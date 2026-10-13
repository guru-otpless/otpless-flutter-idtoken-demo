# BigBasket — OTPLESS SNA Demo (Flutter)

A BigBasket-specific build of the OTPLESS Flutter Headless demo, focused on
**Silent Network Authentication (SNA)**:

- Phone number login only (SNA first; OTP fallback if SmartAuth is enabled in the dashboard)
- After verification, the app shows **only the `idToken`** in a read-only field with a **Copy idToken** button
- No SDK event log, no raw response, and no other tokens on screen
- Installs alongside the original demo: Android `com.otpless.bigbasket_sna_demo`, iOS `com.otpless.bigbasketSnaDemo`

Setup is the same as below: `./scripts/configure.sh <BIGBASKET_APP_ID>`, `flutter pub get`, `flutter run`.
For SNA, test on a real device using mobile data with Wi-Fi turned off.

---

# OTPLESS Flutter Headless SDK — Demo App

A reference Flutter app showing how to integrate the **OTPLESS Headless SDK**
([`otpless_headless_flutter`](https://pub.dev/packages/otpless_headless_flutter))
into your own app, using your own UI.

It covers:

- **Phone**: SMS / WhatsApp OTP, Silent Network Authentication (SNA), Magic Link, and SmartAuth fallback
- **Email**: OTP and Magic Link
- **Social / OAuth**: WhatsApp, Google, Apple, Microsoft, GitHub, and more
- **OTP auto-read** (Android) and iOS OTP autofill
- **Resend OTP** with a cooldown
- **Error handling** with user-friendly messages for every documented error code
- **In-app SDK event log** (OTPs and tokens redacted), to watch the callbacks as they arrive

> **SDK:** `otpless_headless_flutter: ^3.0.1` (Android `otpless-headless-sdk 2.0.1`, iOS `OtplessBM/Core 3.0.1`)
> **Built with:** Flutter 3.47 stable / Dart 3.13
> **Official docs:** https://otpless.com/docs/frontend-sdks/app-sdks/flutter/new/headless

---

## Contents

1. [Run the demo](#1-run-the-demo)
2. [How the demo is organised](#2-how-the-demo-is-organised)
3. [Integrate OTPLESS into your app (step by step)](#3-integrate-otpless-into-your-app)
4. [Response types: what to do with each one](#4-response-types)
5. [Error codes](#5-error-codes)
6. [Troubleshooting](#6-troubleshooting)
7. [Security checklist](#7-security-checklist)

---

## 1. Run the demo

### Prerequisites

| | Requirement |
|---|---|
| Flutter | Recent stable (built and tested with 3.47). The Dart code needs Dart 3.8+. On older Flutter versions, copy `lib/` and the native changes into a project created with your Flutter version |
| Android | Android Gradle Plugin 8.9.1+, `compileSdk` 36+, a real device for SNA / OTP auto-read |
| iOS | Xcode 15+, iOS 13+ deployment target, CocoaPods |
| OTPLESS | An App ID from the [OTPLESS dashboard](https://otpless.com/dashboard) with the methods you want to test turned on |

### Steps

```bash
# 1. Set your App ID (writes config for Dart, Android and iOS)
./scripts/configure.sh YOUR_APP_ID

# 2. Install packages
flutter pub get

# 3. Run on a connected device
flutter run
```

If you skip step 1, the app opens a screen that tells you how to set the App ID.

`configure.sh` writes two git-ignored files:

| File | Used by | Purpose |
|---|---|---|
| `config/otpless_config.json` | Dart (`lib/config/otpless_config.dart`), Android Gradle | App ID, plus the Android deep-link scheme `otpless.<appid lowercase>` |
| `ios/Flutter/Otpless.xcconfig` | iOS `Info.plist` | `OTPLESS_APP_ID_LOWERCASE` for the URL scheme `otpless.<appid lowercase>` |

> In your own app you don't need any of this. Hard-code the App ID; it is not a secret.

### Trying each flow

| Flow | How to test |
|---|---|
| SMS / WhatsApp OTP | Phone tab → enter number → enter the OTP you receive |
| Force a channel | Phone tab → pick **SMS** or **WhatsApp** under *Delivery channel* |
| OTP auto-read | Android device with the SIM/WhatsApp for that number. The OTP fills in and verifies by itself |
| Silent Network Auth | Turn on SNA in the dashboard. Use mobile data (Wi-Fi off) on a supported carrier |
| SmartAuth fallback | Turn on SNA → OTP fallback in the dashboard. Test on Wi-Fi, so SNA fails and an OTP is sent |
| Email OTP / Magic Link | Email tab |
| Social login | Social tab. The channel must be enabled in the dashboard |

Tap the **receipt icon** in the app bar to see every request and SDK callback.

---

## 2. How the demo is organised

```
lib/
├── main.dart                     App + AuthShell (shows one page per AuthStep)
├── config/otpless_config.dart    Loads App ID (demo convenience only)
├── otpless/
│   ├── otpless_service.dart      ★ The SDK wrapper: initialize, start, verify, callback
│   ├── otpless_response.dart     Typed model over the raw callback map
│   └── otpless_errors.dart       Error code → user message
├── auth/
│   └── auth_controller.dart      ★ Maps each responseType to UI state
├── screens/
│   ├── login_page.dart           Phone / Email / Social input
│   ├── otp_page.dart             OTP entry, auto-read, resend
│   ├── waiting_page.dart         SNA / Magic Link / OAuth in progress
│   ├── success_page.dart         ONETAP token (send to backend)
│   └── setup_required_page.dart
└── widgets/                      Event log sheet, banners, buttons
```

The two files marked ★ hold the integration logic. Everything else is ordinary
Flutter UI, and you can swap in your own state management (Provider, Riverpod,
Bloc, ...) without changing how the SDK is called.

```
 UI ──► AuthController ──► OtplessService ──► Otpless().start(...)
  ▲            │                                     │
  └── state ◄──┴──────── responses stream ◄── setResponseCallback
```

---

## 3. Integrate OTPLESS into your app

### 3.1 Add the dependency

```yaml
# pubspec.yaml
dependencies:
  otpless_headless_flutter: ^3.0.1
```

### 3.2 Android setup

**a) `MainActivity` must extend `FlutterFragmentActivity`**
([MainActivity.kt](android/app/src/main/kotlin/com/otpless/otpless_flutter_headless_demo/MainActivity.kt))

```kotlin
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity : FlutterFragmentActivity()
```

**b) `AndroidManifest.xml`** ([file](android/app/src/main/AndroidManifest.xml))

```xml
<application
    ...
    android:networkSecurityConfig="@xml/otpless_network_security_config">  <!-- SNA only; file ships inside the SDK -->

    <activity
        android:name=".MainActivity"
        android:exported="true"
        android:launchMode="singleTop"
        ...>

        <!-- Magic Link / OAuth redirect. Replace with your App ID in lowercase. -->
        <intent-filter>
            <action android:name="android.intent.action.VIEW" />
            <category android:name="android.intent.category.DEFAULT" />
            <category android:name="android.intent.category.BROWSABLE" />
            <data android:host="otpless" android:scheme="otpless.YOUR_APP_ID_LOWERCASE" />
        </intent-filter>
    </activity>
</application>
```

**c) Toolchain:** `compileSdk 36+` and Android Gradle Plugin `8.9.1+`.

### 3.3 iOS setup

**a) `Info.plist`** ([file](ios/Runner/Info.plist))

```xml
<!-- Magic Link / OAuth redirect -->
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleTypeRole</key><string>Editor</string>
    <key>CFBundleURLName</key><string>otpless</string>
    <key>CFBundleURLSchemes</key>
    <array><string>otpless.YOUR_APP_ID_LOWERCASE</string></array>
  </dict>
</array>

<key>LSApplicationQueriesSchemes</key>
<array>
  <string>whatsapp</string>
  <string>otpless</string>
  <string>gootpless</string>
  <string>com.otpless.ios.app.otpless</string>
  <string>googlegmail</string>
</array>

<!-- SNA only: carrier endpoints -->
<key>NSAppTransportSecurity</key>
<dict>
  <key>NSExceptionDomains</key>
  <dict>
    <key>80.in.safr.sekuramobile.com</key>
    <dict><key>NSExceptionAllowsInsecureHTTPLoads</key><true/><key>NSIncludesSubdomains</key><true/></dict>
    <key>api-csp.airtel.in</key>
    <dict><key>NSExceptionAllowsInsecureHTTPLoads</key><true/><key>NSIncludesSubdomains</key><true/></dict>
    <key>in-vil.ipification.com</key>
    <dict><key>NSExceptionAllowsInsecureHTTPLoads</key><true/><key>NSIncludesSubdomains</key><true/></dict>
    <key>partnerapi.jio.com</key>
    <dict><key>NSExceptionAllowsInsecureHTTPLoads</key><true/><key>NSIncludesSubdomains</key><true/></dict>
  </dict>
</dict>
```

**b) Pass redirects back to the SDK.** Pick the variant that matches your app.

If your app uses a `SceneDelegate` (the default for new Flutter projects), see
[SceneDelegate.swift](ios/Runner/SceneDelegate.swift):

```swift
import Flutter
import OtplessBM
import UIKit

class SceneDelegate: FlutterSceneDelegate {
  override func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    for context in URLContexts where Otpless.shared.isOtplessDeeplink(url: context.url) {
      Task(priority: .userInitiated) { await Otpless.shared.handleDeeplink(context.url) }
    }
    super.scene(scene, openURLContexts: URLContexts)
  }
}
```

If your app has only an `AppDelegate`:

```swift
import OtplessBM

override func application(_ app: UIApplication, open url: URL,
                          options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
  if Otpless.shared.isOtplessDeeplink(url: url) {
    Task(priority: .userInitiated) { await Otpless.shared.handleDeeplink(url) }
    return true
  }
  return super.application(app, open: url, options: options)
}
```

**c)** Run `cd ios && pod install` (or just `flutter run`, which does it for you).

### 3.4 Initialize once and listen for responses

See [otpless_service.dart](lib/otpless/otpless_service.dart).

```dart
import 'package:otpless_headless_flutter/otpless_flutter.dart';

// Create ONE instance for the whole app. Each Otpless() registers its own
// native handler, so only the most recently created instance gets callbacks.
final otpless = Otpless();

Future<void> initOtpless() async {
  await otpless.setDevLogging(kDebugMode);              // optional
  await otpless.setResponseCallback(onOtplessResponse); // before initialize
  await otpless.initialize('YOUR_APP_ID');
}

void onOtplessResponse(dynamic result) {
  otpless.commitResponse(result);   // always acknowledge first
  switch (result['responseType']) {
    case 'SDK_READY':          /* ready to start */ break;
    case 'INITIATE':           /* OTP sent / SNA started, or error */ break;
    case 'OTP_AUTO_READ':      /* Android: fill + verify */ break;
    case 'VERIFY':             /* verification FAILED */ break;
    case 'ONETAP':             /* SUCCESS: send token to backend */ break;
    case 'FALLBACK_TRIGGERED': /* moved to next channel */ break;
    case 'DELIVERY_STATUS':    /* delivered on channel */ break;
    case 'FAILED':             /* SDK-level failure */ break;
    case 'AUTH_TERMINATED':    /* flow ended without success */ break;
  }
}
```

The demo calls `initialize` from the first screen's `initState`, as the
official docs do.

### 3.5 Start authentication

```dart
// Phone. countryCode has no "+".
otpless.start(onOtplessResponse, {'phone': '9876543210', 'countryCode': '91'});

// Optional: force a channel instead of the dashboard order
otpless.start(onOtplessResponse, {
  'phone': '9876543210', 'countryCode': '91', 'deliveryChannel': 'WHATSAPP',
});

// Email
otpless.start(onOtplessResponse, {'email': 'user@example.com'});

// OAuth / social
otpless.start(onOtplessResponse, {'channelType': 'WHATSAPP'});
```

Supported `channelType` values: `WHATSAPP`, `APPLE`, `GMAIL`, `TWITTER`, `DISCORD`,
`SLACK`, `FACEBOOK`, `LINKEDIN`, `MICROSOFT`, `LINE`, `LINEAR`, `NOTION`, `TWITCH`,
`GITHUB`, `BITBUCKET`, `ATLASSIAN`, `GITLAB`.

Other optional request keys: `otpLength` (`"4"` / `"6"`), `expiry` (seconds),
`tid` (template id), `extras` (`Map<String, String>`).

> ⚠️ **Pass every value as a `String`.** The iOS bridge reads them with `as? String`,
> so `'countryCode': 91` or `'otpLength': 6` is silently ignored on iOS.

Check `await otpless.isSdkReady()` before calling `start`. The demo shows
"Sign-in is still initializing" if it isn't ready yet.

### 3.6 Verify the OTP

Verification uses the same `start` call with the same identity plus `otp`:

```dart
otpless.start(onOtplessResponse, {'phone': '9876543210', 'countryCode': '91', 'otp': '123456'});
otpless.start(onOtplessResponse, {'email': 'user@example.com', 'otp': '123456'});
```

To resend, call `start` again **without** `otp`.

### 3.7 Validate the token on your backend

When you receive `ONETAP`, send `response.token` to **your server** and
validate it with the OTPLESS server-side token validation API, using your
Client ID / Client Secret. Create the user session only after that succeeds.
Never put the Client Secret in the app.

---

## 4. Response types

All callbacks look like `{ responseType, statusCode, response: {...} }`.
[`AuthController._onResponse`](lib/auth/auth_controller.dart) is a full,
working example of handling each one.

| `responseType` | When | What your UI should do |
|---|---|---|
| `SDK_READY` | `initialize` finished | Enable the login button |
| `FAILED` | SDK could not initialize (`5003`) or SSL pinning failed (`5004`) | Show an error; retry `initialize` |
| `INITIATE` (200) | Request accepted. Check `response.authType` | `OTP` → OTP screen · `OTP_LINK` → OTP screen (link also works) · `MAGICLINK` → "check your inbox" · `SILENT_AUTH` → loader |
| `INITIATE` (≠200) | Request rejected | Show `errorCode` message, stay on the input screen |
| `OTP_AUTO_READ` | Android read the OTP from SMS / WhatsApp | Fill the field and verify |
| `DELIVERY_STATUS` | OTP / link delivered | Optional: "Delivered via WhatsApp" |
| `FALLBACK_TRIGGERED` | Primary channel failed, SmartAuth retried | Update "sent via …" (e.g. SNA → SMS OTP: show the OTP screen) |
| `VERIFY` | Verification **failed** | Wrong / expired OTP → show error. `SILENT_AUTH` + `9106` → every method failed, restart. `SILENT_AUTH` otherwise → wait for the next `INITIATE` |
| `ONETAP` | **Success** | Read `response.token` (or `response.data.token`) → send to backend |
| `AUTH_TERMINATED` | Flow ended without success | Return to the login screen |

---

## 5. Error codes

Mapped in [otpless_errors.dart](lib/otpless/otpless_errors.dart).

| Code | Meaning |
|---|---|
| 7101 | Invalid parameters |
| 7102 | Invalid phone number |
| 7103 | Invalid delivery channel for phone |
| 7104 | Invalid email |
| 7105 | Invalid delivery channel for email |
| 7106 | Invalid phone or email |
| 7113 | Invalid expiry |
| 7116 | OTP length must be 4 or 6 |
| 7121 | Invalid app hash |
| 4000 / 4001 / 4003 | Invalid request / 2FA not supported / channel not enabled |
| 401 / 7025 | Unauthorized / country not enabled |
| 7020 / 7022 / 7023 / 7024 | Rate limited |
| 7112 | Empty OTP |
| 7115 | OTP already verified |
| 7118 | Incorrect OTP |
| 7303 | OTP expired |
| 9106 | Silent Auth and all fallbacks failed |
| 9100–9105 | Network errors (9101, 9102, 9105 iOS only) |
| 9110 | Request cancelled (iOS) |
| 5900 | Needs a newer iOS version (iOS) |
| 5003 | SDK initialization failed |
| 5004 | SSL pin validation failed (only with `sslPinning: OtplessSslPinning.enabled`) |

---

## 6. Troubleshooting

| Symptom | Fix |
|---|---|
| No callbacks at all | Make sure there is **one** `Otpless()` instance app-wide, and `setResponseCallback` runs before `initialize` |
| `FAILED` 5003 on launch | Wrong App ID, or no network |
| `INITIATE` 401 / 4003 | Method or channel not enabled in the dashboard for this App ID |
| Android crash: activity is not a FragmentActivity | `MainActivity` must extend `FlutterFragmentActivity` |
| Android build: compileSdk / AGP error | Use `compileSdk 36+` and AGP `8.9.1+` |
| Magic Link / OAuth opens the browser but never returns | Deep-link scheme must be `otpless.<appid in lowercase>` (Android intent filter + iOS `CFBundleURLSchemes`); on iOS also forward the URL in `SceneDelegate` / `AppDelegate` |
| iOS ignores `countryCode` / `otpLength` | Pass them as `String`s |
| SNA always falls back | Turn Wi-Fi off, use mobile data, check the carrier is supported, and keep the network security config / ATS exceptions |
| `FAILED` 5004 | SSL pinning is on and a proxy (Charles, Proxyman) is intercepting traffic |
| App shows "Add your OTPLESS App ID" | Run `./scripts/configure.sh YOUR_APP_ID`, then fully restart the app |

---

## 7. Security checklist

- [ ] Validate the `ONETAP` token **on your backend** before trusting the user
- [ ] Never ship your OTPLESS Client Secret in the app
- [ ] Turn off `setDevLogging` in release builds (the demo enables it only in debug)
- [ ] Remove the in-app event log from production builds
- [ ] Consider `initialize(appId, sslPinning: OtplessSslPinning.enabled)` for production
