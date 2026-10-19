# Flight integration and collision: own code or a library?

Researched 2026-10-19 for the TypeScript port of Vector Thrust. Settled
going in: TypeScript + Vitest, and the simulation is a pure, deterministic,
fixed-timestep TS module kept separate from rendering.

## TL;DR

**Write it ourselves.** Use a semi-implicit Euler integrator (what
`vehicle.gd` does today), plus a swept convex-polygon-vs-segment
move-and-slide over static terrain, plus our own deterministic `sin`/`cos`.
That is the only option that:

- matches the current `CharacterBody2D` feel by construction,
- hands crash/landing logic the pre-impact velocity and contact normal directly,
- adds no WASM to Vitest or the WebView, and
- makes determinism something we control rather than something we inherit.

If M6 later needs cargo that swings and collides like a real rigid body,
the one library worth adding is **Rapier2D's `-deterministic` build**. It is
the only candidate with a documented cross-platform determinism guarantee
on the web. It also ships move-and-slide, rope joints and CCD. The costs are
about 0.9 MB of gzipped WASM and an API that changes fast.

## What we are matching (current Godot prototype)

- `scripts/vehicle.gd` integrates velocity by hand each physics tick:
  `velocity.y += gravity * delta`, then
  `velocity += Vector2.UP.rotated(rotation) * thrust_acceleration * delta`
  while thrust is held, then `move_and_slide()`. Rotation is set directly
  (rate-limited), not simulated. The navigator uses `acos`, `asin`, `sin`
  and `rotated()`, so it needs trig.
- The vehicle is a `CharacterBody2D` with a 24x30 `RectangleShape2D`
  (`scenes/vehicle.tscn`). Walls are `StaticBody2D` rectangles 20 px thick
  (`scenes/main.tscn`). `motion_mode` is not overridden, so it is the
  default, grounded.
