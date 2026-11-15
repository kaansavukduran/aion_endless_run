# Behavior and regression checks

Select checks from the changed action, its affected state, and the project's supported platforms. For each material risk, record the ordinary entry point, action, expected effect, and observation that would distinguish success from failure.

| What can look correct | What to verify |
| --- | --- |
| Button exists, looks enabled, or shows a toast | Use the visible control through a supported input and check its actual effect: route, game state, saved value, or completed request. Verify disabled actions and reasons when applicable. |
| Save looks successful | Use disposable data. Reopen or reload and read the saved value through the normal entry point. On a failed write, preserve the prior value and the user's unsaved input where recovery is supported. |
| Retry succeeds once | Exercise failure then retry, and try a rapid duplicate action where relevant. Count the resulting save, score change, or transition. Check late responses after navigation or cancellation and prevent them from overwriting newer state. |
| Empty, loading, and error states look interchangeable | Exercise them with controlled inputs. Distinguish an empty result from a failed request. Tie progress and completion to the real state. Ensure recovery leads back to the intended task. |
| Defaults work on a fresh profile | If settings, save formats, or data loaders changed, try an existing save or older fixture, missing fields, and valid boundary values. Verify supported values such as zero, false, or an empty string survive where they have meaning. Keep the original save intact during the test. |
| Two controls update the same setting | Start from both supported paths. Reopen or revisit the screen and confirm both show and apply the same value. Trace to the existing owner of the setting before adding state or handlers. |
| A small screen passes in automation | Observe bounds and hit targets before any auto-scroll. Use normal click, tap, or focus activation. A forced click, direct handler call, or test-only state jump can diagnose a cause, but leaves user reachability unverified. |
| Build or tests pass | Identify the actual artifact and entry point tested. Check that the relevant test ran, exercised the changed path, and asserted the observable result. Report skipped tests and mocked dependencies at their real scope. |

## Make the test sensitive to the defect

- Where practical, record a failing baseline with the same conditions used after the patch. If a baseline is unavailable, state it and use a small controlled failure in a disposable fixture where it adds value. A useful regression assertion catches the original symptom and passes after repair.
- Use real entry points for acceptance. Use stubs to introduce controlled timeout, rejection, or ordering failures as needed. Keep the actual interaction and app state under test. Verify outward effects independently of the message the interface prints.
- Inspect changes to tests, fixtures, and screenshots. Keep assertions on the user outcome. Avoid green results caused by skipping a test, weakening an assertion, increasing a timeout without a reason, replacing real behavior with mocks, or accepting a broken snapshot. An intentionally changed expectation needs a documented behavior reason.
- Match evidence to the claim: a unit test can verify state transitions, an engine test can verify scene behavior, and a target browser or device can verify its real input and rendering. Use the narrowest claim supported by the observed result.

