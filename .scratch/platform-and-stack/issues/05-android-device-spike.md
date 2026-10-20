# Real-device spike: web build on Android vs. Godot APK

Type: prototype
Status: resolved
Blocked by: 01, 03

## Question

Does a minimal web build feel good enough on your actual Android phone to commit to TypeScript? Build a throwaway: gravity + thrust button (hold) + tap-to-target navigator, using the current tuned values, wrapped with the wrapper recommended in [TypeScript-on-Android runtime options](01-ts-android-runtimes.md) and the renderer recommended in [Web renderer / game library choice](03-web-renderer-library.md). Install it, then compare against the existing Godot APK side by side on frame smoothness, touch latency on the thrust button, simultaneous hold-thrust + tap-target, portrait/fullscreen/letterboxing, and how long the edit → on-device cycle takes. Measure frame times on the phone for both Pixi WebGL and raw Canvas2D, since that can flip the renderer choice (no primary-source fps benchmarks exist for WebView wrappers), and set `android:appCategory="game"` in the manifest so portrait lock holds. Your verdict on feel is the answer.

## Answer

Prototype: branch `prototype/android-device-spike`, directory `prototype-android-spike/` (Capacitor 8.5.3, PixiJS 8.22, Vite). Tested on a Redmi Note 13 Pro (HyperOS, Android 16, WebView 155, 120 Hz panel).

**Verdict (user): TypeScript is good enough.** All three renderers (Pixi WebGL, Pixi Canvas, raw Canvas2D) feel the same as each other and as the Godot APK on smoothness, thrust-button response, and hold-thrust + tap-target.

Measured on the phone (fixed 60 Hz sim; the WebView ran at 60 Hz on the 120 Hz panel). Load = extra drifting hexagon outlines:

| Renderer | CPU/frame at load 0 / 200 / 1000 / 3000 | Frame rate |
|---|---|---|
| Pixi WebGL | 0.3 / 1.3 / 3.3 / 8.1 ms | 60 fps at every load, no long frames |
| raw Canvas2D | 0.4 / 1.7 / 2.5 / 6.8 ms | 60 fps up to 1000, ~30 fps at 3000 (GPU-bound) |
| Pixi Canvas | 0.8 / 3.4 / 9.0 / 22.6 ms | 60 fps up to 1000, ~36 fps at 3000 |

Frame-time numbers don't flip the renderer choice at game-like loads. Only Pixi WebGL has headroom past 1000 shapes.

Edit → on-device cycle: with live reload, a saved source file is reloaded and drawing on the phone in ~0.65 s. A native rebuild + install + launch takes ~10 s. The Godot loop couldn't be timed: the headless `--export-debug Android` failed with "configuration errors", and the Godot APK on the phone predated M3 (no target marker). The user judged the comparison sufficient without fixing it.

Found along the way, for later tickets:
- Capacitor 8 needs **JDK 21+**, not 17 as the runtime research said. Android Studio's bundled JBR (25) works.
- Netskope TLS inspection breaks Gradle downloads. Fix: a truststore copied from JBR's `cacerts` plus the Netskope root (see the prototype README).
- `npx cap run android` fails on Windows (`'gradlew' is not recognized`: the CLI spawns `./gradlew`). Workaround: write `server.url` into `android/app/src/main/assets/capacitor.config.json`, `adb reverse tcp:5173 tcp:5173`, `gradlew.bat assembleDebug`, `adb install -r`.
- The Capacitor template's splash theme falls back to an ActionBar theme. Set `AppTheme.NoActionBar` on `<application>`.
- `SystemBars.hide()` / `hidden: true` didn't hide the bars. Hiding them natively in `MainActivity.onWindowFocusChanged` via `WindowInsetsControllerCompat` (swipe to reveal) worked.
- HyperOS blocks `adb install` (`INSTALL_FAILED_USER_RESTRICTED`) after a denied prompt, until the Security app's data is cleared.
- Screenshots show a white "VT…" strip and a 264 px top inset on this device that isn't part of the app's view tree. Not investigated.
- A Godot headless run imports every folder in the repo. Non-Godot directories need a `.gdignore`.
