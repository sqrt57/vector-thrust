# TypeScript-on-Android runtime options

Type: research
Status: resolved
Blocked by: none

## Question

Which ways of shipping a TypeScript/web-canvas 2D game as an Android app are viable for Vector Thrust, and how do they compare? Candidates include Capacitor (system WebView), Trusted Web Activity/PWA, Tauri 2 mobile, Cordova, and native-canvas runtimes (e.g. React Native + Skia, NativeScript), plus anything current that's better. For each, cover: rendering performance (Canvas2D/WebGL at 60fps on low/mid-tier devices), touch input latency and multitouch (hold thrust + tap target at the same time), fullscreen/portrait lock/safe areas, build + signing pipeline (CLI-driven, headless-friendly), dev loop to a real device (live reload over adb/Wi-Fi), Play Store acceptability, and how well an agent can build and verify it unattended. End with a recommended wrapper.

## Answer

Findings: [research/ts-android-runtimes.md](../research/ts-android-runtimes.md) (also on branch `research/ts-android-runtimes`).

Recommend **Capacitor 8**: its Android project already targets API 36 (required by Play since 2026-08-31), it has built-in fullscreen and safe-area handling, and it builds and signs from the CLI with JDK 17. Live reload to the phone works over USB or wireless adb, and an agent can inspect the WebView via `chrome://inspect`. Capacitor, Cordova and Tauri all share the system WebView, so they render at the same speed and the choice comes down to tooling. Cordova is superseded, and Tauri adds Rust and the NDK for no gain. Fallback: a TWA via Bubblewrap, which needs public HTTPS hosting. React Native + Skia means rewriting rendering and input and requires Vulkan; NativeScript canvas is still in 3.0 beta. Caveats: frame rate on low/mid-tier phones is unbenchmarked (measure it in the device spike), and the manifest must set `android:appCategory="game"`, otherwise API 36 ignores portrait lock on large screens. Multitouch (hold thrust + tap target) works fine with standard touch events.
