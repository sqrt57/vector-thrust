# Real-device spike: web build on Android vs. Godot APK

Type: prototype
Status: open
Blocked by: 01, 03

## Question

Does a minimal web build feel good enough on your actual Android phone to commit to TypeScript? Build a throwaway: gravity + thrust button (hold) + tap-to-target navigator, using the current tuned values, wrapped with the wrapper recommended in [TypeScript-on-Android runtime options](01-ts-android-runtimes.md) and the renderer recommended in [Web renderer / game library choice](03-web-renderer-library.md). Install it, then compare against the existing Godot APK side by side on frame smoothness, touch latency on the thrust button, simultaneous hold-thrust + tap-target, portrait/fullscreen/letterboxing, and how long the edit → on-device cycle takes. Measure frame times on the phone for both Pixi WebGL and raw Canvas2D, since that can flip the renderer choice (no primary-source fps benchmarks exist for WebView wrappers), and set `android:appCategory="game"` in the manifest so portrait lock holds. Your verdict on feel is the answer.
