"""Read-only native launch predicates; all interaction stays in the ADB driver."""
from io import BytesIO
import time

from PIL import Image


def layout_matches_display(state, bounds):
    expected = 'portrait' if bounds[0] < bounds[1] else 'landscape'
    return state.get('orientation') == expected and all(
        0 <= button['point'][0] < bounds[0]
        and 0 <= button['point'][1] < bounds[1]
        for button in state['buttons']
    )


def opening_button(state, bounds):
    if state.get('page') != 'main' or not layout_matches_display(state, bounds):
        return None
    return next((button for button in state['buttons']
                 if button['name'] == 'SkipOpening'), None)


def main_layout_ready(state, bounds):
    names = {button['name'] for button in state['buttons']}
    return (
        state.get('page') == 'main'
        and layout_matches_display(state, bounds)
        and not names.intersection({'SkipOpening', 'ExitAttract'})
        and {'LanguageMenu', 'StartCampaign', 'StartRun', 'ChooseHero',
             'OpenSettings'} <= names
        and any(name.startswith('StartSelect_') for name in names)
        and {'PagePanel', 'StartChooser'} <= state.get('regions', {}).keys()
    )


def wait_for_main(read_history, read_bounds, tap_opening, record, *, cold=False,
                  timeout=25, clock=time.monotonic, sleep=time.sleep):
    """Fresh installs must expose the authored opening before main is accepted.

    A pre-opening layout can already contain every main control. Historical
    opening records prove the cold sequence was observed, but only the current
    bounded opening control may be tapped. Returning always needs its absence.
    """
    until = clock() + timeout
    opening_seen = False
    skip_sent = False
    history = []
    while clock() < until:
        history = read_history()
        bounds = read_bounds()
        if not opening_seen:
            observed = next((state for state in history
                             if state.get('page') == 'main'
                             and any(button['name'] == 'SkipOpening'
                                     for button in state['buttons'])), None)
            if observed is not None:
                opening_seen = True
                record({'event': 'opening_observed', 'cold': cold,
                        'layout': observed, 'display': bounds})
        if history:
            state = history[-1]
            skip = opening_button(state, bounds)
            if skip is not None:
                if not skip_sent:
                    tap_opening(skip, state, bounds)
                    skip_sent = True
            elif (not cold or opening_seen) and main_layout_ready(state, bounds):
                record({'event': 'main_ready', 'cold': cold,
                        'opening_seen': opening_seen, 'skip_tapped': skip_sent,
                        'layout': state, 'display': bounds})
                return state
        sleep(.1)
    record({'event': 'main_readiness_timeout', 'cold': cold,
            'opening_seen': opening_seen, 'skip_tapped': skip_sent,
            'layouts': history[-3:]})
    raise AssertionError('Timed out waiting for actual main after opening: '
                         f'cold={cold}, opening_seen={opening_seen}, '
                         f'skip_tapped={skip_sent}, layouts={history[-3:]}')


def render_sample(png, bounds):
    """Use the unchanged full-scene image gate, plus actual display dimensions."""
    with Image.open(BytesIO(png)) as source:
        size = list(source.size)
        image = source.convert('RGB').resize((256, 144))
        colors = len(image.getcolors(256 * 144))
    return {'size': size, 'display': bounds, 'colors': colors,
            'minimum_colors': 200,
            'complete': size == list(bounds) and colors >= 200}


def capture_main_frame(read_history, read_bounds, screencap, save, record, *,
                       timeout=8, max_attempts=12,
                       clock=time.monotonic, sleep=time.sleep):
    """Bound GPU presentation retries and retain every unmodified raw frame."""
    until = clock() + timeout
    for attempt in range(1, max_attempts + 1):
        bounds = read_bounds()
        before = read_history()
        png = screencap()
        name = f'android-first-launch-attempt-{attempt:02d}.png'
        save(name, png)
        sample = render_sample(png, bounds)
        after = read_history()
        ready = (bool(before) and bool(after)
                 and main_layout_ready(before[-1], bounds)
                 and main_layout_ready(after[-1], bounds))
        record({'event': 'first_launch_render', 'attempt': attempt,
                'file': name, 'main_ready_before_and_after': ready, **sample})
        if ready and sample['complete']:
            save('android-first-launch.png', png)
            return
        if clock() >= until:
            break
        sleep(.1)
    raise AssertionError('Actual main did not present a complete Android frame; '
                         'raw first-launch attempts retained')
