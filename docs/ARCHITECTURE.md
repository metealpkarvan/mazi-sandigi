# Architecture

## Native application

Swift and AppKit, deployment target macOS 11, no third-party runtime dependencies. A Swift Package builds two executables: the actual application and a small Foundation rule runner, allowing development with Command Line Tools without XCTest/full Xcode.

MaziCore contains a typed catalogue, validated Codable archive, atomic local store, Turkish-tolerant search, two deterministic game engines and original WAV synthesis. MaziSandigi contains the AppKit window, native editor, illustrated hotspots, postcard view and menu wiring. Data is never loaded from a remote endpoint.

The window uses resizable content geometry, a persistent navigation sidebar, scrollable content and native editing controls. Game timers do not affect saved memories. The smoke mode disables timers and uses a unique temporary archive; it does not read or write the user's real journal.

## Save and recovery

The controller builds a proposed archive, validates it and saves it before adopting the new state. A failed save leaves the previous in-memory archive and on-disk file available. Data.write atomically replaces the JSON file; file permissions are set to owner read/write when the OS permits it.

An unreadable local file puts the editor into a protected state and leaves the file untouched. Import rejects wrong identity/version, oversized data, duplicate identifiers, invalid records and malformed photo data before a replacement confirmation. A confirmed restore copies the previous file to a unique recovery filename before saving the imported one. Recovery copies intentionally remain until the user removes them.

Archive version 1 supports 100 memories, at most 10 photo-bearing memories, 2 MB per JPEG and 30 MB total. Dates may be unknown; supplied years must be 1800–2100. This is a field bound, not historical validation.

## Photos and exports

ImageIO reads only files selected by the user. The input file is bounded to 20 MB/40 megapixels before decoding; a transformed thumbnail has a maximum edge of 1600 pixels and is re-encoded as JPEG. The source file is untouched. Backup photo import also checks dimensions and successful decoding.

A .mazi file is validated JSON with base64 photo bytes, never an executable archive. Markdown intentionally excludes binary photos and states that a complete backup is needed to preserve them. Postcards show at most 340 characters and clearly mark an excerpt when the original story is longer.

JSON, recovery copies, Markdown and PNG are unencrypted. Local storage offers control, not an encryption or shared-device security guarantee.

## Games and sound

The marble engine uses analytic deceleration within capped time steps. A throw settles and scores once, with five shots per game. Hopscotch ignores input until the preview is hidden, rejects wrong steps and ends after a seven-step round. UI controls share these same engines; visual motion is not a separate simulation.

The original deterministic PCM WAV is decoded by NSSound. It is off at launch, loops only on an explicit user action and stops on exit. There are no recordings, radio stations or song assets.

## Universal distribution

The package script compiles x86_64 and arm64 release executables separately for macOS 11, joins them with lipo, embeds the artwork/icon/license/plist and verifies an ad-hoc signature. It runs the packaged smoke check from a staging directory so the Resources fallback cannot mask a missing bundled image.

A Universal archive is native on both Mac CPU families. Apple Developer ID signing and notarization are separate distribution steps and were not performed. macOS 11 is the deployment target; the verification record lists the hosts actually exercised.
