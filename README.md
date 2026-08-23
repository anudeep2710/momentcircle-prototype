# MomentCircle prototype

MomentCircle is a consent-first event photo index for weddings and family functions. A host brings one shared archive into an event; a guest joins by QR, enrolls with up to three selfie samples, finds authorized moments, reviews an uncertain match, and can revoke the event identity.

This repository is the **judge-ready interaction prototype** for the iQOO Hackathon. It is intentionally deterministic so the three-minute demo never depends on a network, a cloud model, or a real person’s photos.

## What is working in this prototype

- Six-step product story: Create → Join → Enroll → Search → Confirm → Delete.
- Deterministic event fixture: 300 archive photos, 10 opt-in participants, and 127 authorized matches.
- Consent screen with three selfie slots and event-scoped identity language.
- Private album view with event filters and a device-lock screen.
- Native `local_auth` integration point for Android biometrics/PIN; the web preview uses a safe demo unlock fallback.
- Safety tab covering opt-in, event-only scope, traceable evidence, deletion, and retention.
- Responsive Flutter UI for Android and web preview.

The QR graphic and match cards are deterministic visual fixtures in this first prototype. The camera/QR/ML Kit packages are included in the dependency surface; production wiring belongs behind the interfaces described in [`docs/architecture.md`](docs/architecture.md).

## Run locally

```powershell
flutter pub get
flutter run -d chrome
```

For Android:

```powershell
flutter run -d <device-id>
flutter build apk --debug
```

The debug APK is produced at `build/app/outputs/flutter-apk/app-debug.apk`.

### Download a release APK

The shareable Android artifacts are published at [MomentCircle v0.1.0](https://github.com/anudeep2710/momentcircle-prototype/releases/tag/v0.1.0). For a current iQOO/ARM64 phone, download `app-arm64-v8a-release.apk`.

## Three-minute walkthrough

1. Tap **Create event + QR**.
2. Tap **Scan event QR** (the prototype advances through the deterministic invite fixture).
3. Tap **Consent + capture 3 selfies**.
4. Tap **Open private album** and switch to the Album tab if desired.
5. Tap **Reject low-confidence match**.
6. Tap **Delete identity** and show the revoked state.
7. Open **Safety**, lock the gallery, and demonstrate the unlock boundary.

## Technology choices

- Flutter and Dart for the phone-first UI.
- `google_mlkit_face_detection` for capture validation (face presence, pose and quality); it is not used as an identity recognizer.
- OpenCV YuNet + SFace in the planned local worker for face detection, alignment, embeddings, and event-scoped similarity matching.
- Appwrite Auth, Storage, Tables/Databases, Functions and Realtime for the production backend contract.
- `local_auth` backed by Android `BiometricPrompt` for the native gallery lock.
- `mobile_scanner` for the production QR camera path.

## Configuration boundary

The prototype runs without cloud credentials. Never commit an Appwrite API key, service account, `.env` file, real guest photos, or face embeddings. See [`docs/architecture.md`](docs/architecture.md) for the Appwrite collections, private buckets, worker contract, and privacy boundaries.

## Honest prototype boundary

This is not yet the production ingestion/indexing service. The first shareable artifact proves the product loop and safety behavior with a seeded fixture. The next implementation slice replaces the deterministic adapter with:

1. Appwrite event creation and private file upload.
2. Local Python worker using YuNet + SFace.
3. Consent selfie staging and embedding deletion.
4. Real QR camera scanning and authorized thumbnail retrieval.
