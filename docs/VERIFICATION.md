# Verification record

Release 1.0.0 · 2026-10-05

## Rule runner

48 checks passed on Intel macOS 15.8 with Swift 6.1.2 in Swift 5 language mode. The runner covers catalogue integrity, Turkish search, ordering/filtering, archive identity/version/limits, malformed data, atomic save, recovery copies, photo bounds, deterministic game behavior and the generated WAV header.

    swift run -j 2 MaziRulesTests

## Actual AppKit integration

The application's smoke mode exercises native NSButton action dispatch, scene hotspot selection, the memory editor's real field values and save callback, photo conversion/validation, reload persistence, question navigation, marble controls, hopscotch controls and minimum window geometry. It also decodes the original ambient sound through NSSound and produces screenshots of the real views and an exported postcard.

    swift build -j 2
    .build/debug/MaziSandigi --smoke-test --screenshots output/verification

All smoke checks passed locally. The mode uses a unique temporary archive, fictional text and the original room illustration as its test image; no personal journal is read or overwritten.

## Package and CI

The release script builds both x86_64 and arm64 slices, checks their presence with lipo, verifies bundle signing and executes the bundled smoke test from an independent working directory. GitHub Actions repeats rules and AppKit checks on native Intel and arm64 hosts, then verifies a Universal package. Actual run results are visible in the repository Actions tab.

    ./scripts/package.sh 1.0.0

## Visual inspection and limits

The salon, editor, journal, story cards, games and postcard were rendered and inspected. The window's minimum geometry was checked; larger content scrolls. The interface uses native labels/controls, keyboard menu shortcuts and accessibility labels, but a full VoiceOver audit was not performed.

A physical speaker listening session, every dialog interaction, every supported OS release and every Mac model were not individually verified. A lower deployment target is not evidence of physical testing on macOS 11. Gatekeeper first-launch handling depends on the user's Mac policy; the app has an ad-hoc signature and is not notarized. No usability or nostalgia-effect study was performed.
