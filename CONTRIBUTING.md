# Contributing

This started as a weekend project and sat archived for two years — contributions of any
size are genuinely welcome, not just tolerated.

## Good first contributions

- **Translations.** The app is built on `easy_localization` and only ships English today.
  Adding a language is a JSON file, not a code change:
  1. Copy `assets/translations/en.json` to `assets/translations/<locale>.json` and
     translate the values (keep the keys identical).
  2. Add the new `Locale(...)` to `supportedLocales` in `lib/main.dart`.
  3. Regenerate the generated key file:
     ```bash
     flutter pub run easy_localization:generate -S ./assets/translations -O ./lib/ -f keys -o locale_keys.g.dart
     ```
  This is exactly how the existing language infrastructure got here in the first place —
  a contributor added it, no one asked for it up front.
- **A screenshot or two.** If you're running this against real hardware, a picture of the
  app mid-use for the README is a genuinely useful PR.
- **Bug fixes.** Check `git log` for recent commits before assuming something is
  unhandled — several rounds of bug-fixing already went through independent audits.

## Before opening a PR

- `flutter analyze` should not add new warnings (the generated `locale_keys.g.dart` file's
  lint notices are pre-existing and expected).
- If you touch `lib/services/mqtt_service.dart`, keep the certificate pinning intact —
  it checks the presented cert against a pinned DER byte string, not just "is TLS on."
  Loosening that quietly reopens a MITM path.
- Real broker credentials go in `lib/core/config/secrets.dart` (gitignored); only
  `secrets.dart.example` should ever be committed.
- Small, focused PRs over large ones.

## Bigger changes

Open an issue first for anything that changes the MQTT topic contract or payload shapes —
those are shared with the [firmware](https://github.com/menezmethod/PetFeederESP), so a
change here needs a matching change there, not just an app-side patch.

## Reporting a bug

Include what you saw and expected, whether the app was connected to a real feeder or just
the broker, and the relevant `logDebug` output if you have it (only printed in debug
builds).
