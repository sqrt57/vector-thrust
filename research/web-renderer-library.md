# Research: rendering/game library for the web port

Date: 2026-10-19
Question: Which rendering library suits Vector Thrust? It is a portrait 2D gravity/thrust game, shipped to Android in a web wrapper (Capacitor). The simulation (physics + navigator) is a separate, pure, deterministic, fixed-timestep TS module. The renderer only draws sim state and forwards input. The stack is TypeScript + Vite + Vitest + Playwright.

Candidates: raw Canvas2D, PixiJS v8, Phaser 4 (v3 is now legacy), Excalibur, KAPLAY. LittleJS is included as the strongest current "small engine" alternative. Three.js was considered and dropped (it is 3D-first and adds nothing for flat vector art).

## TL;DR

**Recommendation: PixiJS v8, used only as a renderer.** Turn off its ticker, drive `renderer.render(stage)` from our own rAF loop that steps the sim with a fixed-timestep accumulator, request the WebGL renderer, and do letterboxing ourselves with one root `Container` scale. Of all the candidates it has the least framework to fight. It has first-class TS (it is written in TS) and the healthiest release cadence, and it ships an `llms.txt` doc index for agents. It also now has a Canvas2D fallback renderer. **Raw Canvas2D is a credible runner-up**, especially for a few dozen vector shapes, and it keeps the option of swapping later cheap if the view layer stays thin. Phaser, Excalibur, KAPLAY and LittleJS are all *engines*: each owns the loop and offers its own physics/scene model, which duplicates what our sim already does.

## Comparison matrix

| Criterion | Canvas2D | PixiJS 8.22 | Phaser 4.2 | Excalibur 0.32 | KAPLAY 3001 | LittleJS 1.27 |
|---|---|---|---|---|---|---|
| Thin view over external sim | Ideal: no loop, no scene | Very good: renderer is separable, ticker can be stopped | Poor: Game owns loop, scenes, input managers | Poor: Engine owns loop + physics (physics can be disabled) | Poor: owns loop, no public step/render API | Poor: `engineInit` callbacks own the loop, physics built in |
| Android WebView perf | GPU-accelerated 2D canvas; fine for tens to hundreds of shapes | WebGL batching; best headroom | WebGL, very capable | WebGL, capable | WebGL, fine for small games | WebGL2 + Canvas2D hybrid |
| Multitouch | DIY via Pointer Events (`pointerId`) | Federated events expose `pointerId` | Pointer pool (default 1, add more) | `pointers.at(n)`, unlimited | `touchToMouse` default; touch events | Touch supported |
| Letterbox world + UI together | DIY (simple transform) | DIY (`resizeTo` only resizes) | Built in: `Scale.FIT` + `autoCenter` | Built in: `DisplayMode.FitScreen` etc. | Built in: `letterbox: true` | Built in |
| TS typings | DOM lib | Written in TS | Generated `.d.ts` from JSDoc'd JS | Written in TS | Written in TS | Ships `.d.ts` |
| Min+gz (measured, see below) | 0 | ~164 KB (upper bound) | ~369 KB | ~127 KB | ~69 KB | ~26 KB (vendor claim) |
| Latest stable / cadence | n/a (platform) | 8.22.0, 2026-10-01; ~monthly | 4.2.1, 2026-07-09 | 0.32.0, 2025-12-23; 0.33 alphas through 2026-09 | 3001.0.19, 2025-06-15; 4000 alpha since | 1.27.x, Oct 2026 |
| Adoption (npm/wk; GH stars) | n/a | 846k; 48.4k | 376k; 40.5k | 6.1k; 2.4k | 6.8k; 1.8k | ~0.9k; 4.3k |
| Agent-friendliness | Excellent: trivially deterministic, no hidden state | Good: `llms.txt`, TS types, common in training data | Good: ships 28 AI skill files | Moderate: `TestClock` for stepping | Moderate | Moderate |

## Findings per criterion

### 1. Fit with "thin view over an external sim"

