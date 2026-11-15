"""Cold native launch must dismiss the real intro before capturing the menu."""
from io import BytesIO
from pathlib import Path
import sys
import unittest

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'packaging'))
from android_readiness import (capture_main_frame, layout_matches_display,
                               main_layout_ready, render_sample, wait_for_main)


BOUNDS = [540, 960]


def layout(*extra, main=True):
    names = ['LanguageMenu', 'StartCampaign', 'StartRun', 'ChooseHero',
             'OpenSettings', 'StartSelect_aion'] if main else []
    return {'page': 'main', 'orientation': 'portrait',
            'buttons': [{'name': name, 'text': name, 'point': [100, 200]}
                        for name in [*names, *extra]],
            'regions': {'PagePanel': [28, 234, 484, 339],
                        'StartChooser': [28, 592, 484, 36]} if main else {}}


class Polls:
    def __init__(self, histories):
        self.histories = histories
        self.index = 0
        self.now = 0
        self.events = []
        self.taps = []

    def history(self):
        return self.histories[min(self.index, len(self.histories) - 1)]

    def sleep(self, duration):
        self.now += duration
        self.index += 1

    def wait(self, cold=False, timeout=1):
        return wait_for_main(self.history, lambda: BOUNDS,
                             lambda *args: self.taps.append(args),
                             self.events.append, cold=cold, timeout=timeout,
                             clock=lambda: self.now, sleep=self.sleep)


