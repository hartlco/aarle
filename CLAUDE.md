# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Aarle is a native iOS and macOS SwiftUI client for bookmark services: **Shaarli**, **Pinboard**, and **Linkding**. Written in Swift 6.0, targeting iOS 16+/macOS 13+.

## Build & Run

```bash
# Build and run via Xcode
open Aarle.xcodeproj

# Command-line build
xcodebuild -project Aarle.xcodeproj -scheme "Aarle (iOS)" build
xcodebuild -project Aarle.xcodeproj -scheme "Aarle (macOS)" build

# Run tests (each SPM module has its own tests)
xcodebuild -project Aarle.xcodeproj -scheme "Aarle (iOS)" test

# Format code
swiftformat --swiftversion 6.0 .
```

SwiftFormat config: `--wraparguments before-first`

## Architecture

**Modular SPM packages** — each domain concern is a separate Swift package under the repo root:

- `Types/` — Core models (`Link`, `PostLink`, `Tag`, `AccountType`) and the `BookmarkClient` protocol
- `List/` — `ListState` for managing loaded links
- `Navigation/` — `NavigationState` for routing
- `Settings/` — Settings UI and state
- `Archive/` — Offline article archiving (`ArchiveState`)
- `Tag/` — Tag management and filtering
- `AarleKeychain/` — Keychain wrapper (uses `KeychainAccess` dependency)

**Shared code** lives in `Shared/`:

- `Networking/` — API clients: `ShaarliClient`, `PinboardClient`, `LinkdingClient`, plus `ClientFactory` (factory pattern via `UniversalClient`)
- `Stores/OverallAppState.swift` — Main state container composing all sub-states
- `Views/` — SwiftUI views (list, detail, add/edit forms, web view, sidebar)
- `Services/MetadataService.swift` — Website metadata fetching

**State management** uses Swift `@Observable` macro. `OverallAppState` is the root, composing `ListState`, `TagState`, `EditState`, `AddState`, `NavigationState`, `SettingsState`, `ArchiveState`.

**Client abstraction**: All three bookmark services implement the `BookmarkClient` protocol. `ClientFactory.createClient()` returns a `UniversalClient` wrapping the appropriate implementation based on `AccountType`.

## Targets

Four build targets: iOS app, macOS app, iOS Share Extension, macOS Share Extension. Share extensions allow adding bookmarks from the system share sheet.

## Key Dependencies

- `KeychainAccess` — Secure credential storage
- `SwiftJWT` — JWT signing for Shaarli auth
- `Introspect` / `SwiftUIX` — SwiftUI utilities
