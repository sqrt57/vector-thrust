# Physics & collision approach

Type: research
Status: resolved
Blocked by: none

## Question

For a deterministic, fixed-timestep TS simulation of a gravity/thrust vehicle in static maze levels, should flight integration and collision be our own code or a library? Compare our own integrator plus custom collision (polygon/segment terrain, swept or substep collision) against Planck.js (Box2D port), Rapier2D (WASM, deterministic build), Matter.js, and any current alternative. Cover: determinism across runs/devices, matching the current Godot `CharacterBody2D` kinematic feel (velocity integration + `move_and_slide`, see `scripts/vehicle.gd`), crash detection by impact speed/angle vs. soft landing (backlog M4), cargo on a tether/tractor beam with added mass (M6), projectiles (M8), headless testability in Vitest, performance in an Android WebView, and bundle size. End with a recommendation.

## Answer

Findings: [research/physics-collision.md](../research/physics-collision.md) (also on branch `research/physics-collision`).

Recommend **our own code**: the same velocity integration `vehicle.gd` uses, plus a custom swept polygon-vs-segment move-and-slide loop, a depenetration step for when rotation pushes the hull into a wall, and our own deterministic `sin`/`cos` (JS does not guarantee cross-platform `Math.sin`/`cos` results; Box2D ships its own trig for the same reason). This matches the `CharacterBody2D` kinematic feel by construction, gives crash/landing checks the impact speed and surface normal directly, and keeps Vitest and the WebView free of WASM. Swept collision is required, not optional: at 1200 px/s the ship moves about 20 px per tick, the same as wall thickness. Fallback, if cargo needs real tumbling: `@dimforge/rapier2d-deterministic` is the only candidate with cross-platform determinism on the web, and it has move-and-slide, rope joints and CCD; the costs are about 919 KB of gzipped WASM and churning APIs (breaking releases in Aug/Sep 2026). Rejected: box2d3-wasm (web determinism unverified, experimental mover, package lags upstream), Planck.js (deterministic only on the same JS runtime), Matter.js (no tunnelling protection, last release 2024).
