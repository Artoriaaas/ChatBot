# Paper & Ink

A research paper reader with AI chat — Flutter desktop prototype.

## Screenshot

(Placeholder — screenshots will be added after visual review)

## Features

- **Library**: Browse, search, filter, and organize research papers
- **Reader**: Paginated mock reader with text selection, highlighting, and search
- **AI Chat**: Ask questions about papers with mock streaming responses and citations
- **Notes**: Save AI responses, edit, search, and export as Markdown
- **Settings**: Light/Dark/System theme, font sizes, reduce motion

## Demo vs Real

| Feature | Status |
|---------|--------|
| Paper content | Mock — 6 built-in demo papers with realistic text |
| PDF rendering | Not implemented — uses styled text reader |
| AI responses | Mock — pre-written responses streamed with delays |
| Paper import | UI only — not functional in demo |
| Notes persistence | Real — saved to local storage, survives restart |
| Theme persistence | Real — saved to local storage |
| Settings | Real — all settings persist locally |
| Markdown export | Real — creates actual .md file |
| Text selection | Real — works in mock reader |
| Citation navigation | Real — navigates to correct page/section |

## Verification Status

`flutter analyze` ✅ No issues found  
`flutter test` ✅ 4/4 tests passed (Flutter 3.47.4)

## Known Limits

- AI chat uses mock responses — no real LLM integration
- PDF rendering is not implemented; reader is a styled text mock
- Paper import is UI-only — demo mode only
- Window resizing below 1000 px switches to tab-based navigation
- Visual screenshots have not been captured yet

## Getting Started

### Prerequisites
- Flutter SDK 3.47+ (stable channel)
- Windows desktop development tools (Visual Studio with C++ workload)

### Run
```bash
flutter pub get
flutter run -d windows
```

### Test
```bash
# On Windows, set PROGRAMFILES(X86) first if it's missing:
[Environment]::SetEnvironmentVariable('PROGRAMFILES(X86)', 'C:\Program Files (x86)', 'Process')

flutter test
flutter analyze
```

## Architecture

- **State Management**: ChangeNotifier + ListenableBuilder (no external packages)
- **Theme**: ThemeData + ColorScheme + ThemeExtension (AppColorsExtension)
- **Persistence**: shared_preferences for settings and notes
- **Font**: Inter via google_fonts (requires network on first run, then cached)

### Dependencies
- `google_fonts` — Inter font with Vietnamese support
- `shared_preferences` — Local persistence
- `flutter_markdown` — Markdown rendering in chat
- `path_provider` — File export paths

## Project Structure
```
lib/
├── main.dart
├── app/theme/          # Design tokens, ThemeData, typography, motion
├── models/             # Paper, ChatMessage, Note
├── services/           # Mock repositories and AI service
├── features/
│   ├── library/        # Paper list with search/filter
│   ├── reader/         # Paper workspace (reader + chat)
│   ├── chat/           # AI chat panel
│   ├── notes/          # Saved notes management
│   └── settings/       # App settings
└── shared/widgets/     # App shell, splitter, badges
```

## Design

Style: Paper & Ink — quiet, clear, polished, for research.
- Warm paper background (light mode)
- Deep teal-dark background (dark mode)
- Teal accent color
- Warm yellow for document highlights
- Inter font, clean typography
