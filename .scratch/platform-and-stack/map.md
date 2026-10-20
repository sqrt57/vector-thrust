# Map: Android platform & prototype stack

Label: wayfinder:map

## Destination

Decided (and recorded as ADRs/design docs): the final Android platform (TypeScript in a wrapper vs. Godot), whether the HTML codebase is throwaway prototypes or the real game, the web stack (renderer, physics/collision, build, tests), and what happens to the Godot M0–M3 code, the `design/` docs, and the backlog. Scaffolding the new project is the first step *after* this map, not part of it.

## Notes

- Domain: Vector Thrust, a portrait 2D gravity/thrust game on Android, with point-to-navigate controls (see `design/concept.md`, `design/control-schemes.md`, `design/backlog.md`).
- Why we're doing this: the current loop is slow at (b) export + `adb install` to the device, and (c) the LLM gets little feedback from GDScript/`.tscn`. Judge every option on **how well an agent can build *and verify* it unattended**, alongside runtime performance on low/mid-tier Android devices.
- Lean: one TypeScript codebase shipped in an Android wrapper, with Godot as the fallback if research or the device spike rule TS out.
- Settled up front: Android only; web/desktop are dev/preview targets; iOS is out. Godot M0–M3 code is a disposable prototype. What carries over is the tuned values (`gravity=800`, `thrust_acceleration=1400`, `navigator_turn_rate=3.0`, `navigator_min_climb_ratio=1.2`) and the navigator algorithm in `scripts/vehicle.gd`.
- Settled up front: the simulation (flight physics + navigator) is a pure, fixed-timestep, deterministic module separate from rendering, so agents can unit-test trajectories.
- Settled up front: default tooling is TypeScript + Vite + Vitest + Playwright/Chrome automation. Only the renderer and physics/collision get researched.
- Settled up front: same repo. Godot files get deleted once the decision lands (history keeps them). `design/` merges into `docs/`, restructured, with outdated info retired.
- Skills: `grilling` + `domain-modeling` for decision tickets; `research` for research tickets; `prototype` for the device spike. Record hard-to-reverse decisions as ADRs in `docs/adr/`.

## Decisions so far

- [TypeScript-on-Android runtime options](issues/01-ts-android-runtimes.md): Capacitor 8 (system WebView, CLI build, adb live reload); TWA as the fallback; frame rate still to be measured on the device
- [Physics & collision approach](issues/04-physics-collision.md): own integrator + swept move-and-slide + deterministic trig; Rapier deterministic build only if cargo needs real rigid bodies
- [Godot agent-feedback story](issues/02-godot-agent-feedback.md): headless logic tests are fine (GUT/gdUnit4), but visuals and input need a windowed GPU process, type checks need a running editor, MCP tooling is community-only; weaker than the web loop except native Android
- [Web renderer / game library choice](issues/03-web-renderer-library.md): PixiJS v8 as a renderer only, under our own loop (WebGL, Canvas2D fallback); raw Canvas2D as the runner-up pending device frame times
- [Real-device spike: web build on Android vs. Godot APK](issues/05-android-device-spike.md): TS is good enough on the phone; all three renderers feel the same as Godot at 60 fps, only Pixi WebGL keeps 60 fps at 3000 shapes; live reload ~0.65 s; JDK 21 and Windows `cap run` gotchas found
- [Final Android platform decision](issues/06-final-platform-decision.md): TypeScript in Capacitor 8, Godot dropped; the TS project is the real game but can be thrown away; reopen Godot only on unfixable frame drops on the Redmi Note 13 Pro ([ADR 0001](../../docs/adr/0001-typescript-capacitor-android-platform.md))
- [Web stack decision: renderer and physics](issues/07-web-stack-decision.md): PixiJS v8 WebGL as a read-only view; our own rAF loop with a fixed 60 Hz accumulator; hand-written swept move-and-slide inside a same-runtime-deterministic sim; Rapier only if M6 cargo needs it ([ADR 0002](../../docs/adr/0002-pixi-renderer-over-own-loop-and-deterministic-sim.md))

## Not yet specified

- **Daily Android dev loop on the chosen platform**: live-reload onto the device, or how often to do device checks vs. browser-only checks; whether and when to add a low-tier test phone; folding in the spike's toolchain gotchas (JDK 21, Windows `cap run`, HyperOS install block).

## Out of scope

- iOS builds and signing.
- Scaffolding the new project and porting M3 code: the first build step after this map.
- Play Store release pipeline details (release keystore, store listing): M10. Only *feasibility* on the chosen platform counts here.
