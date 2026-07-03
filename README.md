# English Learning

A mobile-first Flutter app for focused daily English practice, including tiny
lessons, speaking support, roleplay, vocabulary, and AI-assisted learning.

## UI architecture

The app uses a feature-first structure. Shared visual rules live in
`lib/core/theme`, reusable interface components live in `lib/shared/widgets`,
and feature-specific pages and widgets stay inside `lib/features`.

Design tokens are centralized in:

- `app_colors.dart`
- `app_typography.dart`
- `app_spacing.dart`
- `app_radius.dart`
- `app_shadows.dart`
- `app_theme.dart`

New screens should use `AppScaffold`, `AppCard`, the shared button variants,
`SectionHeader`, and `AppBottomNavBar` instead of defining local visual styles.
The current project does not bundle a custom font asset, so the theme uses the
platform font. Plus Jakarta Sans can be added later as a bundled asset without
changing individual widgets.

## Current screens

- Home
- AI Coach practice menu
- Tiny Lesson with Vocabulary, Phrases, and Tips tabs
- Slang Hang with generated two-person dialogue and expression notes

Tiny Lesson generates personalized content from a required proficiency level
and usage context or theme through the configured backend Worker. It starts
without dummy lesson data and renders learning content only after a successful
AI response. Gemini is never called directly from Flutter. See
[`docs/ai-endpoints.md`](docs/ai-endpoints.md) for the request contract and
security boundary.

Learn, Lexicon, and Profile remain planned destinations. Their existing
coming-soon behavior is preserved. The center AI Coach action opens the
practice-mode menu; Tiny Lesson is entered from that menu.

## Manual verification

This repository intentionally avoids automatic Flutter builds and test runs on
limited hardware. To verify locally when appropriate:

```sh
flutter analyze
flutter test
flutter run
```
