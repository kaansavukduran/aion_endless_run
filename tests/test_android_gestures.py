"""Regression for short native charges overtaken by the next logcat read."""
from pathlib import Path
import sys
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'packaging'))
from android_gestures import (charged_jump_sequence, start_grounded_gesture,
                              wait_for_charged_jump)


def state(character='eren', *, charging=False, airborne=False, ratio=0,
          page='', phase='running'):
    return {'character': character, 'page': page, 'state': phase,
            'charging': charging, 'airborne': airborne, 'charge_ratio': ratio}


class ChargedJumpTests(unittest.TestCase):
    def test_charge_overtaken_by_latest_release_is_still_actual_evidence(self):
        history = [state(), state(charging=True, ratio=.014),
                   state(charging=True, ratio=.111), state(airborne=True)]
        self.assertFalse(history[-1]['charging'])
        result = charged_jump_sequence(history, 1, 'eren')
        self.assertEqual(result['charge']['index'], 1)
        self.assertEqual(result['release']['index'], 3)
        self.assertTrue(result['charge']['state']['charging'])
        self.assertFalse(result['charge']['state']['airborne'])

    def test_prior_gesture_charge_and_release_cannot_satisfy_new_gesture(self):
        history = [state(charging=True), state(airborne=True), state()]
        self.assertEqual(charged_jump_sequence(history, 2, 'eren'),
                         {'charge': None, 'release': None})

    def test_wrong_character_cannot_charge_or_complete_another_character(self):
        history = [state('rabbit', charging=True),
                   state('rabbit', airborne=True)]
        self.assertEqual(charged_jump_sequence(history, 0, 'eren'),
                         {'charge': None, 'release': None})
        history = [state(charging=True), state('rabbit', airborne=True)]
        self.assertIsNone(charged_jump_sequence(history, 0, 'eren')['release'])

    def test_dead_and_menu_packets_are_not_live_charge_or_release(self):
        for context in [{'phase': 'bonk'}, {'page': 'finished'},
                        {'page': 'paused', 'phase': 'paused'}]:
            with self.subTest(context=context):
                history = [state(charging=True, **context), state(airborne=True)]
                self.assertIsNone(charged_jump_sequence(history, 0, 'eren')['charge'])
                history = [state(charging=True), state(**context),
                           state(airborne=True)]
                self.assertIsNone(charged_jump_sequence(history, 0, 'eren')['release'])

    def test_release_before_charge_cannot_complete_the_sequence(self):
        history = [state(airborne=True), state(charging=True)]
        result = charged_jump_sequence(history, 0, 'eren')
        self.assertEqual(result['charge']['index'], 1)
        self.assertIsNone(result['release'])

    def test_ground_charge_and_later_airborne_release_are_both_required(self):
        for history in [[state(), state(airborne=True)],
                        [state(charging=True, airborne=True)],
                        [state(charging=True), state()]]:
            self.assertIsNone(charged_jump_sequence(history, 0, 'eren')['release'])

    def test_rabbit_charge_threshold_remains_strictly_above_point_one(self):
        history = [state('rabbit', charging=True, ratio=.1),
                   state('rabbit', airborne=True)]
        self.assertIsNone(charged_jump_sequence(history, 0, 'rabbit', .1)['charge'])
        history.insert(1, state('rabbit', charging=True, ratio=.101))
        result = charged_jump_sequence(history, 0, 'rabbit', .1)
        self.assertEqual(result['charge']['index'], 1)
        self.assertEqual(result['release']['index'], 2)

    def test_poll_returning_entire_charge_and_release_keeps_their_order(self):
        history = [state(), state(charging=True), state(airborne=True)]
        for phase in ['charge', 'release']:
            result = wait_for_charged_jump(lambda: history, 1, 'eren', phase)
            self.assertLess(result['charge']['index'], result['release']['index'])

    def test_no_fresh_charge_times_out_even_with_old_matching_packets(self):
        history = [state(charging=True), state(airborne=True), state()]
        clock = [0.]
        def sleep(duration):
            clock[0] += duration
        with self.assertRaisesRegex(AssertionError, 'gesture cursor 2'):
            wait_for_charged_jump(lambda: history, 2, 'eren', 'charge',
                                  timeout=.2, clock=lambda: clock[0], sleep=sleep)

    def test_incomplete_new_history_never_reuses_old_cursor_matches(self):
        self.assertEqual(charged_jump_sequence([state(charging=True)], 2, 'eren'),
                         {'charge': None, 'release': None})
        with self.assertRaises(ValueError):
            charged_jump_sequence([], -1, 'eren')


class GroundedGestureStartTests(unittest.TestCase):
    def test_issue_and_cursor_share_the_accepted_ground_packet_read(self):
        history = [state(airborne=True), state()]
        calls = []
        def read():
            calls.append('read')
            return history
        def issue():
            calls.append('issue')
            # A device can advance while ADB starts. The packet must remain
            # inside the gesture's observation interval, not be discarded.
            history.append(state(airborne=True))
            return 'real-adb-process'
        gesture, cursor, observation = start_grounded_gesture(read, 'eren', issue)
        self.assertEqual(calls, ['read', 'issue'])
        self.assertEqual(gesture, 'real-adb-process')
        self.assertEqual(cursor, 2)
        self.assertEqual(observation, {'index': 1, 'state': state()})
        self.assertTrue(history[cursor]['airborne'])
        self.assertEqual(charged_jump_sequence(history, cursor, 'eren'),
                         {'charge': None, 'release': None})

    def test_waits_for_latest_ground_and_never_cherry_picks_prior_ground(self):
        snapshots = [[state(), state(airborne=True)],
                     [state(), state(airborne=True), state()]]
        reads = []
        now = [0.]
        def read():
            reads.append(len(reads))
            return snapshots[min(len(reads)-1, len(snapshots)-1)]
        gesture, cursor, observation = start_grounded_gesture(
            read, 'eren', lambda: 'gesture', clock=lambda: now[0],
            sleep=lambda duration: now.__setitem__(0, now[0]+duration))
        self.assertEqual(len(reads), 2)
        self.assertEqual(cursor, 3)
        self.assertEqual(observation['index'], 2)
        self.assertEqual(gesture, 'gesture')

    def test_invalid_live_context_never_issues_the_gesture(self):
        for invalid in [state('rabbit'), state(airborne=True),
                        state(charging=True), state(page='paused'),
                        state(phase='bonk'), {**state(), 'rolling': True},
                        {**state(), 'airborne': None}]:
            with self.subTest(invalid=invalid):
                now = [0.]
                issued = []
                with self.assertRaisesRegex(AssertionError, 'latest live grounded eren'):
                    start_grounded_gesture(
                        lambda: [state(), invalid], 'eren',
                        lambda: issued.append(True), timeout=.2,
                        clock=lambda: now[0],
                        sleep=lambda duration: now.__setitem__(0, now[0]+duration))
                self.assertEqual(issued, [])

    def test_empty_history_cannot_issue_or_invent_a_cursor(self):
        now = [0.]
        issued = []
        with self.assertRaisesRegex(AssertionError, 'before issuing charge: \\[\\]'):
            start_grounded_gesture(
                lambda: [], 'eren', lambda: issued.append(True), timeout=.2,
                clock=lambda: now[0],
                sleep=lambda duration: now.__setitem__(0, now[0]+duration))
        self.assertEqual(issued, [])


if __name__ == '__main__':
    unittest.main()
