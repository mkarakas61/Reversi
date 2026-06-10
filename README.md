# Reversi Android MVP

Flutter Android MVP for a local two-player Reversi/Othello game.

## Requirements

- Flutter SDK with Android toolchain
- Android emulator or physical Android device
- Optional Firebase Android app configuration at `android/app/google-services.json`

This repository was authored in an environment without Flutter or Gradle installed. After installing Flutter, run this once to let Flutter add any SDK-generated Android wrapper files that are missing from the manual scaffold:

```sh
flutter create --platforms=android .
```

Review generated changes before committing if this command updates Android wrapper files.

## Run

```sh
flutter pub get
flutter test
flutter run
```

## Build Test APK

```sh
flutter build apk --debug
```

The current workspace did not have Flutter installed when this project was created, so tests and APK build must be run after installing Flutter.

## Firebase

The app catches Firebase initialization errors so local development can run before Firebase is configured. To enable analytics on Android, create a Firebase Android app with package name `com.example.reversi`, then place `google-services.json` at `android/app/google-services.json`.
