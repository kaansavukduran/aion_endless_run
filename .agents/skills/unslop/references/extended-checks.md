# Extended checks

## Accessible interaction

- Test the actual keyboard or directional route to each affected action. Check meaningful focus order, visible focus against the actual surface, and an escape or back route appropriate to the platform. For a modal, check its accessible name, focus entry, isolation of background controls, and focus return. Check sticky bars and the on-screen keyboard for obscured targets.
- Inspect meaningful names, roles, values and state changes using the accessibility tree where available. Check that form errors identify the relevant field and that important asynchronous updates can be perceived without reading the entire screen again. Claim actual screen-reader behavior only after testing it.
- Check whether color-only, sound-only, hover-only or drag-only cues leave a supported input path unusable. Use the project's established equivalent input or status cues. Verify meaningful reduced-motion behavior where relevant. Check the entire hit area and adjacent-target spacing at supported sizes.

## Navigation, forms and actions

- Exercise back, forward, reload, and direct links when they are supported. Verify the intended route, selected item, filters, scroll position and unsaved input according to the product's behavior. Check that modal and menu dismissal, nested overlays and browser history cooperate.
- Submit forms through supported keyboard and pointer paths. Verify required fields, inline errors, correction, successful submission, and input preservation on recoverable failure. Check keyboard composition and localized input when changes affect text entry. Confirm the acted-on item for destructive or bulk actions and check supported undo or recovery.
- Check that primary and secondary actions remain predictable across screens. Investigate disabled states with no explanation when the user needs a next step. Confirm user-facing error text explains what happened and what action is available.

## Data and visual asset fidelity

- Trace displayed totals, counts, units, labels, dates, sort and filter results, pagination and progress to their actual source. Use controlled records that expose boundary, zero, stale, partial and missing-data cases. Check placeholders, demo content, fake metrics and stale indicators that can be mistaken for live data. Preserve intentional demo or fixture modes and their visible context.
- Inspect assets at their real display size and device scales. Check distorted aspect ratios, unintended cropping of meaningful content, missing images, font fallback, texture edges, alpha halos and inconsistent icon alignment. Check loaded and fallback states. Preserve approved asset identity and intentional composition.
- Compare shared components across supported themes, sizes and states. Fix accidental style drift at its source when practical. Preserve intentional distinctions in emphasis, state and meaning.

## Responsiveness and stability

- Reproduce relevant lag or visual instability on the actual route. Observe before and after under comparable conditions. Check controls that move while a user is about to activate them, layout shifts after fonts or images load, flicker during state changes, input delay, and repeated requests or work during a single action.
- Use targeted runtime evidence such as timings, traces, frame recordings, request counts, or engine profiling as appropriate. Check slow loads and rapid repeated actions when relevant. Fix the observed cause and confirm the interface keeps appropriate feedback and recovery. Preserve supported visual quality, content and behavior.

