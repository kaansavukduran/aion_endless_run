"""Stale update and real Campaign Continue across three immutable Web exports."""

import argparse
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
import json
from pathlib import Path
import shutil
from threading import Thread
from time import monotonic
from urllib.parse import parse_qs, urlsplit

from playwright.sync_api import sync_playwright


class Site(ThreadingHTTPServer):
    def __init__(self, exports):
        super().__init__(("127.0.0.1", 0), Files)
        self.exports = exports
        self.builds = [json.loads((path / "build.json").read_text()) for path in exports]
        self.published = 0
        self.served_entries = []

    def entry_release(self, query):
        requested = parse_qs(query).get("build", [None])[0]
        if self.published == 2 and requested == self.builds[1]["build"]:
            return 1  # A stale CDN entry for the update button's original URL.
        return self.published


class Files(SimpleHTTPRequestHandler):
    def log_message(self, *_args):
        pass

    def end_headers(self):
        self.send_header("Cache-Control", "no-cache")
        super().end_headers()

    def do_GET(self):
        url = urlsplit(self.path)
        name = url.path.lstrip("/")
        release = self.server.published
        if name in ("", "index.html"):
            release = self.server.entry_release(url.query)
            self.server.served_entries.append({"query": url.query, "release": release})
        self.directory = str(self.server.exports[release])
        # Hash-named assets remain available to older tabs during deployment.
        if name.startswith(("aion-", "fragaria-", "pixel-font-")) and name not in ("aion-latest.json",):
            for export in reversed(self.server.exports[:release + 1]):
                if (export / name).is_file():
                    self.directory = str(export)
                    break
        # Local archive mtimes can go backwards or tie as releases switch.
        # These fixtures must serve the selected bytes even on revalidation.
        for validator in ("If-Modified-Since", "If-None-Match"):
            if validator in self.headers:
                del self.headers[validator]
        super().do_GET()


def read_campaign(page):
    return json.loads(page.locator("canvas").get_attribute("data-campaign"))


def entry_ready(page):
    page.wait_for_selector('canvas[data-state="ready"][data-ui-ready="true"]', timeout=150_000)
    return page.locator("canvas").evaluate("c => ({...c.dataset})")


def choose_saved_hero(page):
    def tap(name, entry):
        button = next(item for item in json.loads(entry["ui"]) if item["name"] == name)
        a, b, c, d, tx, ty = json.loads(entry["screenTransform"])
        canvas = page.locator("canvas").bounding_box()
        x = button["x"] + button["w"] / 2
        y = button["y"] + button["h"] / 2
        page.touchscreen.tap(
            canvas["x"] + (a * x + c * y + tx) * canvas["width"] / float(entry["rawWidth"]),
            canvas["y"] + (b * x + d * y + ty) * canvas["height"] / float(entry["rawHeight"]),
        )

    def find(name):
        for _ in range(10):
            entry = entry_ready(page)
            if any(button["name"] == name for button in json.loads(entry["ui"])):
                return entry
            tap("NextPage", entry)
            page.wait_for_function(
                "old => document.querySelector('canvas').dataset.menuPage !== old",
                arg=entry["menuPage"],
            )
        raise AssertionError(f"Could not reach the hero selection action {name}")

    # Choosing a non-default hero exposes a reset to Aion after updating.
    tap("ChooseHero", entry_ready(page))
    page.wait_for_selector('canvas[data-page="characters"][data-ui-ready="true"]')
    tap("Select_sheep", find("Select_sheep"))
    page.wait_for_selector('canvas[data-character="sheep"][data-ui-ready="true"]')
    tap("ConfirmHero", find("ConfirmHero"))
    page.wait_for_selector('canvas[data-page="main"][data-character="sheep"][data-ui-ready="true"]')
    return entry_ready(page)["character"]


def start_campaign(page):
    entry = entry_ready(page)
    start = next(button for button in json.loads(entry["ui"]) if button["name"] == "StartCampaign")
    page.get_by_role("button", name=start["text"], exact=True).press("Enter")
    page.wait_for_selector("canvas[data-campaign]", timeout=45_000)


def tap_action(page, name):
    page.wait_for_function(
        "n => {const d=JSON.parse(document.querySelector('canvas').dataset.campaign);return d.ui_ready&&d.buttons[n]}",
        arg=name,
    )
    state = read_campaign(page)
    left, top, width, height = state["buttons"][name][:4]
    factor, tx, ty = state["transform"]
    canvas = page.locator("canvas").bounding_box()
    raw_width, raw_height = state.get("raw", [dim * factor for dim in state["view"]])
    page.touchscreen.tap(
        canvas["x"] + ((left + width / 2) * factor + tx) * canvas["width"] / raw_width,
        canvas["y"] + ((top + height / 2) * factor + ty) * canvas["height"] / raw_height,
    )
    page.wait_for_function(
        "old => {const d=JSON.parse(document.querySelector('canvas').dataset.campaign);return d.ui_ready&&d.ui_generation!==old}",
        arg=state["ui_generation"],
    )


def playing(page):
    page.wait_for_function(
        """() => {const d=JSON.parse(document.querySelector('canvas').dataset.campaign);
        return d.state==='playing'&&!d.menu&&!d.travel_active&&!(d.presentation||d.presentation_stage)}"""
    )


def prepare_campaign(page):
    start_campaign(page)
    tap_action(page, "CampaignBegin")
    while read_campaign(page)["menu"] == "help":
        tap_action(page, "CampaignGo")
    playing(page)
    page.locator("canvas").focus()
    page.keyboard.down("d")
    page.keyboard.down("f")
    page.wait_for_function(
        "() => {const d=JSON.parse(document.querySelector('canvas').dataset.campaign);return d.score>0&&Object.keys(d.taken).length>0}",
        timeout=45_000,
    )
    page.keyboard.up("d")
    page.keyboard.up("f")
    page.keyboard.press("Escape")
    page.wait_for_function("JSON.parse(document.querySelector('canvas').dataset.campaign).menu==='paused'")
    return page.evaluate("JSON.parse(localStorage.getItem('aion.campaign.v1'))")


