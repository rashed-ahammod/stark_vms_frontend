# Stark Group VMS (Frontend)

Flutter Web admin frontend for the **Stark Group Vehicle Management System (VMS)**, built with `shadcn_ui`, `flutter_riverpod`, `retrofit` + `dio`, `json_serializable`, `skeletonizer`, and `infinite_scroll_pagination`.

## Prerequisites

- Flutter SDK (`^3.13.4` Dart SDK)
- Chrome (for `flutter run -d chrome`)
- Running **Stark Group VMS** Spring Boot backend (`/Users/chayan/Documents/stark-vms-backend`)

## Running the App

1. Install dependencies:
   ```bash
   flutter pub get
   ```

2. Run on Chrome:
   ```bash
   flutter run -d chrome
   ```

## Changing the API Base URL

Edit `baseUrl` in [`lib/config/api_config.dart`](lib/config/api_config.dart):

```dart
static const String baseUrl = 'http://localhost:9001/api';
```

> Note: `http://localhost:9001/api` matches `server.port=9001` in the backend's `application.properties`. Update this value if your backend runs on a different port (e.g., `8080`).

## Regenerating Code

After modifying any `@JsonSerializable` model or `@RestApi` Retrofit interface, regenerate `.g.dart` files with:

```bash
dart run build_runner build --delete-conflicting-outputs
```
