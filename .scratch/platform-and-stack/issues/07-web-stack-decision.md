# Web stack decision: renderer and physics

Type: grilling
Status: resolved
Blocked by: 03, 04, 05

## Question

Which renderer/game library and which physics/collision approach does the web codebase use, given [Web renderer / game library choice](03-web-renderer-library.md), [Physics & collision approach](04-physics-collision.md), and what [Real-device spike: web build on Android vs. Godot APK](05-android-device-spike.md) exposed? Settle how they sit around the pure deterministic sim module (who owns the game loop, fixed-timestep accumulator, where collision lives). Record it as an ADR in `docs/adr/`.

## Answer

ADR: [0002 Pixi renderer over our own loop and a deterministic sim with hand-written collision](../../../docs/adr/0002-pixi-renderer-over-own-loop-and-deterministic-sim.md).

- **Renderer**: PixiJS v8, WebGL pinned, no Canvas2D fallback (show an error if WebGL is missing). Only Pixi WebGL held 60 fps at 3000 shapes in the spike.
- **Physics**: our own integrator (ported from `vehicle.gd`) plus swept polygon-vs-segment move-and-slide with depenetration. No library. Reopen with `@dimforge/rapier2d-deterministic` only if M6 cargo needs real rigid-body tumbling.
- **Loop**: our own `requestAnimationFrame` loop. A fixed 60 Hz accumulator (capped at about 5 ticks per frame), paused on `visibilitychange`, and one `renderer.render(root)` per frame. Pixi's ticker is off. No render interpolation until judder shows up above 60 Hz.
- **Tick rate**: 60 Hz, fixed, as a sim constant (the rate the values were tuned at).
- **Collision lives in the sim**: level geometry, move-and-slide, crash/landing contacts (impact speed, surface normal) and projectile hits. The renderer is a read-only view and is never used for hit-testing.
- **Determinism**: same-runtime (fixed step, seeded RNG, no wall clock). All trig goes through one sim math module so deterministic trig can be swapped in later.

The sim's public interface and per-tick input were left to [Sim module conventions](10-sim-module-conventions.md).