def continue_campaign(page, saved, hero):
    start_campaign(page)
    tap_action(page, "CampaignContinue")
    playing(page)
    active = read_campaign(page)
    assert active["character"] == hero and active["section"] == saved["checkpoint"]
    assert all(active[key] == saved[key] for key in ("score", "taken", "awarded"))
    return active


def published_worker(page, build, update):
    page.wait_for_function("navigator.serviceWorker.controller !== null", timeout=150_000)
    if update:
        page.evaluate("navigator.serviceWorker.getRegistration().then(registration=>registration.update()).then(()=>true)")
    deadline = monotonic() + 150
    # Resolve the message reply before deciding whether this worker is active.
    while monotonic() < deadline:
        if page.evaluate(
            """(build) => new Promise(resolve => {
            const controller = navigator.serviceWorker.controller;
            if (!controller) {resolve(false);return;}
            const expiry = setTimeout(() => finish(false), 600);
            const answer = event => {
              if (event.source === controller && event.data?.type === 'aion-version') finish(event.data.build === build);
            };
            const finish = value => {
              clearTimeout(expiry);
              navigator.serviceWorker.removeEventListener('message',answer);
              resolve(value);
            };
            navigator.serviceWorker.addEventListener('message',answer);
            controller.postMessage({type:'aion-version'});
          })""",
            build,
        ):
            return
        page.wait_for_timeout(150)
    raise AssertionError(f"Active service worker never confirmed build {build}")


def verify_context(context, site, evidence, modern):
    reports = {}
    errors = []
    page = context.new_page()
    page.on("pageerror", lambda error: errors.append(str(error)))
    url = f"http://127.0.0.1:{site.server_port}/aion/"
    first, intermediate, final = site.builds
    try:
        page.goto(url)
        hero = choose_saved_hero(page)
        published_worker(page, first["build"], update=False)
        saved = prepare_campaign(page)
        assert saved["score"] > 0 and saved["taken"] and saved["awarded"]
        reports["saved"] = saved
        print("PASS Real original profile stores score, checkpoint and unique rewards", flush=True)

        site.published = 1
        published_worker(page, intermediate["build"], update=True)
        offer = page.locator("#aion-update")
        offer.wait_for(state="visible")
        reports["first_offer"] = offer.inner_text()
        assert reports["first_offer"].endswith("v" + intermediate["version"])
        site.published = 2
        published_worker(page, final["build"], update=True)
        if modern:
            page.wait_for_function(
                "version => document.querySelector('#aion-update')?.textContent.endsWith('v'+version)",
                arg=final["version"],
            )
        reports["clicked_offer"] = offer.inner_text()
        page.screenshot(path=evidence / "update-offer.png")

        with page.expect_navigation(wait_until="domcontentloaded", timeout=40_000):
            offer.click()
        state = entry_ready(page)
        reports["landed"] = page.evaluate("window.AION_BUILD")
        print(f"Update button landed on {reports['landed']}", flush=True)
        assert reports["landed"] == {"version": final["version"], "build": final["build"]}
        assert state["version"] == final["version"] and state["character"] == hero
        print("PASS One actual update click opens the exact final immutable package", flush=True)
        reports["online"] = continue_campaign(page, saved, hero)
        page.screenshot(path=evidence / "continued-online.png")
        print("PASS Online Continue restores original hero, checkpoint, score and reward IDs", flush=True)

        context.set_offline(True)
        page.reload(timeout=120_000)
        assert entry_ready(page)["version"] == final["version"]
        assert page.evaluate("window.AION_BUILD.build") == final["build"]
        reports["offline"] = continue_campaign(page, saved, hero)
        page.screenshot(path=evidence / "continued-offline.png")
        print("PASS Offline reload and Continue restore the same hero, checkpoint, score and reward IDs", flush=True)
        assert not errors, errors
    finally:
        reports["entries"] = site.served_entries
        reports["page_errors"] = errors
        (evidence / "update-results.json").write_text(json.dumps(reports, indent=2) + "\n")
        page.close()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--exports", type=Path, nargs=3, required=True)
    parser.add_argument("--evidence", type=Path, required=True)
    parser.add_argument("--modern", action="store_true", help="Require the loaded updater to also relabel its first offer")
    args = parser.parse_args()
    args.evidence.mkdir(parents=True, exist_ok=True)

    # The hosted production project uses a repository subpath.
    class ScopedFiles(Files):
        def do_GET(self):
            assert self.path.startswith("/aion/"), self.path
            self.path = "/" + self.path.removeprefix("/aion/")
            super().do_GET()

    site = Site([path.resolve() for path in args.exports])
    site.RequestHandlerClass = ScopedFiles
    assert len({meta["build"] for meta in site.builds}) == 3, "Use three distinct immutable builds"
    thread = Thread(target=site.serve_forever, daemon=True)
    thread.start()
    try:
        with sync_playwright() as playwright:
            browser = playwright.chromium.launch(
                executable_path=shutil.which("chromium"),
                args=["--no-sandbox", "--enable-unsafe-swiftshader"],
            )
            context = browser.new_context(viewport={"width": 1280, "height": 720}, has_touch=True, locale="tr-TR")
            verify_context(context, site, args.evidence, args.modern)
    finally:
        site.shutdown()
        site.server_close()


if __name__ == "__main__":
    main()
