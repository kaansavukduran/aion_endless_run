"""Walk native roster pages through visible ADB controls and passive layouts."""
import time

from android_readiness import main_layout_ready


CURRENT_ROSTER = tuple('StartSelect_' + hero for hero in
                       ('aion', 'sheep', 'rabbit', 'eren', 'armadillo', 'frog'))
RETIRED_ROSTER = {'StartSelect_owl', 'StartSelect_wolf'}


class NativeRoster:
    def __init__(self, read_history, read_bounds, tap_button, *, timeout=25,
                 clock=time.monotonic, sleep=time.sleep):
        self.read_history = read_history
        self.read_bounds = read_bounds
        self.tap_button = tap_button
        self.timeout = timeout
        self.clock = clock
        self.sleep = sleep

    @staticmethod
    def names(layout):
        names = frozenset(button['name'] for button in layout['buttons']
                          if button['name'].startswith('StartSelect_'))
        assert not names & RETIRED_ROSTER, ('Retired native roster choice', names)
        assert names <= set(CURRENT_ROSTER), ('Unexpected native roster choice', names)
        return names

    def layout(self, predicate=lambda value: True):
        until = self.clock() + self.timeout
        history = []
        while self.clock() < until:
            history = self.read_history()
            bounds = self.read_bounds()
            if history and main_layout_ready(history[-1], bounds):
                state = history[-1]
                self.names(state)
                if predicate(state):
                    return state
            self.sleep(.1)
        raise AssertionError('Timed out waiting for current native roster page: '
                             f'{history[-3:]}')

    def step(self, layout, direction):
        before = self.names(layout)
        assert any(button['name'] == direction for button in layout['buttons']), (
            'Native roster pager missing', direction, before)
        self.tap_button(direction)
        # A successful ADB command is not the engine's next-page acknowledgment.
        return self.layout(lambda state: self.names(state) != before)

    def find(self, target):
        assert target in CURRENT_ROSTER, ('Unknown current native hero', target)
        layout = self.layout()
        visited = set()
        for _ in CURRENT_ROSTER:
            names = self.names(layout)
            if target in names:
                return layout
            assert names not in visited, ('Native roster navigation loop', target, names)
            visited.add(names)
            target_index = CURRENT_ROSTER.index(target)
            indices = [CURRENT_ROSTER.index(name) for name in names]
            direction = 'RosterNext' if target_index > max(indices) else 'RosterPrevious'
            layout = self.step(layout, direction)
        raise AssertionError(('Native hero was not reachable through roster pages', target))

    def inspect(self, on_page=lambda layout: None):
        # Begin at the actual first card, even when the selected hero saved a
        # later page. Paging does not change the selected character.
        layout = self.find(CURRENT_ROSTER[0])
        seen = set()
        visited = set()
        for _ in CURRENT_ROSTER:
            names = self.names(layout)
            assert names not in visited, ('Native roster inspection loop', names)
            visited.add(names)
            on_page(layout)
            seen.update(names)
            if seen == set(CURRENT_ROSTER):
                return seen
            if CURRENT_ROSTER[-1] in names:
                break
            layout = self.step(layout, 'RosterNext')
        raise AssertionError(('Not all six native hero cards were reachable',
                              sorted(set(CURRENT_ROSTER)-seen), sorted(seen)))