- **Canvas2D** has no loop or scene graph. We write `draw(state)` and call it from our own rAF loop, as MDN recommends: "Use `requestAnimationFrame()` instead of `setInterval()`" [MDN-opt].
- **PixiJS**: `Application` is a convenience wrapper over renderer setup plus ticker updates. Its ticker has `autoStart` (default `true`) and can be stopped with `app.stop()` [pixi-app] [pixi-ticker]. You can skip `Application` entirely: `autoDetectRenderer()` returns a renderer whose `render(container)` you call yourself [pixi-renderers] [pixi-d.ts: `AbstractRenderer.render(options | Container)`]. There is no physics and no game-object lifecycle, so the sim stays the single source of truth.
- **Phaser 4**: `Game.step(time, delta)` is "Called automatically by the Time Step, once per browser frame". Each step updates the global managers (input, sound) and then each Scene, then renders [phaser-src `src/core/Game.js`]. The game loop, scene lifecycle and input managers are Phaser's. Our sim would sit inside a Scene's `update`, and we would ignore Arcade/Matter physics. That works, but we would be fighting the architecture.
- **Excalibur**: "The Excalibur engine uses a simple main loop", and you hook in through `onPreUpdate`/`onPostUpdate` [ex-engine]. `EngineOptions.physics?: boolean | PhysicsConfig` defaults to Arcade physics, which can be turned off. It also has `fixedUpdateFps`/`fixedUpdateTimestep` and a `TestClock` with manual `step()` [ex-d.ts `Engine.d.ts`, `Util/Clock.d.ts`]. Good engine hygiene, but again it is the engine's loop.
- **KAPLAY**: `kaplay({...})` starts the engine. Game code registers `onUpdate`/`onFixedUpdate`/`onDraw` callbacks. The public context exposes no step or render entry point [kaplay-d.ts `dist/doc.d.ts`]. The engine also includes collision (`hashGridSize` "for collision detection") [kaplay-d.ts].
- **LittleJS**: `engineInit(gameInit, gameUpdate, gameUpdatePost, gameRender, gameRenderPost)`. It ships "Robust arcade physics" and Box2D integration [littlejs-readme]. The engine owns the loop.

### 2. Android WebView performance

