"""Observe ordered transient input effects in gesture-local passive packets."""
import time


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
