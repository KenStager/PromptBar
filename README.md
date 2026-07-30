# PromptBar

A macOS menu bar app for storing and retrieving AI prompts, with local classification
through Ollama so nothing leaves the machine.

Prompts live in SQLite behind an FTS5 index, which is what keeps search under 10ms on the
test corpus. A global hotkey opens the bar from anywhere; selecting a prompt copies it to
the clipboard, optionally rendered as Markdown.

## Status

Personal project, built to the point where it was useful to me and then parked. It builds
and runs on macOS 14+, and search and storage work. Rough edges I know about:

- Markdown copy formatting is unreliable.
- Idle memory sits near 82MB against a 50MB target. The NSStatusItem and theme
  allocations are the likely culprits, unprofiled.
- The Ollama analysis path is implemented but was never benchmarked.

An earlier save-path bug was fixed in a761326, where prompt mapping dropped persistence
fields. I haven't run a full pass since, so treat the save path as working but lightly
exercised.

This is published for the structure rather than as a product. If you want a polished
prompt manager, this isn't one yet.

## Build

```bash
open PromptBar.xcodeproj      # then Cmd-R

# or from the command line
xcodebuild -scheme PromptBar -configuration Debug
```

Requires macOS 14.0+ and Xcode 16+, plus Ollama running locally for the classification
features. The app is sandboxed, so the database lands in the app container.

## Design

SwiftUI, dropping to AppKit where the menu bar requires it. MVVM with constructor
injection through a hand-rolled `DIContainer` — no framework, since the object graph is
small enough that one wouldn't earn its keep.

```
PromptBar/
├── Models/          Prompt domain model
├── Database/        SQLiteDatabase, Migrations
├── Repositories/    PromptRepository — all SQL lives behind this
├── UseCases/        SavePromptUseCase and friends
├── Services/        ClipboardManager, OllamaClient, HotkeyManager, AnalysisQueue
├── Shared/Theme/    design tokens
└── *View.swift      MainView, SavePromptView, PromptDetailView, PreferencesView
```

The repository boundary is the part worth looking at. SQL is confined to
`Repositories/`, use cases depend on the protocol rather than the concrete type, and
`AnalysisQueue` keeps Ollama calls off the UI path so a slow local model can't stall the
menu bar.

## License

No license yet, all rights reserved. Ask if you want to use any of it.