- Capacitor (current docs: v8) supports API 24+ and "requires an Android WebView with Chrome version 60 or later" [cap-android]. The WebView is therefore Chromium, so WebGL is available on any device we target.
- PixiJS calls its WebGL renderer the "Default... Well supported and stable" and recommends it "for production applications". WebGPU is "still maturing" [pixi-renderers]. `autoDetectRenderer` "will prioritize the WebGL renderer as it is the most tested safe API" [pixi-d.ts `autoDetectRenderer.d.ts`]. Since v8.16.0 (2026-02-03) Pixi also has a Canvas renderer ("feat: Canvas renderer", PR #11815) [pixi-rel-8.16], so `preference: ['webgl', 'canvas']` gives a fallback ladder. (The renderers guide still says "Coming-soon", so that page is stale.)
- WebGPU on Android Chrome needs Android 12+ and Qualcomm/ARM GPUs [chrome-webgpu-121]. I found no primary source confirming it is on by default in Android WebView. A Chromium intent-to-ship for WebGPU *Compatibility mode* lists Android WebView among its targets [blink-webgpu-compat]. Conclusion: don't depend on WebGPU. Pin WebGL.
- Canvas2D: Android's 2D pipeline is GPU-accelerated by default for target API ≥ 14 [android-hwaccel]. MDN's canvas performance tips (batch paths, avoid `shadowBlur`, avoid per-frame text, `alpha:false`, scale for `devicePixelRatio`) [MDN-opt] are the levers we would need. For a line-art ship, terrain polylines and a HUD, that is very likely enough. Glow/bloom effects would be costly in Canvas2D (`shadowBlur`) and cheap as Pixi filters.
- **Not verified here:** frame-time numbers on a real mid-range Android device. That needs a quick on-device prototype (see Open questions).

### 3. Multitouch

The control scheme needs simultaneous touches: hold-to-thrust plus pointing at a target.
- Canvas2D/DIY: standard Pointer Events. Track `pointerId` per active touch on the canvas or on DOM buttons.
- PixiJS: a "unified, DOM-like federated event model". Pointer events are "Recommended for general use", and `globalpointermove` fires "regardless of whether any display object is hit" [pixi-events]. `FederatedPointerEvent.pointerId` mirrors the DOM field [pixi-d.ts `events/FederatedPointerEvent.d.ts`]. With a thin view, raw DOM pointer events on the canvas are equally fine.
- Phaser: `input.activePointers` "number of Pointer objects created by default... you can leave this as 1" (default `1`) [phaser-src `src/core/Config.js`]. Raise it in config or call `scene.input.addPointer(n)`. Access is via `pointer1`..`pointer10` or `manager.pointers[n]` [phaser-input].
- Excalibur: "closely follows the W3C Pointer Events spec". Multi-touch works via `engine.input.pointers.at(n)` with no limit. However, "There is no way to identify touches after they happen; you can only know that there are n touches" [ex-pointers]. That is awkward for "this finger is the thrust button".
- KAPLAY: `touchToMouse` (default `true`) translates touches to mouse clicks. There are separate `onTouchStart(pos, t: Touch)` events [kaplay-d.ts].

### 4. Letterboxed scaling of world + UI together

- Built in: Phaser `Scale.FIT` "keeping the aspect ratio" plus `autoCenter: CENTER_BOTH`. World/cameras use the unscaled game size and the canvas is scaled [phaser-scale]. Excalibur `DisplayMode.FitScreen`/`FitContainer` and variants, with a logical `resolution` mapped onto the CSS-pixel `viewport` [ex-screens]. KAPLAY `letterbox`: "keep aspect ratio and leave black bars" [kaplay-d.ts].
- Not built in: Pixi's resize plugin only makes "the renderer automatically adjust to match the dimensions of the target" [pixi-resize]. Canvas2D has nothing. In both, letterboxing is about 20 lines: pick a logical portrait size, compute `s = min(w/W, h/H)`, then apply `ctx.setTransform` (Canvas2D) or `root.scale/position` (Pixi). Because world *and* the in-canvas control strip live under the same root, they scale together. Account for `devicePixelRatio` per MDN [MDN-opt]. This is low risk and keeps the input-to-logical-coordinate mapping in our hands, which the sim needs anyway.

### 5. TS typings quality

- PixiJS: source in TS, `types: lib/index.d.ts` [npm pixi.js].
- Excalibur: written in TS, `build/dist/excalibur.d.ts` [npm excalibur].
- KAPLAY: TS, `dist/doc.d.ts` [npm kaplay].
- Phaser: source is JavaScript (`src/**/*.js` with JSDoc). Types ship as a single generated `types/phaser.d.ts` [npm phaser; package contents].
- LittleJS: ships `dist/littlejs.d.ts`, and the README claims "Full TypeScript and Module support" [littlejs-readme].
- Canvas2D: TS DOM lib.

### 6. Bundle size

I measured this myself on 2026-10-19 with esbuild 0.28.2: `--bundle --minify --format=esm`, gzip -9, each library's latest stable from npm. Each entry is a minimal "create app + polygon + text" for that library.

| Library | min | min+gz |
|---|---|---|
| pixi.js 8.22.0 | 564 KB | 164 KB |
| phaser 4.2.1 | 1,395 KB | 369 KB |
| excalibur 0.32.0 | 495 KB | 127 KB |
| kaplay 3001.0.19 | 189 KB | 69 KB |

Pixi lazily imports its renderer ("dynamically imported to optimize... initial bundle size") [pixi-d.ts `autoDetectRenderer.d.ts`]. Without code splitting the measured figure includes all three renderers, so it is an upper bound. Pixi also has `skipExtensionImports` for hand-picked extensions [pixi-d.ts `SharedSystems.d.ts`]. LittleJS self-reports about 26 KB gz for a small 2D game [littlejs-readme] (not measured). In a Capacitor APK the assets load from local storage, so none of these sizes matter much. Phaser's size is the only notable one.

### 7. Maintenance health

All dates come from the npm registry and GitHub releases, queried 2026-10-19.
- PixiJS: v8.15.0 (2026-01-05) through v8.22.0 (2026-10-01), roughly monthly minors. Dev builds are published as recently as 2026-10-10, and the repo was pushed 2026-10-17 [gh-pixi-releases].
- Phaser: v4.0.0 shipped 2026-04-10 after a long RC run. It is a "ground-up rebuild of the WebGL renderer" with "AI Agent Skills - 28 comprehensive skill files" [phaser-4.0-release]. 4.1.0 came 2026-04-30, 4.2.0 on 2026-06-19 and 4.2.1 on 2026-07-09. The last v3 release was 3.90.0 (2025-05-23) [npm phaser].
- Excalibur: the last stable is 0.32.0 (2025-12-23), still pre-1.0. `next` 0.33.0-alpha builds come almost daily (latest 2026-09-21) [npm excalibur; gh-ex-releases].
- KAPLAY: the last stable is 3001.0.19 (2025-06-15), 16 months ago. The 4000.0.0 line has been in alpha since 2025. The latest is alpha.27.1 (2026-05-12) [npm kaplay; gh-kaplay-releases].
- LittleJS: 1.27.x, published 2026-10-15 [npm littlejsengine].

### 8. LLM familiarity / agent-friendliness

- Adoption is a proxy for how much training data and how many examples exist. npm downloads for the week 2026-10-12..18: pixi.js 845,563, phaser 376,276, kaplay 6,817, excalibur 6,149, littlejsengine 938 [npm-downloads]. GitHub stars: Pixi 48.4k, Phaser 40.5k, LittleJS 4.3k, Excalibur 2.4k, KAPLAY 1.8k [gh-api].
- Agent docs: Pixi publishes an `llms.txt` index of Markdown guides [pixi-llms]. Phaser 4 ships `skills/` (28 subsystems plus a v3→v4 migration skill) in the npm package [phaser-4.0-release; package contents]. There is no `llms.txt` at excaliburjs.com, kaplayjs.com or docs.phaser.io (all HTTP 404 on 2026-10-19).
- One caveat: Pixi v8 changed many APIs from v7 (see the v8 migration guide [pixi-llms]). Agents may produce v7-style code (`new Application({...})` without `await app.init`, `beginFill`). Point them at `llms.txt` and pin the version in AGENTS.md.
- Testability: with the sim outside the renderer, unit tests (Vitest) don't touch the renderer at all for any option. For the view, Canvas2D and Pixi let a test build a known sim state, call `draw`/`render` once, and take a screenshot, with no engine clock to freeze. Excalibur offers `TestClock` [ex-d.ts]. Phaser/KAPLAY need their loop paused or waited on.
- Headless screenshots: headless Chrome "disables GPU" by default and falls back to SwiftShader software rendering [chrome-headless-gpu]. WebGL therefore still renders in Playwright's Chromium, but through a software rasterizer. Playwright notes that rendering "can vary based on the host OS, version, settings, hardware". It provides `threshold`/`maxDiffPixels` and advises running "in the same environment where the baseline screenshots were generated" [pw-snapshots]. Canvas2D output tends to be the most stable across environments. For Pixi, `preserveDrawingBuffer` (default `false`) is "Needed for `toDataURL`" [pixi-app]. It is only needed if a test reads pixels from the canvas rather than using Playwright's page screenshot (inference: page screenshots capture the composited frame).

## Recommendation

1. **Use PixiJS v8 (≥ 8.22) as a pure renderer.**
   - Create it with `autoDetectRenderer({ preference: ['webgl', 'canvas'] })`, or `Application` with the ticker stopped.
   - Own the rAF loop: run a fixed-timestep accumulator into the sim, then call `renderer.render(root)` with interpolated state.
   - Handle input as DOM Pointer Events on the canvas, tracked by `pointerId`, mapped through our own letterbox transform into logical coordinates, and forwarded to the sim.
   - Put the world and the in-canvas control strip under one scaled `root` container.
   - This gives GPU headroom (filters for glow, particle containers for exhaust) and the best TS and agent support. Its only "framework" cost is a scene graph we rebuild or patch from sim state each frame.
2. **Fallback / alternative: raw Canvas2D.** Choose it if the art stays strictly line-vector and we want zero dependencies and the most deterministic screenshots. Keep the view interface (`draw(simState, viewport)`) the same either way, so switching later is cheap.
3. **Avoid Phaser, Excalibur, KAPLAY and LittleJS** for this architecture. Each is a fine engine, but each owns the loop and scene/physics model our sim already provides. On top of that: Phaser adds the largest bundle and JS-sourced types, Excalibur's touches can't be tracked by identity, and KAPLAY has had no stable release for 16 months and translates touch to mouse by default.

## Open questions

- Real frame times on a low-end Android WebView for Canvas2D vs Pixi/WebGL with our actual scene. Build a throwaway prototype and test on a device. This is the one thing that could flip the choice toward Canvas2D (if both are fine, simpler wins) or confirm Pixi.
- Whether WebGPU is enabled by default in Android WebView today (not needed if we pin WebGL).

## Sources

- [MDN-opt] MDN, Optimizing canvas: https://developer.mozilla.org/en-US/docs/Web/API/Canvas_API/Tutorial/Optimizing_canvas
- [pixi-llms] PixiJS llms.txt: https://pixijs.com/llms.txt
- [pixi-app] PixiJS Application guide: https://pixijs.com/8.x/guides/components/application
- [pixi-ticker] PixiJS Ticker plugin: https://pixijs.com/8.x/guides/components/application/ticker-plugin.md
- [pixi-resize] PixiJS Resize plugin: https://pixijs.com/8.x/guides/components/application/resize-plugin.md
- [pixi-renderers] PixiJS Renderers guide: https://pixijs.com/8.x/guides/components/renderers.md
- [pixi-events] PixiJS Events guide: https://pixijs.com/8.x/guides/components/events.md
- [pixi-d.ts] pixi.js@8.22.0 package type declarations (`lib/rendering/renderers/autoDetectRenderer.d.ts`, `lib/rendering/renderers/shared/system/SharedSystems.d.ts`, `lib/events/FederatedPointerEvent.d.ts`, `lib/rendering/renderers/shared/system/AbstractRenderer.d.ts`)
- [pixi-rel-8.16] PixiJS v8.16.0 release notes: https://github.com/pixijs/pixijs/releases/tag/v8.16.0
- [gh-pixi-releases] https://github.com/pixijs/pixijs/releases
- [phaser-4.0-release] Phaser v4.0.0 release: https://github.com/phaserjs/phaser/releases/tag/v4.0.0
- [phaser-src] phaser@4.2.1 source, `src/core/Game.js`, `src/core/Config.js`
- [phaser-scale] Phaser Scale Manager docs: https://docs.phaser.io/phaser/concepts/scale-manager
- [phaser-input] Phaser Input docs: https://docs.phaser.io/phaser/concepts/input
- [ex-engine] Excalibur Engine docs: https://excaliburjs.com/docs/engine
- [ex-screens] Excalibur Screens docs: https://excaliburjs.com/docs/screens
- [ex-pointers] Excalibur Pointers docs: https://excaliburjs.com/docs/pointers
- [ex-d.ts] excalibur@0.32.0 type declarations (`build/dist/Engine.d.ts`, `build/dist/Util/Clock.d.ts`)
- [gh-ex-releases] https://github.com/excaliburjs/Excalibur/releases
- [kaplay-d.ts] kaplay@3001.0.19 `dist/doc.d.ts` (KAPLAYOpt: `letterbox`, `touchToMouse`, `hashGridSize`; `onTouchStart`, `onFixedUpdate`)
- [gh-kaplay-releases] https://github.com/kaplayjs/kaplay/releases
- [littlejs-readme] https://github.com/KilledByAPixel/LittleJS
- [cap-android] Capacitor Android docs: https://capacitorjs.com/docs/android
- [chrome-webgpu-121] What's new in WebGPU (Chrome 121): https://developer.chrome.com/blog/new-in-webgpu-121
- [blink-webgpu-compat] Intent to Ship: WebGPU Compatibility mode: https://groups.google.com/a/chromium.org/g/blink-dev/c/N3RlLGCOTJ4/m/loneRTlPBwAJ
- [android-hwaccel] Android hardware acceleration: https://developer.android.com/develop/ui/views/graphics/hardware-accel
- [chrome-headless-gpu] Chrome for Developers, Supercharge Web AI model testing: https://developer.chrome.com/blog/supercharge-web-ai-testing
- [pw-snapshots] Playwright visual comparisons: https://playwright.dev/docs/test-snapshots
- [npm …] npm registry metadata via `npm view <pkg> --json` (versions, publish times, `types`), 2026-10-19
- [npm-downloads] https://api.npmjs.org/downloads/point/last-week/pixi.js,phaser,excalibur,kaplay,littlejsengine
- [gh-api] GitHub REST `repos/{owner}/{repo}` (stargazers_count, pushed_at), 2026-10-19
