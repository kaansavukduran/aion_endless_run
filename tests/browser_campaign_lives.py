"""Play the actual arcade lives flow with keyboard, touch and a real page reload.

Canvas telemetry and the save mirror are read-only. No injected save, forced
damage, world setter or fixture is used by this browser test.
"""
import argparse
import json
from pathlib import Path
import shutil
import time

from playwright.sync_api import sync_playwright


parser = argparse.ArgumentParser()
parser.add_argument("--url", required=True)
parser.add_argument("--evidence", type=Path, required=True)
parser.add_argument("--headed", action="store_true")
parser.add_argument("--offline", action="store_true")
parser.add_argument("--locale", choices=["tr-TR", "en-US"], default="tr-TR")
args = parser.parse_args()
args.evidence.mkdir(parents=True, exist_ok=True)

with sync_playwright() as playwright:
    browser = playwright.chromium.launch(
        executable_path=shutil.which("chromium"), headless=not args.headed,
        args=["--no-sandbox", "--enable-unsafe-swiftshader"],
        ignore_default_args=["--disable-background-timer-throttling",
                             "--disable-backgrounding-occluded-windows",
                             "--disable-renderer-backgrounding"],
    )
    context = browser.new_context(
        locale=args.locale, has_touch=True, viewport={"width": 1280, "height": 720},
    )
    page = context.new_page()
    canvas = page.locator("canvas")
    context.new_cdp_session(page).send("Emulation.setFocusEmulationEnabled", {"enabled": False})
    errors = []
    page.on("pageerror", lambda error: errors.append(str(error)))
    page.on("console", lambda msg: errors.append(msg.text) if "SCRIPT ERROR" in msg.text else None)
    evidence = {"checks": [], "losses": [], "picker": []}

    def check(ok, label):
        assert ok, label
        evidence["checks"].append(label)
        print("PASS", label, flush=True)

    def read():
        return json.loads(canvas.get_attribute("data-campaign") or "{}")

    def observe(predicate, arg=None, timeout=20000):
        result = page.wait_for_function(
            "arg=>{const raw=document.querySelector('canvas')?.dataset.campaign;"
            "if(!raw)return false;const d=JSON.parse(raw);return (" + predicate + ") ? d : false;}",
            arg=arg, timeout=timeout,
        )
        return result.json_value()

    def tap_campaign(name):
        state = observe("d.ui_ready && d.buttons[arg]", name)
        x, y, width, height, _ = state["buttons"][name]
        transform = state["transform"]
        rect = canvas.bounding_box()
        raw = state["raw"]
        page.touchscreen.tap(
            rect["x"] + (transform[0] * (x + width / 2) + transform[1]) / raw[0] * rect["width"],
            rect["y"] + (transform[0] * (y + height / 2) + transform[2]) / raw[1] * rect["height"],
        )

    def boot(reload=False):
        if reload:
            page.reload(timeout=120000)
        else:
            page.goto(args.url, timeout=120000)
        page.wait_for_selector('canvas[data-state="ready"][data-ui-ready="true"]', timeout=120000)
        controls = json.loads(canvas.get_attribute('data-ui'))
        if not reload:
            start = next(button for button in controls if button["name"] == "StartCampaign")
            check(start["text"] == ("Kahraman seç" if args.locale == "tr-TR" else "Choose hero"),
                  "The first screen names the actual hero selection destination")
            page.screenshot(path=str(args.evidence / "opening-guide.png"))
        if reload and not any(b['name']=='ContinueCampaign' for b in controls):
            return False
        actions = ('ContinueCampaign',) if reload else ('StartCampaign', 'ConfirmHero')
        for name in actions:
            controls = canvas.evaluate("c=>({...c.dataset})")
            item = next(button for button in json.loads(controls["ui"]) if button["name"] == name)
            tr = json.loads(controls["screenTransform"])
            rect = canvas.bounding_box()
            x = item["x"] + item["w"] / 2
            y = item["y"] + item["h"] / 2
            page.touchscreen.tap(
                rect["x"] + (tr[0] * x + tr[2] * y + tr[4]) / float(controls["rawWidth"]) * rect["width"],
                rect["y"] + (tr[1] * x + tr[3] * y + tr[5]) / float(controls["rawHeight"]) * rect["height"],
            )
            if name == 'StartCampaign':
                page.wait_for_selector('canvas[data-page="characters"][data-ui-ready="true"]')
        observe("d.ui_ready")
        return True

    def lose_three_lives(held_enter=False):
        for expected in [2, 1, 0]:
            before = observe("d.state==='playing' && d.hp===1")
            canvas.focus()
            if expected == 0 and held_enter:
                page.keyboard.down("Enter")
            page.keyboard.down("d")
            fallen = observe("d.state==='dying' && d.attempts===arg", expected, timeout=30000)
            page.keyboard.up("d")
            check(fallen["losses"] == before["losses"] + 1, "A real enemy hit spends exactly one life")
            evidence["losses"].append(fallen)
            if expected:
                entering = observe("d.state==='respawn' && d.attempts===arg", expected)
                returned = observe("d.state==='playing' && d.invulnerable>0 && d.attempts===arg", expected)
                check(returned["section"] == fallen["section"] and
                      returned["time"] - fallen["time"] < .3 and entering["player"][1] < returned["player"][1],
                      "The replacement comes down into the same frozen encounter")
            else:
                offer = observe("d.menu==='continue_offer' && d.ui_ready && d.attempts===0")
                if held_enter:
                    page.keyboard.down("Enter")  # An operating-system repeat of the held key.
                    page.wait_for_timeout(320)
                    check(read()["menu"] == "continue_offer", "Held Enter and key repeat cannot spend a credit")
                    page.keyboard.up("Enter")
                return offer

    try:
        boot()
        start = observe("d.state==='playing' && d.attempts===3 && d.hp===1")
        check(start["continues"] == 0, "A new run has one active body, two reserves and zero Continues")
        offer = lose_three_lives(held_enter=True)
        check(offer["continue_remaining"] > 9., "Last death opens the ten-second Continue offer")
        buttons = offer["buttons"]
        check("ArcadeConfirmHero" in buttons and "ArcadeNextHero" in buttons and
              buttons["ArcadeConfirmHero"][0] < 40 and buttons["ArcadeConfirmHero"][1] < offer["view"][1] / 3,
              "The live field stays visible with an immediate upper-left hero selector")
        page.screenshot(path=str(args.evidence / "continue-landscape.png"))
        later_offer = observe("d.state==='continue_offer' && d.continue_remaining<8.")
        elapsed_offer = later_offer["continue_remaining"]
        check(later_offer["time"] > offer["time"] and later_offer["enemies"] != offer["enemies"] and
              later_offer["losses"] == offer["losses"] and later_offer["shots"] == offer["shots"],
              "Enemies keep moving and attacking while the fallen hero cannot lose another life or fire")
        with page.expect_popup() as popup:
            page.evaluate("window.open(new URL('build.json', location.href), '_blank')")
        other_tab = popup.value
        context.new_cdp_session(other_tab).send("Emulation.setFocusEmulationEnabled", {"enabled": False})
        other_tab.bring_to_front()
        focus_samples = []
        for _ in range(6):
            focus = page.evaluate("({hidden:document.hidden, focused:document.hasFocus()})")
            focus_samples.append(focus)
            if focus["hidden"] or not focus["focused"]:
                break
            time.sleep(.1)
        evidence["tab_focus_samples"] = focus_samples
        before_blur = read()["continue_remaining"]
        time.sleep(1.15)
        if focus["hidden"] or not focus["focused"]:
            check(abs(read()["continue_remaining"] - before_blur) < .13, "An unfocused page pauses the countdown")
        else:
            # Some headless remote sessions keep all top-level targets focused.
            # This stays distinct from testing real inactive-window behavior.
            evidence["tab_focus_limit"] = "Browser did not report focus loss for this popup."
        other_tab.close()
        page.bring_to_front()
        canvas.focus()
        observe("d.continue_remaining<arg", before_blur)
        # Open the saved offer through a fresh page, with the same origin data.
        if args.offline:
            page.wait_for_function("""async () => {
                const manifest = await fetch('build.json').then(response => response.json());
                const pack = Object.keys(manifest.assets).find(name => name.endsWith('.pck'));
                return !!navigator.serviceWorker.controller && !!(await caches.match(new URL(pack, location.href)));
            }""", timeout=120000)
            context.set_offline(True)
        boot(reload=True)
        if args.offline:
            # A HEAD request cannot be supplied by the game's GET cache.
            network_blocked = page.evaluate("""async () => {
                try {
                    await fetch(new URL('build.json?offline_probe=' + Date.now(), location.href),
                                {method:'HEAD', cache:'no-store'});
                    return false;
                } catch (_) {
                    return true;
                }
            }""")
            check(network_blocked, "The cached game loads while a fresh network request fails")
        reopened = observe("d.menu==='continue_offer' && d.ui_ready")
        check(0. < reopened["continue_remaining"] <= elapsed_offer + .13 and reopened["attempts"] == 0,
              "Reload preserves the unspent countdown without refilling the credit")
        if args.offline:
            context.set_offline(False)
        page.set_viewport_size({"width": 393, "height": 873})
        observe("d.ui_ready && d.view[1]>d.view[0]")
        canvas.focus()
        picker = observe("d.menu==='continue_offer' && d.ui_ready")
        rect = canvas.bounding_box()
        for name in ("ArcadePreviousHero", "ArcadeNextHero", "ArcadeConfirmHero"):
            _, _, width, height, _ = picker["buttons"][name]
            scale = picker["transform"][0]
            check(min(width * scale * rect["width"] / picker["raw"][0],
                      height * scale * rect["height"] / picker["raw"][1]) >= 43.5,
                  f"{name} has a finger-sized target in portrait")
        original_hero = picker["continue_hero"]
        page.keyboard.press("ArrowRight")
        observe("d.menu==='continue_offer' && d.continue_hero!==arg", original_hero)
        page.keyboard.press("ArrowLeft")
        observe("d.menu==='continue_offer' && d.continue_hero===arg", original_hero)
        for _ in range(6):
            state = observe("d.ui_ready && d.menu==='continue_offer'")
            hero = state["continue_hero"]
            evidence["picker"].append(hero)
            tap_campaign("ArcadeNextHero")
            observe("d.continue_hero!==arg && d.ui_ready", hero)
        check(set(evidence["picker"]) == {"aion", "sheep", "rabbit", "eren", "armadillo", "frog"},
              "All six playable heroes can be browsed on a portrait viewport")
        tap_campaign("ArcadePreviousHero")
        selected = observe("d.continue_hero==='frog' && d.ui_ready")
        check(0. < selected["continue_remaining"] < picker["continue_remaining"] and selected["continues"] == 0,
              "Browsing takes place inside the original countdown without spending a credit")
        page.screenshot(path=str(args.evidence / "hero-picker-portrait.png"))
        tap_campaign("ArcadeConfirmHero")
        recovered = observe("d.state==='playing' && d.character==='frog' && d.attempts===3")
        check(recovered["continues"] == 1 and recovered["shots"] == picker["shots"] and recovered["grenades"] == 5,
              "One touch buys exactly one Continue with the selected hero and no leaked attack")
        check(recovered["taken"] == picker["taken"] and recovered["section"] == picker["section"],
              "Continue preserves the same section and collected items")
        page.set_viewport_size({"width": 1280, "height": 720})
        observe("d.ui_ready && d.view[0]>d.view[1]")
        lose_three_lives()
        game_over = observe("d.menu==='dead' && d.ui_ready", timeout=35000)
        check(game_over["attempts"] == 0 and game_over["continues"] == 1 and
              "CampaignRestart" in game_over["buttons"] and "ArcadeConfirmHero" not in game_over["buttons"],
              "Expiration reaches Game Over with only a genuine new run available")
        page.screenshot(path=str(args.evidence / "game-over.png"))
        check(not boot(reload=True), "Game Over cannot be bypassed by reopening the saved run")
        check(not errors, "No uncaught browser or Godot script errors")
    except Exception:
        evidence["failure"] = read()
        page.screenshot(path=str(args.evidence / "failure.png"))
        raise
    finally:
        evidence["errors"] = errors
        (args.evidence / "arcade-lives.json").write_text(json.dumps(evidence, indent=2) + "\n")
        browser.close()
