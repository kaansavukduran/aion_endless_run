# UI checks

## Headings, copy and visual hierarchy

- Walk the screen in reading and focus order. Give each view a clear primary title and each subordinate heading a real group to label. Flag a badge, eyebrow, decorative “01”, subtitle or adjacent label only when it repeats the same meaning or has no navigational, ordinal, or state purpose. Preserve progress such as “2 / 4”, actual step numbering, version and distinct section names. Retain accessible dialog names and semantic headings when simplifying the visible stack.
- Check that the most important action is recognizable from its label and emphasis. Keep visible and accessible names aligned. Remove repeated descriptions and empty success claims. Preserve essential controls, tutorial information, error recovery, action consequences, units and accurate state. Use short project terminology and real localized strings. Exercise the action: flag decorative buttons with no handler, misleading enabled states, hardcoded fake progress and duplicate actions with conflicting handlers.
- Check actual uses of repeated cards, badges, icons, radius, borders, shadows and motion against the local design system. Collapse containers with no grouping function and align equivalent controls by optical and actual hit area. Confirm that the fix still looks intentional in each supported theme. Keep motion that conveys state and respect reduced-motion settings. Inspect long labels and sibling rows in the actual theme for optical balance, distinguishable disabled/focus states, and contrast on the surface the text really sits on.

## Scroll, fit and reachability

- For a short confirmation, result, settings group, or control panel, verify that its title, content and primary actions fit together at normal scale in the smallest supported layout where the content can naturally fit. Inspect the panel, its ancestors and viewport. Start before any automatic scrolling or test-assisted focus. Try mouse wheel, touch and keyboard on the affected path. Check for invisible scroll, unnecessary nested scroll, clipped last row, fixed bars, safe areas, focus traps and intercepting overlays. When checking a no-scroll panel, assert the entire primary hit target fits initially, then activate it through the normal input path.
- For long lists, logs and documents or legitimately enlarged content, prefer one clear vertical scroll owner. Ensure the end of content and essential actions remain reachable by supported inputs. Preserve native scrolling and any meaningful two-dimensional content such as the game world or a wide data table. At high text/zoom settings, allow necessary scrolling instead of shrinking text, cropping, hiding a scrollbar, or silently removing content.
- In web UI, inspect fixed heights, padding and borders, flex/grid minimum sizes, intrinsic width, wrapping, and overflow on the actual scroll container. Check scroll/client dimensions and element bounds after fonts, assets, and state settle. Subpixel rounding and scrollbars inside intentional lists are context signals. Compare the target with clipping ancestors and the visible viewport. Verify actual click/tap, keyboard focus and resulting state; geometry or a screenshot alone can miss an overlay or dead control.
- In native UI, check intrinsic sizes, wrapping, safe areas, system scaling, layout bounds and actual hit targets using the platform's equivalent tools. Preserve inputs or in-progress state across a resize, rotation or keyboard open/close. Test focus restoration after closing an overlay.

## Select test conditions from supported targets

| Risk | Useful cases |
| --- | --- |
| Small viewport or fixed chrome | Smallest supported width and height, short desktop window, mobile portrait and landscape, browser chrome and onscreen keyboard as applicable |
| Text expansion | Real long Turkish and English strings where supported, user-selected and fallback fonts, system text size, 200% text or UI scaling as applicable |
| Web reflow | Test appropriate text UI at 320 CSS px equivalent width, with legitimate two-dimensional exceptions scoped to the affected content. Check text resize separately from UI scale and browser zoom. |
| State and accessibility | Default plus the relevant loading, empty, long, error and result states. Tab or directional navigation, visible focus, close/back, focus restoration, touch, and actual activation where supported. |
| Shared layout | Other uses of the same panel/container or action bar, each supported theme when affected, and at least one normal layout as a control |

Use the existing project matrix and target builds. Emulated mobile/browser inputs are useful evidence for that environment. Report physical-device, hardware-input and assistive-technology results only when observed.

