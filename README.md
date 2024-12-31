# <img src="assets/logo.svg" width="40" height="40" alt="Flutter Cleaner Logo" style="vertical-align: middle;"> Flutter Cleaner

A modern macOS application built with Flutter for managing and cleaning up project files efficiently.

![Flutter Cleaner Preview](https://is2-ssl.mzstatic.com/image/thumb/PurpleSource221/v4/ce/bf/79/cebf7922-135f-99fb-22c4-54797d90de27/a37bff70-1c63-424f-8715-42ef3ce9dbf9_Amazing_Mockups_533shots.jpeg/0x0ss.png)

## Features

- 🧹 Clean and manage Flutter project dependencies
- 🎨 Modern UI with shadcn_ui components
- 🪟 Native macOS window management
- 🔒 Secure file system access with macOS secure bookmarks
- 📁 Intuitive file management interface
- 🌓 Light theme support

## Tech Stack

- **Framework**: Flutter (SDK >=3.4.4)
- **State Management**: Riverpod with Hooks
- **UI Components**: shadcn_ui
- **Routing**: go_router
- **Code Generation**: 
  - flutter_gen (asset generation)
  - riverpod_generator (state management)
  - freezed (immutable models)
  - json_serializable (JSON serialization)

## Development Setup

### Prerequisites

- Flutter SDK >=3.4.4
- Xcode (for macOS development)
- CocoaPods

### Getting Started

1. Clone the repository:
```bash
git clone https://github.com/xcc3641/flutter_cleaner.git
cd flutter_cleaner
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run code generation:
```bash
flutter pub run build_runner build
```

4. Run the app:
```bash
flutter run -d macos
```

## Project Structure

```
lib/
├── foundation/    # Core utilities and base classes
├── gen/          # Generated code (assets, models)
├── riverpod/     # State management
├── page/         # UI pages
└── main.dart     # Application entry point
```

## Features in Detail

- **Modern UI**: Built with shadcn_ui components for a clean and modern look
- **File Management**: Efficient file system operations with secure access
- **Window Management**: Native macOS window controls and management
- **State Management**: Robust state management using Riverpod with Flutter Hooks

## Contact

- Email: hugo3641@gmail.com
- Twitter: [@Lumosous](https://x.com/Lumosous)

## License

This project is licensed under the MIT License - see the LICENSE file for details. 