def png(colors, size=(256, 144)):
    image = Image.new('RGB', size)
    for value in range(colors):
        image.putpixel((value % size[0], value // size[0]),
                       (value % 256, value // 256, 0))
    buffer = BytesIO()
    image.save(buffer, 'PNG')
    return buffer.getvalue()


def screen_layout(*extra, main=True):
    state = layout(*extra, main=main)
    state['orientation'] = 'landscape'
    for button in state['buttons']:
        button['point'] = [100, 80]
    return state


class ReadinessTests(unittest.TestCase):
    def test_cold_pre_intro_main_is_not_ready_and_skip_must_disappear(self):
        main = layout()
        opening = layout('SkipOpening', main=False)
        occluded = layout('SkipOpening')
        polls = Polls([[main], [main, opening], [main, opening],
                       [main, opening, occluded], [main, opening, main]])
        self.assertIs(polls.wait(cold=True), main)
        self.assertEqual(polls.index, 4)
        self.assertEqual(len(polls.taps), 1)
        self.assertEqual(polls.taps[0][0]['name'], 'SkipOpening')
        self.assertTrue(polls.events[-1]['opening_seen'])
        self.assertTrue(polls.events[-1]['skip_tapped'])

    def test_auto_ended_observed_intro_never_taps_historical_skip(self):
        main = layout()
        polls = Polls([[layout('SkipOpening', main=False), main]])
        self.assertIs(polls.wait(cold=True), main)
        self.assertEqual(polls.taps, [])
        self.assertTrue(polls.events[-1]['opening_seen'])
        self.assertFalse(polls.events[-1]['skip_tapped'])

    def test_cold_menu_without_any_opening_evidence_times_out(self):
        polls = Polls([[layout()]])
        with self.assertRaisesRegex(AssertionError, 'opening_seen=False'):
            polls.wait(cold=True, timeout=.25)
        self.assertEqual(polls.events[-1]['event'], 'main_readiness_timeout')
        self.assertFalse(polls.taps)

    def test_warm_menu_needs_no_second_intro(self):
        main = layout()
        polls = Polls([[main]])
        self.assertIs(polls.wait(), main)
        self.assertFalse(polls.taps)

    def test_warm_actual_intro_also_requires_dismissal(self):
        opening = layout('SkipOpening', main=False)
        main = layout()
        polls = Polls([[opening], [opening], [opening, main]])
        self.assertIs(polls.wait(), main)
        self.assertEqual(polls.index, 2)
        self.assertEqual(len(polls.taps), 1)

    def test_unbounded_skip_target_is_observed_but_never_tapped(self):
        invalid = layout('SkipOpening', main=False)
        invalid['buttons'][0]['point'] = [600, 200]
        actual = layout('SkipOpening', main=False)
        main = layout()
        polls = Polls([[invalid], [invalid, actual], [invalid, actual, main]])
        self.assertIs(polls.wait(cold=True), main)
        self.assertEqual(len(polls.taps), 1)
        self.assertIs(polls.taps[0][1], actual)

    def test_main_requires_real_actions_hero_regions_and_no_overlay(self):
        self.assertTrue(main_layout_ready(layout(), BOUNDS))
        for blocker in ['SkipOpening', 'ExitAttract']:
            self.assertFalse(main_layout_ready(layout(blocker), BOUNDS))
        for name in ['LanguageMenu', 'StartCampaign', 'StartRun', 'ChooseHero',
                     'OpenSettings', 'StartSelect_aion']:
            incomplete = layout()
            incomplete['buttons'] = [button for button in incomplete['buttons']
                                     if button['name'] != name]
            self.assertFalse(main_layout_ready(incomplete, BOUNDS), name)
        for region in ['PagePanel', 'StartChooser']:
            incomplete = layout()
            del incomplete['regions'][region]
            self.assertFalse(main_layout_ready(incomplete, BOUNDS), region)

    def test_orientation_and_physical_target_bounds_remain_required(self):
        stale = layout()
        stale['orientation'] = 'landscape'
        self.assertFalse(layout_matches_display(stale, BOUNDS))
        self.assertFalse(main_layout_ready(stale, BOUNDS))
        stale = layout()
        stale['buttons'][0]['point'][1] = BOUNDS[1]
        self.assertFalse(layout_matches_display(stale, BOUNDS))


class RenderBarrierTests(unittest.TestCase):
    def test_gate_keeps_exact_existing_200_color_boundary(self):
        self.assertFalse(render_sample(png(199), [256, 144])['complete'])
        self.assertTrue(render_sample(png(200), [256, 144])['complete'])
        sample = render_sample(png(250), [540, 960])
        self.assertFalse(sample['complete'])
        self.assertEqual(sample['colors'], 250)

    def capture(self, frames, histories=None, max_attempts=12, timeout=8):
        self.saved = {}
        self.events = []
        self.now = 0
        self.captured = 0
        def screen():
            self.captured += 1
            return frames[min(self.captured - 1, len(frames) - 1)]
        def sleep(duration):
            self.now += duration
        iterator = iter(histories) if histories is not None else None
        capture_main_frame(
            (lambda: next(iterator)) if iterator is not None
            else (lambda: [screen_layout()]),
            lambda: [256, 144], screen,
            lambda name, raw: self.saved.__setitem__(name, raw),
            self.events.append, timeout=timeout, max_attempts=max_attempts,
            clock=lambda: self.now, sleep=sleep)

    def test_gpu_lag_raw_first_attempt_retained_before_full_main(self):
        intro = png(162)
        main = png(350)
        self.capture([intro, main])
        self.assertEqual(self.captured, 2)
        self.assertEqual(self.saved['android-first-launch-attempt-01.png'], intro)
        self.assertEqual(self.saved['android-first-launch-attempt-02.png'], main)
        self.assertEqual(self.saved['android-first-launch.png'], main)
        self.assertEqual([event['colors'] for event in self.events], [162, 350])

    def test_rich_image_cannot_bypass_actual_main_layout(self):
        intro = screen_layout('SkipOpening', main=False)
        main = screen_layout()
        # An opening becoming visible during the first capture invalidates it.
        self.capture([png(350)], [[main], [intro], [main], [main]])
        self.assertEqual(self.captured, 2)
        self.assertFalse(self.events[0]['main_ready_before_and_after'])
        self.assertTrue(self.events[1]['main_ready_before_and_after'])

    def test_failed_render_is_bounded_keeps_raw_and_never_claims_success(self):
        with self.assertRaisesRegex(AssertionError, 'raw first-launch'):
            self.capture([png(162)], max_attempts=3)
        self.assertEqual(self.captured, 3)
        self.assertEqual(len(self.saved), 3)
        self.assertNotIn('android-first-launch.png', self.saved)
        self.assertTrue(all(not event['complete'] for event in self.events))

    def test_render_deadline_stops_before_attempt_cap(self):
        with self.assertRaisesRegex(AssertionError, 'raw first-launch'):
            self.capture([png(162)], timeout=.15)
        self.assertEqual(self.captured, 3)


if __name__ == '__main__':
    unittest.main()
