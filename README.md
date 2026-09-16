# Brew Coffee

Offline-first Flutter app for home baristas to catalog beans, grinders and brew methods, then log extraction recipes with an automatically calculated brew ratio.

## Getting started

```bash
flutter pub get
flutter run
```

The app uses Riverpod for state and SQLite (`sqflite`) for local persistence. The database is created in the platform application documents directory and enables foreign-key enforcement.

## Structure

```text
lib/
  core/enums.dart             # Domain enums and display labels
  data/models.dart            # Domain models
  data/app_database.dart      # SQLite schema, constraints and seed data
  data/repositories.dart      # Relational CRUD boundaries
  providers.dart              # Riverpod providers
  ui/home_page.dart           # Brew history
  ui/log_brew_page.dart       # Validated brew form and ratio preview
  main.dart
```
