# Kard — Quick Snap Business Card (Simple MVP)

[Medium](https://medium.com/@kingki/bdc846e3fe71)

SwiftUI MVP for creating, editing, exporting (AirDrop) and importing digital business cards (JSON + PNG).

## Implemented (Stage 1 → 4)
- SwiftUI App entry (`kardApp`)
- Model: `Card` (+ Codable, timestamps)
- Disk persistence: per-card JSON files + PNG image assets in Documents/cards/
- Image capture / selection with center-aspect crop (Scan workflow)
- Card creation & editing (fields, notes, color palette, image replace)
- Color palette utility + hex color support
- Share / AirDrop export (JSON + optional PNG) via `ShareExporter` (temporary files under /tmp/kard-export)
- Import (Document Picker: multi-select JSON (+ optional PNG) with UUID collision handled by generating new UUID and remapping image filename)
- Delete cards (with file cleanup)
- Basic accessibility labels on key buttons

## Sharing / Import Details
**Export**
1. In `CardDetailView` tap Share (square.and.arrow.up).
2. App generates `{name-or-uuid}.json` and, if an image exists, `{name-or-uuid}.png` in a fresh temporary directory.
3. A `UIActivityViewController` (AirDrop-focused) is presented with those file URLs.

**Import**
1. Tap the import button (square.and.arrow.down) on Home.
2. Select one or more JSON files (optionally also select their PNG siblings). PNGs are ignored unless a JSON with the same stem is chosen.
3. For each JSON: decode `Card`; if its UUID already exists locally a new UUID is assigned (and image filename remapped).
4. If a matching PNG (same stem) exists it is copied into local storage; otherwise image reference is cleared.
5. Result count or error is surfaced via alert.

## Data Locations
- JSON: `Documents/cards/<uuid>.json`
- Images: `Documents/cards/<uuid>.png`
- Temp export: `tmp/kard-export/{stem}.json|png` (recreated on each share)

## Not Yet Implemented (Future)
- OCR / automatic data extraction
- Cloud sync / multi-device
- Advanced theming / multiple layout templates
- Onboarding & richer accessibility audit
- Unit/UI test suite

## Running
Open `kard.xcodeproj` in Xcode (iOS 15.6+ target) and run on device or simulator. AirDrop sharing requires a physical device.

## Dev Notes
- `ShareExporter.export` overwrites the temp export folder each invocation to keep artifacts clean.
- Import only processes files with `.json` extension (extra selected PNGs are simply ignored unless their JSON counterpart is also chosen).
- Collision strategy: generate new UUID; image filename becomes `<newUUID>.png`.

## License
TBD
