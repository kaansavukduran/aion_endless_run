"""Observe ordered transient input effects in gesture-local passive packets."""
import time


def start_grounded_gesture(read_history, character, issue, *, timeout=15,
                           clock=time.monotonic, sleep=time.sleep):
    """Issue immediately after one latest grounded observation and its cursor.

    A second logcat read between readiness and issuing the gesture can already
    observe flight, yet discard it as pre-gesture history. Keep the accepted
    packet and boundary from the same read; never reuse an older grounded one.
    This does not make ADB input atomic with the game. Charge/release evidence
    after the boundary is still required by wait_for_charged_jump.
    """
    until = clock() + timeout
    history = []
    while clock() < until:
        history = read_history()
        if history:
            state = history[-1]
            if (state.get('character') == character and state.get('page') == ''
                    and state.get('state') == 'running'
                    and state.get('airborne') is False
                    and state.get('charging') is False
                    and state.get('rolling', False) is False):
                cursor = len(history)
                observation = {'index': cursor - 1, 'state': state.copy()}
                gesture = issue()
                return gesture, cursor, observation
        sleep(.1)
    raise AssertionError(f'Timed out waiting for latest live grounded {character} '
                         f'before issuing charge: {history[-3:]}')


def charged_jump_sequence(history, cursor, character, minimum_ratio=None):
    """Return ground charge then airborne release, never a prior gesture match.

    A logcat read can finish after both transitions have already happened.
    Inspect the fresh packet interval in order instead of its last element.
    Character, page and live-run context must remain valid through release.
    """
    if cursor < 0:
        raise ValueError('Gesture packet cursor must be nonnegative')
    result = {'charge': None, 'release': None}
    for index in range(cursor, len(history)):
        state = history[index]
        if (state.get('character') != character or state.get('page') != ''
                or state.get('state') != 'running'):
            break
        if result['charge'] is None:
            if (state.get('charging') is True and state.get('airborne') is False
                    and (minimum_ratio is None
                         or state.get('charge_ratio', 0) > minimum_ratio)):
                result['charge'] = {'index': index, 'state': state}
        elif state.get('airborne') is True and state.get('charging') is False:
            result['release'] = {'index': index, 'state': state}
            break
    return result


def wait_for_charged_jump(read_history, cursor, character, phase, *,
                          minimum_ratio=None, timeout=15,
                          clock=time.monotonic, sleep=time.sleep):
    if phase not in ('charge', 'release'):
        raise ValueError('Expected charge or release phase')
    until = clock() + timeout
    history = []
    while clock() < until:
        history = read_history()
        sequence = charged_jump_sequence(history, cursor, character, minimum_ratio)
        if sequence[phase] is not None:
            return sequence
        sleep(.1)
    raise AssertionError(f'Timed out observing actual {character} {phase} '
                         f'after gesture cursor {cursor}: {history[cursor:]}')
