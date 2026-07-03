# Theme architecture

The app uses centralized Material 3 light and dark themes from
`lib/core/theme/app_theme.dart`.

## Semantic colors

`AppColors` is a `ThemeExtension` containing semantic tokens instead of
page-specific colors. Widgets read the current palette through
`context.appColors`. Light and dark values live together in
`lib/core/theme/app_colors.dart`; feature widgets must not introduce literal
light-only colors.

Typography is read from `Theme.of(context).textTheme` so heading, body, label,
and caption colors follow the active palette while preserving the existing
size and weight hierarchy.

## Theme selection

`ThemeController` owns `ThemeMode` and persists an explicit light or dark
selection through `SharedPreferences`. With no saved selection, the app uses
`ThemeMode.system`.

`AppTopBar` provides the accessible theme toggle on every page that uses the
shared top navigation. Theme and icon transitions respect the platform's
reduced-motion setting where available.
