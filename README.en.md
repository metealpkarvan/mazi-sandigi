# Mazi Sandığı — A Chest of Memories

A Turkish-language native macOS app for personal memories inspired by everyday cultural objects: tea glasses, a lace-covered television, cassettes, school notebooks, neighborhood shops and family visits.

**[Download for Mac](https://github.com/metealpkarvan/mazi-sandigi/releases/latest)** · [Türkçe](README.md)

![The illustrated living room](docs/salon.png)

## What you can do

Explore 18 memory doors across six themes. Write a story with an approximate year, place, people and an optional photo. Edit, star, search and filter your entries. Use 36 original interview questions to start a conversation with someone close to you. Export a short PNG postcard, a Markdown text collection or a complete .mazi backup including photos.

Take a small break with two desktop games inspired by marbles and hopscotch. Optional quiet rain and clock ambience is synthesized locally; there are no commercial songs or streaming services. Sound starts off.

The objects invite personal recollection; the app does not claim that everyone in Türkiye had the same upbringing. Recorded stories are personal testimony, not independently verified history. The interface is Turkish; this English guide is for people exploring or contributing to the project.

## Run the app

macOS 11 or later. One Universal app contains native Intel x86_64 and Apple Silicon arm64 executables; Rosetta is not required.

Download MaziSandigi-v1.0.0-universal.zip, extract it and move Mazi Sandığı.app into Applications. Open it and start with an empty journal. No Xcode, Swift installation, account, API key or network connection is needed.

The app is **ad-hoc signed for integrity, not Developer ID signed or notarized**. macOS may block the first launch. After trying to open it, use System Settings → Privacy & Security → Open Anyway if you trust the source. Older macOS versions use System Preferences → Security & Privacy. [Apple's instructions](https://support.apple.com/en-us/102445)

Download SHA256SUMS.txt beside the ZIP and verify:

    shasum -a 256 -c SHA256SUMS.txt

## Data ownership

Entries live in ~/Library/Application Support/MaziSandigi/hatiralar.json. No analytics, accounts or remote storage. Selected photos are normalized copies, not a scan of your photo library. No microphone recording. The Help menu's GitHub link opens externally only when selected.

Data and backups are **unencrypted**. Postcards and exports may contain private stories and photos. Ask the storyteller before sharing. Limits: 100 entries, 10 entries with a photo, 2 MB per normalized JPEG, 30 MB per backup. Source photo files are unchanged; copies use a maximum edge of 1600 pixels.

Saving validates the archive and writes atomically. Invalid imports never replace records. A confirmed restore first preserves a separate recovery copy. An unreadable local archive leaves the original untouched and puts editing into a protected state; restore a sound backup or open the archive folder from the File menu.

## Build and verify

Requires Apple Command Line Tools, Swift 5.7+ and a macOS SDK. Full Xcode is optional.

    swift run -j 2 MaziRulesTests
    swift run -j 2 MaziSandigi
    swift build -j 2
    .build/debug/MaziSandigi --smoke-test --screenshots output/verification
    ./scripts/package.sh 1.0.0

GitHub Actions checks native Intel and arm64 runners and builds a Universal package. Local verification ran on Intel macOS 15.8. macOS 11 is the deployment target, not a claim of physical testing on every OS or Mac. See [verification](docs/VERIFICATION.md), [architecture](docs/ARCHITECTURE.md), [cultural design sources](docs/DESIGN.md) and [artwork provenance](docs/ARTWORK.md).

MIT © 2026 Mete Alp Karvan
