# TSL - Sign Language Learning App

TSL is a mobile learning application designed to help users learn and practice sign language through computer vision, AI-powered gesture recognition, and interactive educational content.

The project combines Flutter, Firebase, and TensorFlow Lite to provide a complete learning experience with a visual dictionary, recognition tools, and game-based exercises.

## Features

- Real-time sign recognition using computer vision
- AI-based gesture classification for sign language detection
- Visual dictionary of signs with image-based learning
- Interactive educational mini-games
- User authentication and profiles
- Firebase integration for data storage and backend services
- Multi-platform Flutter app for Android, iOS, Web, and desktop support

## Tech Stack

- Flutter / Dart
- Firebase Authentication
- Cloud Firestore / Realtime Database
- TensorFlow Lite
- Camera and image processing
- Python scripts for model validation and preprocessing

## Project Structure

- `lib/` — Flutter application logic and UI
- `android/` — Android native configuration
- `ios/` — iOS native configuration
- `backend/` — backend utilities and API-related code
- `assets/models/` — ML model files and labels
- `dictionnaire_DB/` — dictionary dataset and images
- `modele-ai-camera/` — AI and computer vision model scripts
- `test/` — test files and validation scripts

## Prerequisites

Before running the project, make sure you have:

- Flutter SDK installed
- Android Studio / Xcode configured for mobile builds
- Firebase project configured if you want to use authentication and database features
- Python environment if you plan to use the AI preprocessing scripts

## Installation

1. Clone the repository:

   ```bash
   git clone https://github.com/yasmine-manaa/TSL-main.git
   cd TSL-main
   ```

2. Install Flutter dependencies:

   ```bash
   flutter pub get
   ```

3. Run the app:

   ```bash
   flutter run
   ```

## Firebase Setup

This project includes Firebase configuration files and backend integration. If you want to use the authentication and database features, make sure the Firebase project is correctly configured and the required JSON/Plist files are present.

## Notes

- Some AI model files and large generated assets may need to be downloaded or placed in the correct folders before running the recognition features.
- The project contains both mobile app code and supporting scripts for training/validation workflows.

## Authors

This project was developed as a group project by:

- Yasmine Manaa
- Eya Manaa
- Maycem Ben Khemis

## License

This project is currently for educational and development purposes.
