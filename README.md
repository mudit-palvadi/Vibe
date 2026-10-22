# Vibe

[![CI](https://github.com/mudit-palvadi/Vibe/actions/workflows/ci.yml/badge.svg)](https://github.com/mudit-palvadi/Vibe/actions/workflows/ci.yml)
[![Flutter](https://img.shields.io/badge/Flutter-3.44.6-02569B?logo=flutter&logoColor=white)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-3.11-0175C2)](https://dart.dev/)
[![Riverpod](https://img.shields.io/badge/Riverpod-3.3-7C3AED)](https://riverpod.dev/)
[![Google Sign-In](https://img.shields.io/badge/Google_Sign-In-4285F4?logo=google&logoColor=white)](https://developers.google.com/identity/protocols/oauth2)
[![just_audio](https://img.shields.io/badge/just_audio-0.10-FF6D00)](https://pub.dev/packages/just_audio)
[![Hive](https://img.shields.io/badge/Hive-1.1-FFB300?logo=flutter&logoColor=white)](https://pub.dev/packages/hive_flutter)
[![crypto](https://img.shields.io/badge/crypto-3.0-795548)](https://pub.dev/packages/crypto)

A music app for the desktop, the phone and the web. The user signs in with their Google account, listens to the songs of the shared catalog, favourites them, and can add a song of their own.

The backend is a FastAPI service on AWS, it lives in [mudit-palvadi/Vibe-Backend](https://github.com/mudit-palvadi/Vibe-Backend).

---

## Screens

| | | |
| :---: | :---: | :---: |
| ![the home screen](docs/screenshots/home.png) | ![the tracks screen](docs/screenshots/tracks.png) | ![the favourites screen](docs/screenshots/favourites.png) |
| The home screen | The tracks of an album | The favourites of the user |

---

## What it does

- **Sign in with Google.** The system browser opens, the user comes back in the app, and the session is kept for the next time the app starts.
- **A session that survives a restart.** The token is kept on the device, it is renewed quietly when it is about to run out.
- **Playback in the background.** The music keeps playing when the app is closed, with the system media controls.
- **A waveform to scrub through.** The song shows its wave, the position can be dragged.
- **Search** on the title, the artist and the tags.
- **Favourites**, kept per user, with the recently played songs on top.
- **Uploads.** The audio and the cover go straight from the app to the storage bucket, the file never passes through the backend.
- **A shared catalog.** Every song is visible to everyone, whoever uploads one adds it for the whole app.

---

## The stack

| | |
| :--- | :--- |
| **Flutter and Dart** | The app itself, one code base for Android, iOS, web, Windows, Linux and macOS. |
| **Riverpod** | The state of the app, the user, the songs, the upload. |
| **google_sign_in_all_platforms** | The Google sign in, on the phone and on the desktop. |
| **just_audio** | The playback, with the background audio service. |
| **audio_waveforms** | The wave of the song and the scrubbing. |
| **Hive** | The session token and the recently played songs on the device. |
| **http** | The calls to the backend and the uploads to the bucket. |
| **crypto** | The hash of the body, the backend needs it for every request that has a body. |
| **file_picker** | Picking the audio file and the cover. |
| **fpdart** | The `Either` type, so a failure is a value and not an exception. |

---

## Getting started

You need the [Flutter SDK](https://docs.flutter.dev/get-started/install) and a Google OAuth client.

1. **Get the code**

   ```bash
   git clone https://github.com/mudit-palvadi/Vibe.git
   cd Vibe
   ```

2. **The packages**

   ```bash
   flutter pub get
   ```

3. **The settings** — copy `.env.example` to `.env` in the root of the project and fill it in:

   ```ini
   # the address of the backend
   BACKEND_URL=https://d3hb9a4bci0gq5.cloudfront.net

   # the google oauth client of the app, it is a web type client with the
   # address http://localhost:<GOOGLE_REDIRECT_PORT> as a redirect uri
   GOOGLE_CLIENT_ID=
   GOOGLE_CLIENT_SECRET=
   GOOGLE_REDIRECT_PORT=8000
   ```

   The `.env` file is not in the repository, it holds the client secret.

4. **The generated code** — the view models are made by build runner:

   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

5. **Run it**

   ```bash
   flutter run            # the desktop
   flutter run -d <id>    # a phone that is connected over usb
   ```

---

## The Google client

The app needs two clients in the [Google Cloud console](https://console.cloud.google.com/):

**A web type client** for the desktop. The app opens the system browser and comes back to `http://localhost:8000`, so that address has to be the **Authorized redirect URI**. Its id and its secret go into the `.env` of the app.

**An Android client** for the phone. It needs the package name of the app, `com.example.vibe`, and the SHA-1 of the signing key:

```bash
keytool -list -v -keystore C:\Users\<you>\.android\debug.keystore \
  -alias androiddebugkey -storepass android -keypass android
```

The debug key is enough when the app is not published. The id of the web client is the one the app sends to the backend, so the Android client does not have to be put anywhere.

---

## How the app talks to the backend

The session token travels in the **`x-vibe-auth`** header. CloudFront signs the request it forwards to the backend and replaces the `Authorization` header of the caller, so the token needs a header of its own.

A request that has a body also needs **`x-amz-content-sha256`**, the sha256 of the body in hex. Without it the backend answers with a `403`, the signature does not match.

| Call | What it does |
| :--- | :--- |
| `POST /auth/login` | Sends the Google id token, gets the session token back. |
| `POST /auth/refresh` | Sends the Google refresh token, gets a new session token back. |
| `GET /auth` | The user and the favourite songs. |
| `POST /song/upload-init` | Gets a song id and the two upload links. |
| `POST /song/upload-complete` | Says that the files are uploaded, the song is saved. |
| `GET /song/list` | Every song of the catalog. |
| `GET /song/search?q=` | The songs that start with the text. |
| `POST /song/favourite` | Adds the song to the favourites or takes it away. |
| `GET /song/list-favourites` | The favourite songs of the user. |

**The upload** goes straight to the storage bucket: the app asks for the links, puts the audio and the cover on them, and then tells the backend that it is done. The backend never carries the file.

---

## The tests

```bash
flutter analyze
flutter test
```

---

## The layout

```text
lib/
├── core/        the services, the models, the theme, the shared widgets
├── feature/     the pages, one folder for auth, home, library, music and search
└── main.dart
```

## The backend

The service the app talks to lives in [mudit-palvadi/Vibe-Backend](https://github.com/mudit-palvadi/Vibe-Backend), its readme has the endpoints, the sign in and the way it is deployed.
