# Shipping a TypeScript / web-canvas 2D game as an Android app

Research date: 2026-10-19. Question: which wrappers can ship Vector Thrust (portrait, 2D, gravity/thrust, currently Godot 4.7) to Android if it moves to TypeScript, and how do they compare? Dev machine: Windows 11, JDK 17, Android SDK via Android Studio, adb, one real phone.

Sources are linked inline. Where no primary source settles a point (mostly frame rate and touch latency on specific devices), the text says so and marks the statement as an **assessment**.

## TL;DR

**Recommendation: Capacitor 8 (system WebView), using Canvas2D or WebGL directly, or a small renderer such as PixiJS.** It is the only option that meets all of these at once:

- current Play target API (36) out of the box
- a pure-CLI build, signing, and run pipeline that works with JDK 17
- built-in live reload with `adb reverse` port forwarding
- first-party edge-to-edge and safe-area handling
- a renderer that is plain Chromium, so an agent can drive and inspect it through `chrome://inspect` / CDP

Fallbacks:

- **TWA (Bubblewrap):** the lightest option if we are happy to host the game on the web.
- **Tauri 2:** viable, but adds a Rust/NDK toolchain and gives no rendering gain.

React Native + Skia and NativeScript Canvas would mean rewriting the rendering and input layers or betting on a beta, which Vector Thrust doesn't need.

## Constraints that apply to every option

