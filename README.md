# PassKeyra

A zero-knowledge, cross-platform password manager built with Flutter.

**Website**: [passkeyra.com](https://passkeyra.com) — **Google Play**: [com.passkeyra.app](https://play.google.com/store/apps/details?id=com.passkeyra.app)

---

## Highlights

- **Zero-knowledge architecture** — your master password never leaves the device, the server (when enabled) only ever sees encrypted blobs.
- **Strong cryptography** — AES-256-GCM for vault encryption, PBKDF2-HMAC-SHA256 with **600 000 iterations** for key derivation (legacy 150 000 still readable for backward compatibility).
- **Local-first** — entries stored in an encrypted [Hive](https://pub.dev/packages/hive) database; cloud sync (Firebase) and backup (Google Drive) are optional and opt-in.
- **Multi-language** — French, English, Spanish (i18n via Flutter ARB files).
- **Free + Premium** — local vault, generator, security report are free; cloud sync, multi-device, and ad removal are Premium.

## Tech stack

| Layer | Choice |
|---|---|
| Framework | Flutter 3.8+ / Dart 3.8+ |
| Local storage | [Hive](https://pub.dev/packages/hive) (encrypted box) |
| Cryptography | [pointycastle](https://pub.dev/packages/pointycastle) + [cryptography](https://pub.dev/packages/cryptography) (AES-GCM, PBKDF2) |
| Cloud sync (optional) | Firebase Auth (Google Sign-In) + Firestore |
| Cloud backup (optional) | Google Drive API |
| State | Standard Flutter (`ChangeNotifier` / `setState`) |

## Platforms

| Platform | Status |
|---|---|
| Android | Production (Google Play) |
| iOS | Roadmap |
| Windows / macOS / Linux | Roadmap |
| Web (PWA) | Roadmap |

## Build from source

```bash
flutter pub get
flutter gen-l10n
flutter build apk --release --no-tree-shake-icons
```

For Google Play AAB:

```bash
flutter build appbundle --release --no-tree-shake-icons
```

### Firebase setup (required if you build a working app)

This repository **does not include `google-services.json`** (it would expose API keys). To run the app yourself:

1. Create a Firebase project at https://console.firebase.google.com
2. Add an Android app with the package name `com.passkeyra.app` (or your own).
3. Download `google-services.json` and place it in `android/app/`.
4. Same for iOS: `GoogleService-Info.plist` in `ios/Runner/`.

If you only need to build the **local-only** version of the app (no cloud sync), you can stub Firebase initialization — but this is not currently a supported build mode and would require code changes.

### Android signing

To produce a release APK/AAB, create your own `android/key.properties`:

```properties
storePassword=...
keyPassword=...
keyAlias=...
storeFile=/path/to/your-keystore.jks
```

This file is gitignored.

## Project structure

```
lib/
├── main.dart
├── app/              ← App-level setup
├── l10n/             ← Translations (fr, en, es)
├── models/           ← Data models (Hive types)
├── pages/            ← Screens
├── services/         ← Crypto, auth, sync, backup, ads
└── widgets/          ← Reusable UI components
```

## Contributing

PRs welcome. A few ground rules:

- Any UI string change must be added to **all three** ARB files: [lib/l10n/app_fr.arb](lib/l10n/app_fr.arb), [lib/l10n/app_en.arb](lib/l10n/app_en.arb), [lib/l10n/app_es.arb](lib/l10n/app_es.arb), then regenerate via `flutter gen-l10n`.
- No mocks in tests unless explicitly justified.
- Run `flutter analyze` — it should report zero issues before opening a PR.

## Security

If you discover a vulnerability, please **do not open a public issue**. See [SECURITY.md](SECURITY.md) for the responsible disclosure process.

## License

PassKeyra is licensed under the **GNU General Public License v3.0** — see [LICENSE](LICENSE).

Copyright © 2025 Steven Couton

## Contact

- General: contact@passkeyra.com
- Website: [passkeyra.com](https://passkeyra.com)
