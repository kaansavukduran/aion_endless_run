# Exact lazy row sheets

These are mechanical source crops for two measured first-use decode hotspots.
They add no new artwork and do not resize, recolor, quantize or redraw anything.
The original `keepers-walk.png`, `legacy-deaths.png`, their imports and source
provenance remain in the repository.

`CAMPAIGN-ROW-SHEETS.json` records original PNG/import hashes, the decoded
original pixel hash, every crop origin and each resulting PNG hash. Registered
masks, frame rectangles, scales and actor offsets remain authoritative in the
original provenance. Only the source coordinates supplied to a crop change.

The pixels come from the existing imported CTEX rather than a fresh lossy
conversion. This matters because the original legacy-deaths sheet uses a lossy
WebP import: cropping its original PNG would subtly change the current rendered
colors. Row PNGs are lossless, and their imports disable duplicate alpha-border
processing because those source pixels have already been processed. No new
lossy compression is applied.

Eight keeper rows and nine enemy-death rows load individually when requested.
The shared bounded source cache and isolated cel cache continue to work as
before. No row image is preloaded at startup. The original full sheets can be
excluded from release exports once the requested strip resources are verified;
keep the repository source PNGs and all JSON provenance.

To regenerate, first import the original project with Godot 4.6.3, then run
`python3 packaging/pack_campaign_row_sheets.py`, followed by another normal
Godot import. `tests/test_campaign_row_sheets.gd` compares all 102 actual runtime
cels, full row RGBA crops, offsets, scales, source hashes and lazy resource
selection. This exactness test requires repository source/import artifacts and
is separate from ordinary gameplay or shipped-browser verification.