- **Play target API.** New apps and updates must target Android 16 (API 36) from 2026-08-31, with extensions available to 2026-11-01 ([Play target API policy](https://support.google.com/googleplay/android-developer/answer/11926878)).
- **Edge-to-edge is mandatory.** For apps targeting API 36, `windowOptOutEdgeToEdgeEnforcement` "is deprecated and disabled, and your app can't opt-out of going edge-to-edge" ([Android 16 behavior changes](https://developer.android.com/about/versions/16/behavior-changes-16)). Every wrapper therefore has to deliver correct insets to the game, and the game has to keep HUD and controls out of the system bars.
- **Portrait lock is ignored on large screens.** For apps targeting API 36, `screenOrientation`, `setRequestedOrientation()` and aspect-ratio limits no longer apply on displays with smallest width >= 600dp. **Games are exempt, based on `android:appCategory`.** There is also a temporary opt-out property, `PROPERTY_COMPAT_ALLOW_RESTRICTED_RESIZABILITY`, which stops working at API 37 ([Android 16 behavior changes](https://developer.android.com/about/versions/16/behavior-changes-16)). Phones (< sw600dp) are unaffected. Whatever wrapper we pick, set `android:appCategory="game"` in the manifest.
- **WebView engine.** On Android 7–9 the WebView is built into Chrome. On Android 10+ WebView and Chrome are separate apps that share most of their code. New versions ship every 6 weeks ([Chromium WebView FAQ](https://chromium.googlesource.com/chromium/src/+/HEAD/android_webview/docs/faq.md)). The WebView-based wrappers (Capacitor, Cordova, Tauri) all render with the same Chromium engine, so their Canvas/WebGL performance should be essentially the same. The wrapper choice affects tooling and native integration, not drawing speed. (**Assessment**, based on the shared engine. No source benchmarks the wrappers against each other.)
- **Touch input in Chromium.** This applies to every web-based option, including TWA:
  - Since Chrome 60, continuous events (`touchmove`, `pointermove`) are aligned to the frame and dispatched just before `requestAnimationFrame`.
  - Discrete events such as `touchstart`/`touchend` are dispatched immediately.
  - Since Chrome 58, `getCoalescedEvents()` recovers the intermediate samples.

  ([Chrome: Aligned input events](https://developer.chrome.com/blog/aligning-input-events).) For Vector Thrust this is a good fit: thrust-hold starts and stops on a discrete event, and target taps are discrete too, so neither waits for a frame.
- **Multitouch on a canvas.** Put `touch-action: none` on the game canvas. Without it, the browser's pan/zoom handling fires `pointercancel` and takes over the gesture ([MDN touch-action](https://developer.mozilla.org/en-US/docs/Web/CSS/touch-action)). Then track each finger by `pointerId`. Holding thrust with one finger while tapping a target with another is then ordinary Pointer Events code.
- **Local content.** Android recommends `WebViewAssetLoader` (an https origin) over `file://`, because `file://` is an opaque origin that can't use `fetch()` ([Load local content](https://developer.android.com/develop/ui/views/layout/webapps/load-local-content)). Capacitor and Tauri already serve the bundle from a virtual https/custom origin. A hand-rolled WebView shell would have to do this itself.
- **Inspecting a WebView from the desktop.** Any WebView app that calls `setWebContentsDebuggingEnabled` shows up in `chrome://inspect` ([Chrome: Remote debugging WebViews](https://developer.chrome.com/docs/devtools/remote-debugging/webviews)). This is the main way an agent can verify an app it built: read console logs, run JS, take screenshots via DevTools.

### Frame rate on low/mid-tier devices: what is and isn't known

I found no primary source that benchmarks Canvas2D/WebGL at 60 fps in these wrappers on low- or mid-tier phones.

**Assessment:** a vector-style game with a handful of ships, particles and line art is well inside what Chromium's GPU-accelerated canvas handles. The risks to watch are GC pauses from allocating every frame, and overdraw from full-screen alpha effects. Use WebGL (directly or through PixiJS) if Canvas2D profiling shows the raster step is the bottleneck. The first spike should measure frame times on the real phone through `chrome://inspect`, not assume them.

## Comparison

| | Capacitor 8 | TWA (Bubblewrap) | Tauri 2 mobile | Cordova (cordova-android 15) | React Native + Skia v3 | NativeScript + @nativescript/canvas |
|---|---|---|---|---|---|---|
| Renderer | System WebView (Chromium) | User's Chrome (Custom Tabs protocol) | System WebView (Chromium) | System WebView (Chromium) | Skia Graphite on Vulkan, own API | Rust Skia/WGPU behind an HTML-Canvas-like API |
| Reuses browser Canvas/WebGL game code | Yes | Yes | Yes | Yes | No (Skia API, React tree) | Mostly (Canvas 2D/WebGL-like API) |
| Target API in template | 36 | 36 | 37 | supports up to 36 | set by RN app | set by NS app |
| Fullscreen / portrait | SystemBars plugin + ScreenOrientation plugin | `display: fullscreen-sticky`, `orientation: portrait` in twa-manifest | Hand-edit manifest / Kotlin | Config/plugins | Native | Native |
| CLI build + sign | `npx cap build android --keystorepath ... --androidreleasetype AAB` | `bubblewrap build` (env-var passwords) | `tauri android build --aab --ci` + Gradle signing edit | `cordova build android --release -- --keystore ...` | `npx react-native build-android --mode=release` | `ns build android --release --key-store-* --aab` |
| Live reload to device | `cap run android -l --forwardPorts` | Not needed: it's a website (deploy and reload) | `tauri android dev --host` | No first-party live reload in the docs I read | Metro fast refresh | `ns run android` (HMR) |
| Extra toolchain on our machine | Node 22, Android Studio 2025.2.1+ | Node 18+, JDK 17 | Rust + 4 Android targets, NDK, `NDK_HOME` | Node, JDK 17 | RN 0.79+, NDK | NS CLI |
| Maturity (latest stable) | 8.5.3, 2026-10-07 | 1.27.0, 2026-10-09 | tauri 2.12.4, 2026-10-14 | 15.1.0, 2026-07-22 | 3.7.1, 2026-10-19 | canvas 2.1.18, 2026-08-15 (3.0 in beta) |

Release dates come from each project's GitHub releases: [Capacitor](https://github.com/ionic-team/capacitor/releases), [Bubblewrap](https://github.com/GoogleChromeLabs/bubblewrap/releases), [Tauri](https://github.com/tauri-apps/tauri/releases), [cordova-android](https://github.com/apache/cordova-android/releases), [react-native-skia](https://github.com/wcandillon/react-native-skia/releases), [NativeScript canvas](https://github.com/NativeScript/canvas/releases).

## Per option

### 1. Capacitor 8 (system WebView) — recommended

- **Platform support.** Android 7 / API 24+ with WebView Chrome 60+. Uses Chrome's WebView on Android 7–9 and Android System WebView on 10+ ([Capacitor Android docs](https://capacitorjs.com/docs/android)). The 8.5.3 template sets `compileSdkVersion = 36` and `targetSdkVersion = 36` ([variables.gradle@8.5.3](https://github.com/ionic-team/capacitor/blob/8.5.3/android-template/variables.gradle)), so it meets the Play deadline as generated. It uses AGP 8.13.0 and Gradle 8.14.3 ([template build.gradle](https://github.com/ionic-team/capacitor/blob/8.5.3/android-template/build.gradle)).
- **Environment.** Node 22+ and Android Studio 2025.2.1+. Android Studio provides the JDK ([environment setup](https://capacitorjs.com/docs/getting-started/environment-setup)). The current AGP 9.4 needs JDK 17 ([AGP release notes](https://developer.android.com/build/releases/gradle-plugin)), so our JDK 17 fits.
- **Rendering.** Plain Chromium WebView, with no difference from Chrome's canvas (see "Constraints").
- **Input.** Standard Pointer Events. Capacitor adds no layer between touch events and the page that I could find documented.
- **Fullscreen and safe areas.**
  - The SystemBars plugin ships in `@capacitor/core` and is aimed at edge-to-edge apps.
  - `insetsHandling` options:
    - `native` pads the WebView.
    - `css` does the same and also injects `--safe-area-inset-*` variables, because older Android WebViews (below Chromium 140) don't report correct `env(safe-area-inset-*)` values.
    - `disable` hands inset handling to the app.
  - `hide()` and `show()` work on the status and navigation bars.
  - On Android you call `EdgeToEdge.enable(this)` in `BridgeActivity.onCreate`. Capacitor 9 will do this automatically.

  ([SystemBars](https://capacitorjs.com/docs/apis/system-bars).)
- **Portrait lock.** `ScreenOrientation.lock({ orientation: 'portrait' })`. The docs note that on API 36 it does nothing on tablets running Android 16 unless you use the temporary opt-out ([Screen Orientation](https://capacitorjs.com/docs/apis/screen-orientation)). Setting `appCategory="game"` avoids that (see "Constraints").
- **Build and sign (headless).** `npx cap build android` takes `--keystorepath`, `--keystorepass`, `--keystorealias`, `--keystorealiaspass`, `--androidreleasetype AAB|APK` and `--signing-type jarsigner|apksigner` ([cap build](https://capacitorjs.com/docs/cli/commands/build)). The same values can live in `android.buildOptions` in `capacitor.config` ([config](https://capacitorjs.com/docs/config)). The generated `android/` folder is ordinary Gradle, so `gradlew bundleRelease` also works.
- **Dev loop.**
  - `npx cap run android --target <id> --live-reload --host <ip> --port <port>` builds, deploys and points the WebView at the dev server.
  - `--forwardPorts 5173:5173` runs `adb reverse` for you ([cap run](https://capacitorjs.com/docs/cli/commands/run)), so USB or `adb` over Wi-Fi works without the phone needing to reach the PC over the LAN.
  - The LAN alternative needs the server bound to `0.0.0.0` and `server.url` + `cleartext` ([Live reload guide](https://capacitorjs.com/docs/guides/live-reload)). The docs say `server.url` "is not intended for use in production" ([config](https://capacitorjs.com/docs/config)).
  - Wireless adb on Android 11+ is `adb pair ip:port` once, after which the device works like a USB connection ([adb docs](https://developer.android.com/tools/adb)).
- **Play Store.** The output is an ordinary native AAB with assets bundled locally, and no special review path is involved. Watch the Play "minimum functionality" rule against static content apps ([Play policy](https://support.google.com/googleplay/android-developer/answer/9898783)). A game isn't static content, so this doesn't apply to us.
- **Agent fit: best of the set.** Each step is a CLI call with flags: `cap sync`, `cap run --target`, `cap build` with keystore flags. `--list` enumerates devices. Debug builds enable `webContentsDebuggingEnabled` automatically ([config](https://capacitorjs.com/docs/config)), so the agent can attach over `adb forward` to DevTools, read console output, run JS and take screenshots. A browser build of the same code can also be tested headlessly in Playwright before touching the device. (The Playwright step is an **assessment**.)

### 2. Trusted Web Activity / PWA via Bubblewrap — viable fallback

- **What it is.** A TWA opens our PWA fullscreen in the user's browser using a protocol based on Custom Tabs. It requires Chrome 72+ and Digital Asset Links proving that the app and the site belong to the same developer. The site is expected to meet the Add-to-Home-Screen criteria. The host app can't reach web storage. If the browser doesn't support TWAs, it falls back to a Custom Tab with a toolbar ([TWA overview](https://developer.chrome.com/docs/android/trusted-web-activity/overview)).
- **Rendering and input.** Content is rendered "the same way it appears in a normal browser" ([TWA overview](https://developer.chrome.com/docs/android/trusted-web-activity/overview)), i.e. by full Chrome, not WebView. Performance and input are therefore at least as good as Capacitor's. It does depend on the user's default browser actually supporting TWAs.
- **Fullscreen and portrait.** `twa-manifest.json` has `display: fullscreen | fullscreen-sticky` ("corresponds to Android's Immersive Sticky") and `orientation: portrait` ([Bubblewrap CLI README](https://github.com/GoogleChromeLabs/bubblewrap/tree/main/packages/cli)).
- **Build and sign.** `bubblewrap init --manifest <url>`, then `bubblewrap build` produces a signed APK and AAB. In CI, passwords come from `BUBBLEWRAP_KEYSTORE_PASSWORD` / `BUBBLEWRAP_KEY_PASSWORD`. `bubblewrap fingerprint generateAssetLinks` writes `assetlinks.json`, and `bubblewrap install` pushes to a device. **JDK 17 is required exactly**: lower versions won't compile and higher ones clash with the command-line tools ([Bubblewrap CLI README](https://github.com/GoogleChromeLabs/bubblewrap/tree/main/packages/cli)). The template targets SDK 36 ([template build.gradle](https://github.com/GoogleChromeLabs/bubblewrap/blob/main/packages/core/template_project/app/build.gradle)). The latest release is v1.27.0 (2026-10-09) and bumps android-browser-helper to 2.7.4 ([release notes](https://github.com/GoogleChromeLabs/bubblewrap/releases/tag/v1.27.0)).
- **Costs.**
  - We must host the game on HTTPS at a domain we control.
  - Offline play depends on a service worker, which doesn't exist on first launch. An offline first launch shows a network error unless we add a custom native launcher ([Offline-first TWAs](https://developer.chrome.com/docs/android/trusted-web-activity/offline-first)).
  - android-browser-helper's `QualityEnforcer` deliberately crashes the host app when the provider reports a quality-criteria violation, such as a failed verified-origin navigation ([android-browser-helper README](https://github.com/GoogleChrome/android-browser-helper)).
- **Dev loop.** We iterate on the website in desktop and mobile Chrome. The APK changes rarely.
- **Agent fit: good.** The pipeline is CLI-driven. Verification happens mostly in the browser, and Chrome on the phone can be inspected through `chrome://inspect`. Asset Links and hosting add an online step the agent can't fully own.

### 3. Tauri 2 mobile — viable, no advantage here

- **Rendering.** Uses the system Android WebView and bundles no engine ([webview versions](https://v2.tauri.app/reference/webview-versions/)), so rendering and input match Capacitor's.
- **Toolchain.** Android support adds Rust, the NDK (with `NDK_HOME` set) and four rustup Android targets ([prerequisites](https://v2.tauri.app/start/prerequisites/)). The template targets compile and target SDK 37 ([template build.gradle.kts @ tauri-cli v2.12.3](https://github.com/tauri-apps/tauri/blob/tauri-cli-v2.12.3/crates/tauri-cli/templates/mobile/android/app/build.gradle.kts)). The generated manifest sets no orientation or app category ([template AndroidManifest](https://github.com/tauri-apps/tauri/blob/tauri-cli-v2.12.3/crates/tauri-cli/templates/mobile/android/app/src/main/AndroidManifest.xml)), so portrait lock, `appCategory` and immersive mode are manual edits.
- **CLI.**
  - `tauri android dev` has `--host` (sets `TAURI_DEV_HOST`), `--port` and `--open`.
  - `tauri android build` has `--aab`, `--apk`, `--target`, `--split-per-abi` and `--ci` (no prompts).

  ([Tauri CLI reference](https://v2.tauri.app/reference/cli/).)
- **Signing.** Requires hand-editing the generated `build.gradle.kts` and providing a `keystore.properties` ([Android signing](https://v2.tauri.app/distribute/sign/android/)).
- **Dev loop docs.** The docs cover physical devices only partly. The host-binding example is written for iOS, and Android Wi-Fi vs USB isn't covered ([Develop](https://v2.tauri.app/develop/)).
- **Maturity.** Stable 2.12.4 (2026-10-14). A 3.0 alpha line is in progress ([releases](https://github.com/tauri-apps/tauri/releases)).
- **Verdict.** Same renderer as Capacitor with a heavier toolchain. Worth it only if we wanted a Rust core, which we don't.

### 4. Cordova (cordova-android 15) — works, but superseded

- **Support and builds.**
  - cordova-android 15.0.x supports API 24–36 and needs JDK 17.
  - `cordova build android --release -- --keystore ... --storePassword ... --alias ... --password ...` plus `--packageType=bundle` gives a signed AAB.
  - Signing can also come from `build.json` or Gradle properties files.

  ([Cordova Android guide](https://cordova.apache.org/docs/en/latest/guide/platforms/android/).)
- **Maturity.** Latest release 15.1.0 (2026-07-22) ([releases](https://github.com/apache/cordova-android/releases)).
- **Gaps.** The guide documents no live-reload workflow. Rendering is the same system WebView. Capacitor already runs Cordova plugins: its 8.5.3 template pins `cordovaAndroidVersion = '14.0.1'` for compatibility ([variables.gradle](https://github.com/ionic-team/capacitor/blob/8.5.3/android-template/variables.gradle)). Choosing Cordova directly gains nothing.

### 5. React Native + Skia — not recommended for this game

- **Repository has moved.** `Shopify/react-native-skia` now redirects to [wcandillon/react-native-skia](https://github.com/wcandillon/react-native-skia), and the npm package for v3 is `react-native-skia`.
- **Rendering.** v3 renders with Skia Graphite on Vulkan (multi-threaded). v2 stays on Ganesh/OpenGL and is still maintained ([README](https://github.com/wcandillon/react-native-skia)).
- **Requirements.** RN 0.79+ with the New Architecture and React 19, `minSdkVersion` 26, and the NDK. The library's manifest marks Vulkan 1.1 as required, so Play won't serve the app to devices without Vulkan. Supporting those devices means switching to v2 ([installation](https://wcandillon.github.io/react-native-skia/docs/getting-started/installation/)).
- **Build.** `npx react-native build-android --mode=release` with Gradle signing properties ([RN signed APK](https://reactnative.dev/docs/signed-apk-android)).
- **Verdict.** The drawing API is Skia/React, not Canvas2D/WebGL, so game rendering and input would be written against RN-specific APIs. The browser can't serve as a cheap test target, and the Vulkan requirement cuts out the low end of the device range.

### 6. NativeScript + @nativescript/canvas — not recommended now

- **What it is.** `@nativescript/canvas` exposes `getContext('2d')` and WebGL-like contexts. It is backed by Rust Skia and WGPU, with min Android API 21 ([canvas README](https://github.com/NativeScript/canvas/tree/main/packages/canvas)). Pixi, Three, Phaser and Babylon adapters exist ([repo README](https://github.com/NativeScript/canvas)).
- **Maturity.** Stable 2.1.18 (2026-08-15). v3.0.0 is in beta, beta.4 on 2026-10-09 ([releases](https://github.com/NativeScript/canvas/releases)).
- **Build.** `ns build android --release` with `--key-store-*` flags and `--aab` produces signed bundles ([NativeScript Google Play guide](https://docs.nativescript.org/guide/publishing/android-google-play)).
- **Verdict.** This is the only "native canvas" option that keeps a Canvas-like API. But it is a smaller ecosystem mid-way through a major-version rewrite. It is a reimplementation rather than Chromium, so browser behaviour won't match one-to-one, and we would lose the browser as our test target. It would only be worth revisiting if WebView rendering turns out to be the bottleneck.

### Anything better?

I found nothing newer that beats Capacitor for this shape of app. A hand-written Kotlin shell around `WebView` + `WebViewAssetLoader` ([Load local content](https://developer.android.com/develop/ui/views/layout/webapps/load-local-content)) is the minimal alternative. It removes a dependency but means rebuilding live reload, insets handling and signing config that Capacitor already provides. **Assessment:** not worth it at prototype stage.

## Recommendation

Use **Capacitor 8**:

1. Bundle the TS game with Vite.
2. Run `npx cap add android`, then in the generated project:
   - set `android:appCategory="game"` and portrait orientation in `AndroidManifest.xml`
   - set SystemBars `insetsHandling: 'css'` and hide the bars for immersive play
   - call `EdgeToEdge.enable(this)` in `MainActivity`
3. Develop with `npx cap run android --target <id> -l --port 5173 --forwardPorts 5173:5173`, over USB or paired wireless adb.
4. Release with `npx cap build android --androidreleasetype AAB --keystorepath ...`, passing secrets from environment variables.
5. Verify unattended through Playwright on the web build, then `chrome://inspect` / CDP on the phone for frame timing and console output.

Keep TWA/Bubblewrap as the zero-native fallback if we later host the game publicly anyway.
