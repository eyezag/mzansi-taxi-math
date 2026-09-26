# Mzansi Taxi Math

Fare and change calculator for the front-seat passenger in a minibus taxi. It works fully offline, with no accounts and no backend.

```
flutter pub get
flutter run
flutter test
```

- All trip state lives in memory (`lib/src/trip_controller.dart`).
- Fare tiers are the only thing persisted (`shared_preferences`).
- Layout: `fare_bar.dart` (pinned fares), `payment_card.dart` (one card per cash handover), `totals_bar.dart` (collapsible totals), `home_screen.dart`.