- `move_and_slide()` moves the body by `velocity` (the physics delta is
  applied for you). On a hit it slides along the surface instead of
  stopping, and it **modifies `velocity` when a slide collision occurs**.
  Defaults: `max_slides = 4`, `safe_margin = 0.08`,
  `floor_max_angle ≈ 45°`. Grounded mode classifies floor, wall and ceiling;
  floating mode reports everything as walls. Each collision can be read
  back with `get_slide_collision(i)`.
  ([Godot CharacterBody2D docs](https://docs.godotengine.org/en/stable/classes/class_characterbody2d.html))

So the "feel" is a **kinematic body under user-written integration, with
a swept slide-along-surface resolver**. It is not a rigid body under a
contact solver. No restitution, friction model or angular response is
involved. That framing drives most of the comparison below: every
rigid-body engine has to be either (a) used only as a collision-query
layer under our own slide loop, or (b) given a kinematic character
controller of its own.

## Candidates at a glance

| | Own TS code | Planck.js | box2d3-wasm (Box2D v3) | Rapier2D (deterministic) | Matter.js |
|---|---|---|---|---|---|
| Language / runtime | TS | Pure JS/TS | C compiled to WASM (Emscripten) | Rust compiled to WASM | Pure JS |
| Latest release | n/a | 1.5.1, 2026-10-12 [npm] | 5.2.0, 2026-02-16 [npm] | 0.21.0, 2026-09-25 [npm] | 0.20.0, 2024-06-23 [npm] |
| Cross-device determinism | Ours to guarantee | Same JS runtime only ([docs][planck-lim]) | Upstream: 64-bit native targets ([Box2D docs][b2-sim]); WASM build not stated | **Guaranteed** for the `-deterministic` package ([README][rapier-ts]) | Open issue on cross-browser differences ([#1174][matter-1174]) |
| Move-and-slide for a kinematic body | We write it (~1 loop) | None; build on TOI/raycast | Geometric mover toolkit, **experimental** ([Box2D docs][b2-char]) | `KinematicCharacterController` ([Rapier docs][rapier-kcc]) | None |
| Anti-tunnelling | Swept by design | TOI + sub-stepping CCD ([docs][planck-core]) | CCD vs static by default, bullets ([docs][b2-sim]) | Opt-in CCD + soft CCD ([docs][rapier-rb]) | **No CCD**, issue open; maintainer advises sub-stepping ([#5][matter-5]) |
| Impact data for crash test | Pre-impact v and normal, directly | Contacts + post-solve impulses ([docs][planck-contacts]) | Hit events with `approachSpeed` above a threshold ([docs][b2-sim]) | Contact-force events over a threshold; KCC gives normal + TOI ([docs][rapier-adv]) | Collision events |
| Rope / tether | We write a distance constraint | Rope + distance joints ([docs][planck-docs]) | Distance joint with min/max length + spring ([docs][b2-sim]) | `JointData.rope`, `JointData.spring` (typings) | Constraints |
| Shipped payload (gzip, measured) | Few KB | `planck.min.js` 297 KB raw / 55 KB gz | WASM 417–428 KB raw / ~155 KB gz | WASM 2.44 MB raw / **919 KB gz** | `matter.min.js` 83 KB raw / 26 KB gz |
| Vitest friction | None | None | WASM init; Node supported ([README][b2wasm]) | WASM init; plain package imports `.wasm` as an ES module | None |
| Maintenance | Us | Active, MIT | 1 small repo, lags upstream | Very active, frequent breaking changes | Slow releases; commits in 2026 |

Payload sizes were measured with `npm pack` of the listed versions and
`gzip -9` (see the size section below).

## Determinism across runs and devices

**JavaScript arithmetic is safe; JavaScript trig is not guaranteed.**
ECMAScript leaves `acos`, `asin`, `atan2`, `cos`, `sin`, `tan`, `exp`,
`pow` and similar "not precisely specified". It only *recommends* fdlibm
([ECMA-262 §21.3.2](https://tc39.es/ecma262/#sec-function-properties-of-the-math-object)).
`sqrt`, `abs` and the basic operators are not on that list. JS also has no
fused multiply-add for a compiler to contract into. V8, which runs both
Node/Vitest and Android's Chromium WebView, uses an fdlibm port
([v8/src/base/ieee754.cc](https://github.com/v8/v8/blob/main/src/base/ieee754.cc)).
In practice that makes cross-device drift unlikely, but the spec does not
promise it. Box2D v3 reached cross-platform determinism partly by shipping
its **own atan2, cosine and sine** and disabling float contraction
([Box2D simulation docs][b2-sim]). Our own module should do the same: a
small polynomial `sin`/`cos`/`atan2`, plus the navigator's `asin`/`acos`
replaced or approximated.

**WebAssembly floats are deterministic except for NaN bit patterns,
shared-memory threads and relaxed SIMD**
([WebAssembly Nondeterminism.md](https://github.com/WebAssembly/design/blob/main/Nondeterminism.md)).
The engine's own source still has to avoid nondeterministic math, though.

- **Rapier.** The plain `@dimforge/rapier2d` package "does **not**
  guarantee cross-platform determinism (but it is still locally
  deterministic)". `@dimforge/rapier2d-deterministic` is "a less optimized
  build but with a guarantee of a cross-platform deterministic execution"
  ([bindings README][rapier-ts]). The determinism guide adds the
  conditions: same Rapier version, identical construction order, and
  initial values not derived from `Math.sin`/`Math.cos`. It suggests
  hashing `world.takeSnapshot()` to verify
  ([Rapier determinism guide](https://rapier.rs/docs/user_guides/javascript/determinism)).
  That snapshot hash would make a good Vitest golden test.
- **Box2D v3** states cross-platform determinism "on 64-bit platforms"
  through compiler flags and custom trig ([docs][b2-sim]). It first shipped
  in v3.1.0 ([release notes](https://github.com/erincatto/box2d/releases/tag/v3.1.0)).
  box2d3-wasm targets wasm32 and does not document whether the guarantee
  survives its build. Its "deluxe" flavour uses SIMD + pthreads. Its
  "compat" flavour sets `BOX2D_DISABLE_SIMD=ON`
  ([build script](https://github.com/Birch-san/box2d3-wasm/blob/main/box2d3-wasm/shell/0_build_makefile.sh)).
  Treat its determinism as **unverified**, and use compat with threading
  off if we went this way.
- **Planck.js**: "For the same input, and same javascript runtime …
  will reproduce any simulation". Identical results across binaries or
  platforms: "The answer is no" ([Limitations][planck-lim]). One open
  issue reports run-to-run divergence when a world is reused after
  removing bodies. The maintainer's advice is not to reuse worlds, and the
  issue is still open ([#282](https://github.com/piqnt/planck.js/issues/282)).
- **Matter.js**: the maintainer says it should be deterministic with a
  fixed timestep ([#820](https://github.com/liabru/matter-js/issues/820)).
  An open issue documents different results across browsers and platforms
  even with `isFixed = true`
  ([#1174][matter-1174]).

## Matching the CharacterBody2D feel

- **Own code**: reproduce the same loop exactly. Integrate velocity, sweep
  the hull along `velocity*dt` against terrain segments, stop at time of
  impact minus a skin (Godot's `safe_margin` is the analogue), project the
  remaining motion and the velocity onto the surface tangent, and repeat
  up to 4 times. Because rotation is set directly (as in `vehicle.gd`), a
  rotation step can push the hull into a wall. We also need a small
  depenetration "recovery" pass, which is the job Godot's `safe_margin`
  does. The whole thing is only a few hundred lines when terrain is static
  segments.
- **Rapier**: `KinematicCharacterController` is explicitly "the
  well-known *move-and-slide* operation". It has an offset/skin, slope
  limits, autostep and snap-to-ground. Gravity is left to the caller
  ([Rapier character controller][rapier-kcc]). Each `CharacterCollision`
  carries `toi`, `normal1`/`normal2`, witnesses and the translation applied
  and remaining (typings in `@dimforge/rapier2d-deterministic@0.21.0`,
  `control/character_controller.d.ts`). This is the closest off-the-shelf
  match. It only handles translation, which suits us.
- **Box2D v3**: the geometric mover (`b2World_CastMover`,
  `b2World_CollideMover`, `b2SolvePlanes`, `b2ClipVector`) is a toolkit
  for building move-and-slide. Both mover types are labelled
  **experimental** ([Box2D character docs][b2-char]). v3.2.0 (released
  today) adds a "dynamic character mover with new mover and pogo joints
  (experimental)"
  ([v3.2.0 release](https://github.com/erincatto/box2d/releases/tag/v3.2.0)).
  The box2d3-wasm 5.2.0 typings do expose `CastMover`, `SolvePlanes` and
  `ClipVector`.
- **Planck.js / Matter.js**: neither has a character controller. Planck
  could serve as a query layer (ray casts, time of impact) under our own
  slide loop. Otherwise we would make the ship a dynamic body, and the
  contact solver's restitution and friction would change the feel. Planck
  also warns of "around 0.5cm of slop" and that shapes "may begin to
  overlap and then be pushed apart by the solver" ([Limitations][planck-lim]).

**Tunnelling.** Speed is unbounded: there is no drag, gravity is
800 px/s² and thrust is 1400 px/s². At 1200 px/s and a 60 Hz tick the ship
moves 20 px per tick, the same as the wall thickness. A swept test is
therefore required, not optional. Godot's move-and-slide is a sweep, and
our own loop would be too. Matter.js has no CCD
([#5][matter-5]), which rules it out on this alone.

## Crash vs. soft landing (M4)

The test we need: at first contact, take the normal speed `-v·n`, the
tangential speed and the ship's attitude relative to `n`, then compare
them with thresholds.

- **Own code**: `v` before the slide projection and `n` from the sweep
  are both already in hand. Classification is a pure function, easy to
  unit-test.
- **Rapier KCC**: the collision normal comes from `CharacterCollision`.
  The pre-impact velocity is our own (we pass in the desired translation).
  This works just as well. With dynamic bodies, Rapier's impact signal is
  contact-*force* events above a threshold, not approach speed
  ([advanced collision detection][rapier-adv]).
- **Box2D v3**: hit events fire when shapes collide "with a speed faster
  than the hit event threshold" and report `approachSpeed`. They must be
  enabled per shape ([docs][b2-sim]). That suits dynamic bodies. With the
  geometric mover we compute it ourselves anyway.
- **Planck**: contact listeners plus post-solve normal impulses
  ([contacts docs][planck-contacts]). Approach speed has to be derived.

## Cargo on a tether with added mass (M6)

- **Own code**: the ship's mass then matters for the first time, because
  today it is all accelerations. Model cargo as a point mass joined to the
  ship by an inelastic rope (max-length constraint with a
  position/velocity correction), or a stiff spring. Both get the same
  swept collision against terrain. The ship's thrust acceleration becomes
  `thrust_force / (m_ship + m_cargo)` while cargo is attached. This is
  well-trodden ground (position-based dynamics distance constraint), and
  one joint between two bodies stays small.
- **Rapier**: `JointData.rope(length, …)` and `JointData.spring(rest,
  stiffness, damping, …)` (typings `dynamics/impulse_joint.d.ts`), plus
  `setAdditionalMass` ([rigid bodies][rapier-rb]). One caveat: ropes pull
  on dynamic bodies, but a KCC-driven kinematic ship is not pushed back by
  them. Coupling the cargo's tug back into the ship's velocity is still
  our code.
- **Box2D v3**: distance joint with min/max length and spring
  ([docs][b2-sim]). Planck: rope and distance joints
  ([docs index][planck-docs]). Planck warns that joint chains stretch past
  a 10:1 mass ratio and "continuous collision does not handle joints"
  ([Limitations][planck-lim]).

M6 is the strongest case for a library. If the design wants cargo that
tumbles, bounces off walls and drags the ship around physically, a real
solver earns its keep. If it is a pendulum point mass, our own code is
simpler.

## Projectiles (M8)

Projectiles are points or small circles on straight or ballistic paths
against static segments and a few enemies. In our own code that is a ray
or segment cast per tick: the same primitive the ship sweep uses, and
cheap. All the libraries handle this (Box2D bullets, Rapier CCD or ray
casts, Planck bullets). None of them adds anything we would not get from
the collision core we are already writing.

## Headless testability in Vitest

- **Own TS / Planck / Matter**: plain modules, import and run. No setup.
- **Rapier**: the plain package's entry does
  `import * as wasm from "./rapier_wasm2d_bg.wasm"` (from the 0.21.0
  tarball), which needs WASM-ESM support from the test transform. The
  `-compat` builds "embed the `.wasm` file into the `.js` sources encoded
  with base64" ([bindings README][rapier-ts]) and need an awaited
  `RAPIER.init()` ([getting started](https://rapier.rs/docs/user_guides/javascript/getting_started_js)).
  That works in Node, but the compat `.mjs` is about 3.45 MB.
- **box2d3-wasm**: has a NodeJS integration test as its usage example
  ([README][b2wasm]). Threaded "deluxe" needs `SharedArrayBuffer` and
  COOP/COEP headers, so in tests and in the WebView use "compat".

## Performance in an Android WebView

The workload is one ship, perhaps one cargo body, tens to low hundreds of
static segments, and a handful of projectiles. That is far below the
scale where any of these engines differ (Box2D's demos run thousands of
bodies). A brute-force or grid-bucketed segment test in TS is enough.
WASM SIMD is on by default from Chrome 91
([v8.dev](https://v8.dev/features/simd)), but only Rapier's `-simd` and
box2d3's deluxe builds use it, and neither is the deterministic choice.
For us, the cost that matters on Android is **download and parse/compile
size**, not step time. (The workload estimate is our own reasoning;
there is no benchmark for it.)

## Bundle size

Measured from the npm tarballs (`npm pack`, `gzip -9`):

- Rapier2D deterministic 0.21.0: `rapier_wasm2d_bg.wasm` 2,436,321 B raw /
  919,151 B gz, plus about 300 KB of JS glue. 0.21.0 added soft bodies
  with FEM enabled in the npm builds
  ([CHANGELOG 0.21.0][rapier-cl]), which likely explains the size.
- box2d3-wasm 5.2.0: `Box2D.compat.wasm` 417,253 B / 153,120 B gz;
  deluxe 427,805 B / 156,963 B gz.
- Planck 1.5.1: `planck.min.js` 297,211 B / 54,798 B gz.
- Matter.js 0.20.0: `matter.min.js` 83,476 B / 25,784 B gz.
- Phaser Box2D (a JS port of Box2D v3) claims "less than 70KB
  (min+gz)" ([README][phaser-b2]).

## Maintenance health (GitHub API / npm, 2026-10-19)

- **Rapier**: very active. The JS bindings repo `dimforge/rapier.js` is
  **archived** and "MIGRATED TO" the main repo's `bindings/typescript`
  ([repo](https://github.com/dimforge/rapier.js)). There were breaking
  releases on 0.20.0 (2026-08-08) and 0.21.0 (2026-09-24)
  ([CHANGELOG][rapier-cl]). Pre-1.0, Apache-2.0.
- **Box2D (upstream)**: v3.2.0 released 2026-10-19, about 10.4k stars, 7
  open issues ([releases](https://github.com/erincatto/box2d/releases)).
- **box2d3-wasm**: last release 5.2.0 on 2026-02-16, 66 stars. Pinned to
  a Box2D commit from 2025-10-19, so it is behind v3.2.0
  ([repo](https://github.com/Birch-san/box2d3-wasm)). It is a bus-factor
  risk.
- **Planck.js**: 1.5.1 on 2026-10-12, regular commits, MIT, about 5.3k
  stars ([repo](https://github.com/piqnt/planck.js)). It is a Box2D v2
  port (the README says "rewrite of Box2D").
- **Matter.js**: last npm release 0.20.0 on 2024-06-23, though commits
  continue (2026-09-30). 279 open issues, CCD issue still open
  ([repo](https://github.com/liabru/matter-js)).
- **Other current options**: Phaser Box2D (Box2D v3 in JS, MIT, last
  push 2025-04-03, npm 1.1.0 from 2025-01-01)
  ([repo][phaser-b2]). Collision-only libraries such as
  `detect-collisions`/`check2d` (SAT + BVH; npm last modified 2025-10 and
  2025-12) could stand in for our narrow phase, but they give no
  determinism or sweep guarantees beyond what we would write anyway.
  `@box2d/core` (last release 2024-08) and `box2d-wasm` (Box2D v2, 2022)
  look stale.

## Recommendation

1. **Own integrator + own swept collision for M4–M8.** Pieces:
   - Semi-implicit Euler at a fixed 60 Hz, matching Godot's default tick
     (`project.godot` doesn't override it).
   - Terrain as static segment lists. The ship hull is a convex polygon.
   - Swept polygon-vs-segment time of impact, then a slide loop (≤4
     iterations, skin ≈ `safe_margin`), plus a depenetration pass after
     rotation.
   - Deterministic polynomial trig, and no `Math.sin`/`cos`/`asin`/`acos`
     in the sim.

   Crash classification is a pure function of (pre-impact `v`, `n`,
   attitude). Projectiles reuse the segment cast. Verify determinism in
   Vitest with golden replays: hash the state after N ticks of a recorded
   input stream.
2. **Keep the collision core behind a small interface** (`sweep(hull,
   motion) → {toi, normal}`, `raycast`). If needed later, a library can
   sit behind it.
3. **Revisit at M6** only if the cargo design calls for real rigid-body
   tumbling and wall interaction. If so, add
   **`@dimforge/rapier2d-deterministic`**, pinned to an exact version,
   with snapshot-hash tests. It is the only candidate with a stated
   cross-platform determinism guarantee, and it has move-and-slide, ropes
   and CCD. Budget about 0.9 MB gz and expect API churn. Box2D v3 is the
   better engine on paper, but its web builds don't yet carry a verified
   determinism guarantee or a stable character mover. Planck's determinism
   is same-runtime only. Matter lacks CCD.

[planck-lim]: https://github.com/piqnt/planck.js/blob/master/docs/pages/limitations.md
[planck-core]: https://github.com/piqnt/planck.js/blob/master/docs/pages/core-concepts.md
[planck-contacts]: https://github.com/piqnt/planck.js/blob/master/docs/pages/contacts.md
[planck-docs]: https://piqnt.com/planck.js/docs/
[b2-sim]: https://box2d.org/documentation/md_simulation.html
[b2-char]: https://box2d.org/documentation/md_character.html
[b2wasm]: https://github.com/Birch-san/box2d3-wasm/blob/main/box2d3-wasm/README.md
[rapier-ts]: https://github.com/dimforge/rapier/blob/master/bindings/typescript/README.md
[rapier-cl]: https://github.com/dimforge/rapier/blob/master/bindings/typescript/CHANGELOG.md
[rapier-kcc]: https://rapier.rs/docs/user_guides/javascript/character_controller
[rapier-rb]: https://rapier.rs/docs/user_guides/javascript/rigid_bodies
[rapier-adv]: https://rapier.rs/docs/user_guides/javascript/advanced_collision_detection_js
[matter-5]: https://github.com/liabru/matter-js/issues/5
[matter-1174]: https://github.com/liabru/matter-js/issues/1174
[phaser-b2]: https://github.com/phaserjs/phaser-box2d
