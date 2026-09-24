# Saman Mobile

Flutter customer client for the Saman local-commerce platform. It consumes the
same Spring Boot API and PostgreSQL-backed business rules as the Angular web
client. The mobile client does not own product, price, stock, delivery-fee,
payment, or order-state decisions.

## Current slice

- Customer login and registration
- Active shop discovery
- Shop product catalog
- Add to cart
- View and remove cart items
- Memory-only access token (logout on app restart)

Checkout, delivery quote/location permission, secure persistent session,
payment redirect/deep-link handling, order history, and push notifications are
the next mobile slices.

## Local API addresses

- Android emulator: `http://10.0.2.2:8080` (default)
- Flutter web: `http://localhost:8080` (default)
- Physical Android device: pass the development machine's LAN address:

```powershell
flutter run --dart-define=API_BASE_URL=http://192.168.x.x:8080
```

Do not ship a release build that uses plain HTTP. Production must use HTTPS and
an environment-specific `API_BASE_URL`.

## Verification

```powershell
flutter pub get
flutter analyze
flutter test
flutter build web --release --dart-define=API_BASE_URL=http://localhost:8080
flutter build apk --debug --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

The Gradle wrapper uses Gradle's official `downloads.gradle.org` CDN directly.
This avoids the standard `services.gradle.org` redirect to GitHub, which timed
out from Java on the current Windows development machine.
