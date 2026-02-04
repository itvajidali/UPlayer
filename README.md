# UltimatePlayer - Flutter Music Player

A beautiful iOS-styled music player built with Flutter.

## Setup Instructions

Since your `flutter` command was not automatically detected, you will need to ensure Flutter is set up before running the app.

1.  **Open the Project**:
    Open the folder `d:\Projects\UltimatePlayer` in VS Code or Android Studio.

2.  **Install Dependencies**:
    Open a terminal in that folder and run:
    ```bash
    flutter pub get
    ```

3.  **Run the App**:
    Connect your device or start a simulator/emulator and run:
    ```bash
    flutter run
    ```

## Features

-   **iOS Design**: Uses `Cupertino` widgets for a native iOS feel.
-   **Audio Playback**: Streaming audio using `just_audio`.
-   **Glassmorphism**: Blurred background effects on the player screen.
-   **Progress Bar**: Interactive seek bar.

## Troubleshooting

If you see errors about missing files (e.g., `android/`, `ios/` folders), you may need to recreate the platform scaffolding:
1.  Run `flutter create .` inside the `d:\Projects\UltimatePlayer` directory.
2.  This will generate the missing platform folders without overwriting the `lib/` code I created.
