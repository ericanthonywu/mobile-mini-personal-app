# expense_tracker

Expense Tracker Mobile Application (Flutter).

## Environment Setup

The mobile app relies on environment variables defined in `.env.json` for API configuration:

```json
{
  "BASE_URL": "http://srv1743851.hstgr.cloud:9090/api"
}
```

## Running the Application

Always include `--dart-define-from-file=.env.json` when running or building the application so that `BASE_URL` is properly passed to the app and WidgetKit extension.

### Debug Mode
```bash
flutter run --dart-define-from-file=.env.json
```

### Release Mode (Physical iOS Device)
```bash
flutter run -d <device_id> --release --dart-define-from-file=.env.json
```

### Build iOS Release Bundle
```bash
flutter build ios --release --dart-define-from-file=.env.json
```

