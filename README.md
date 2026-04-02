# BrushAndCoinMobile

Simple Flutter foundation app for the Brush&Coin capstone project. It focuses on artists, portfolios, secure commission projects, escrow-style milestones, client messaging, and payment methods (GCash, PayMaya, PayPal, Stripe).

## Running the app with separate API backend

1. Start the standalone API server (outside Flutter app):

```bash
cd ../BrushAndCoinApi
npm install
npm start
```

2. Install Flutter and set up an Android emulator or physical device.
3. From the mobile project directory, install dependencies:

```bash
flutter pub get
```

4. Run the app on your device or emulator:

```bash
flutter run
```

If you need a different backend URL, pass it at run time:

```bash
flutter run --dart-define=API_BASE_URL=http://localhost:4000
```
'''phone
flutter run --dart-define=API_BASE_URL=http://192.168.1.54:4000
'''

The home screen shows a simple dashboard, and you can navigate between `Home`, `Artists`, `Projects`, `Messages`, and `Profile` using the bottom navigation bar. Each tab is just a starter UI that you can extend with real data, geo-location, chat, contracts, and payment integrations.
