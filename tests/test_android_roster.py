"""Native roster coverage must follow real pager targets, never hidden IDs."""
from pathlib import Path
import sys
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'packaging'))
from android_roster import CURRENT_ROSTER, NativeRoster


BOUNDS = [540, 960]


class Device:
    def __init__(self, pages=None, start=0, lag=0):
        self.pages = pages or [CURRENT_ROSTER[index:index+2] for index in range(0, 6, 2)]
        self.page = start
        self.now = 0.
        self.taps = []
        self.observed = []
        self.lag = lag
        self.pending = None
        self.remaining_lag = 0

    def layout(self):
        names = ['LanguageMenu', 'StartCampaign', 'StartRun', 'ChooseHero',
                 'OpenSettings', *self.pages[self.page]]
        if len(self.pages) > 1:
            names += ['RosterPrevious', 'RosterNext']
        return {'page': 'main', 'character': 'eren', 'orientation': 'portrait',
                'buttons': [{'name': name, 'point': [100, 200]} for name in names],
                'regions': {'PagePanel': [0, 0, 100, 100],
                            'StartChooser': [0, 110, 100, 50]}}

    def history(self):
        if self.pending is not None:
            if self.remaining_lag:
                self.remaining_lag -= 1
            else:
                self.page = self.pending
                self.pending = None
        self.observed.append(self.page)
        return [self.layout()]

    def tap(self, name):
        self.taps.append((self.page, name))
        self.pending = min(len(self.pages)-1, self.page+1) if name == 'RosterNext' else max(0, self.page-1)
        self.remaining_lag = self.lag

    def sleep(self, duration):
        self.now += duration

    def roster(self):
        return NativeRoster(self.history, lambda: BOUNDS, self.tap, timeout=.5,
                            clock=lambda: self.now, sleep=self.sleep)


class NativeRosterTests(unittest.TestCase):
    def test_three_actual_pages_cover_all_six_and_restore_first_from_later_page(self):
        device = Device(start=1)
        pages = []
        seen = device.roster().inspect(pages.append)
        self.assertEqual(seen, set(CURRENT_ROSTER))
        self.assertEqual([tuple(sorted(page['buttons'][5+i]['name'] for i in range(2)))
                          for page in pages],
                         [tuple(sorted(CURRENT_ROSTER[i:i+2])) for i in range(0, 6, 2)])
        self.assertEqual(device.taps, [(1, 'RosterPrevious'), (0, 'RosterNext'),
                                      (1, 'RosterNext')])
        self.assertTrue(all(page['character'] == 'eren' for page in pages))

    def test_actual_next_page_ack_required_before_another_tap(self):
        device = Device(lag=2)
        layout = device.roster().find('StartSelect_eren')
        self.assertIn('StartSelect_eren', {button['name'] for button in layout['buttons']})
        self.assertEqual(device.taps, [(0, 'RosterNext')])
        self.assertEqual(device.observed, [0, 0, 0, 1])

    def test_eren_then_aion_are_reachable_by_actual_opposite_pager_taps(self):
        device = Device()
        roster = device.roster()
        roster.find('StartSelect_eren')
        roster.find('StartSelect_aion')
        self.assertEqual(device.taps, [(0, 'RosterNext'), (1, 'RosterPrevious')])

    def test_retired_choice_hidden_on_later_page_is_a_failure(self):
        pages = [CURRENT_ROSTER[:2], (*CURRENT_ROSTER[2:4], 'StartSelect_owl'),
                 CURRENT_ROSTER[4:]]
        device = Device(pages)
        with self.assertRaisesRegex(AssertionError, 'Retired native roster choice'):
            device.roster().inspect()

    def test_missing_middle_hero_cannot_pass_as_first_two_subset(self):
        device = Device([CURRENT_ROSTER[:2], (CURRENT_ROSTER[2],), CURRENT_ROSTER[4:]])
        with self.assertRaisesRegex(AssertionError, 'StartSelect_eren'):
            device.roster().inspect()

    def test_missing_pager_does_not_reveal_hidden_heroes(self):
        device = Device([CURRENT_ROSTER[:2]])
        with self.assertRaisesRegex(AssertionError, 'pager missing'):
            device.roster().inspect()
        self.assertEqual(device.taps, [])

    def test_unpaged_six_roster_needs_no_pager_input(self):
        device = Device([CURRENT_ROSTER])
        self.assertEqual(device.roster().inspect(), set(CURRENT_ROSTER))
        self.assertEqual(device.taps, [])

    def test_unknown_and_retired_selection_targets_are_rejected(self):
        device = Device()
        for target in ['StartSelect_owl', 'StartSelect_wolf', 'StartSelect_unknown']:
            with self.subTest(target=target), self.assertRaises(AssertionError):
                device.roster().find(target)
        self.assertEqual(device.taps, [])

    def test_stuck_next_page_fails_bounded_without_repeated_taps(self):
        device = Device()
        device.tap = lambda name: device.taps.append((device.page, name))
        with self.assertRaisesRegex(AssertionError, 'Timed out'):
            device.roster().find('StartSelect_eren')
        self.assertEqual(device.taps, [(0, 'RosterNext')])


if __name__ == '__main__':
    unittest.main()
