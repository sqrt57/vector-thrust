# Pixi renderer over our own loop and a deterministic sim with hand-written collision

The game is a pure, fixed-timestep simulation that owns all geometry and contacts, driven by our own loop and drawn by PixiJS v8 as a read-only view. We chose this so agents can unit-test trajectories, crashes and landings in Vitest with no renderer, WASM or wall clock involved, and so the renderer stays swappable.

- **Sim**: fixed 60 Hz tick (the rate the Godot values were tuned at). The integrator is ported from `vehicle.gd`. Collision is our own swept polygon-vs-segment move-and-slide with a depenetration step after rotation. Level geometry, move-and-slide, crash/landing contact results (impact speed, surface normal) and projectile hits all live inside the sim. Determinism is required per runtime (fixed step, seeded RNG, no wall clock), and every trig call goes through one sim math module so deterministic trig can be swapped in if cross-device replays are ever needed.
- **Loop**: our own `requestAnimationFrame` loop owns time. It runs the 60 Hz accumulator (about 5 ticks per frame at most), pauses on `visibilitychange`, and calls `renderer.render(root)` once per frame. Pixi's ticker is off. Rendering shows the latest sim state with no interpolation.
- **Renderer**: PixiJS v8 with WebGL pinned and no Canvas2D fallback. If WebGL is missing we show an error. The renderer never feeds back into the sim, and display objects are never used for hit-testing.

## Considered Options

- **A physics library** (Planck.js, Matter.js, box2d3-wasm, Rapier): rejected because they lack web determinism, don't protect against tunnelling, or are heavy WASM with churning APIs. A kinematic move-and-slide matches the Godot `CharacterBody2D` feel by construction.
- **Raw Canvas2D or Pixi's Canvas renderer**: on the Redmi Note 13 Pro, both dropped to 30–36 fps at 3000 shapes, while Pixi WebGL held 60 fps.
- **Full engines** (Phaser 4, Excalibur, KAPLAY, LittleJS): rejected because they own the loop and would duplicate the sim.

## Consequences

Reopen the physics choice only if M6 cargo needs real rigid-body tumbling that a hand-written tether can't fake. In that case `@dimforge/rapier2d-deterministic` is the candidate. Add render interpolation only if judder shows up on a device that runs the WebView above 60 Hz.
