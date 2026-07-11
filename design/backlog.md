# Backlog

Milestones are ordered as a walking skeleton: get the smallest playable
slice first (gravity + thrust + navigator feel), then widen to full
control scheme, then content, then meta-progression/combat. Items within a
milestone are roughly execution order, not strict dependencies.

## M0 — Project scaffolding

- [x] Initialize Godot project (`project.godot`) inside the repo. Godot
      4.7 (GDScript, GL Compatibility renderer for broad mobile support).
- [x] Folder structure: `scenes/`, `scripts/`, `assets/`, `levels/`.
- [x] `.gitignore` additions for Godot (`.godot/`, `/android/`,
      `/builds/`). `export_presets.cfg` is committed as-is — its only
      credential is the Android debug keystore password, which is the
      universal, non-secret default (`android`/`androiddebugkey`) shared
      by every Android SDK install; a release keystore, when added later,
      must **not** be committed the same way.
- [x] Mobile export presets set up for Android — JDK 17 (Temurin)
      installed, Godot 4.7 export templates downloaded and installed,
      Android SDK/debug keystore auto-detected via Android Studio.
      Verified end-to-end with a real headless `--export-debug` build
      that produced a signed APK. iOS skipped (no Mac available for
      signing).
- [x] Basic empty scene (`scenes/main.tscn`) that runs on desktop —
      verified both headless and in a real window. Also installed and
      launched on a real Android device (`adb install` + launch);
      confirmed running via `pidof` and logcat showing steady ~59fps
      frame output with no crashes.

## M1 — Core flight physics prototype

- [x] Vehicle node with a rigid body (or custom integrator) affected by
      constant gravity.
- [x] Thrust force applied along the vehicle's current facing direction,
      magnitude controlled by a temporary hardcoded/dev input (e.g.
      keyboard key) — just to validate gravity/thrust/mass feel before any
      UI exists. Verified on a real Android device via a temporary
      on-screen thrust button (pulled forward from M2) since the
      keyboard-only dev input isn't usable on touch.
- [x] Tune gravity strength, thrust magnitude, and vehicle mass/drag to a
      first "feels right" pass. Current values (`gravity=800`,
      `thrust_acceleration=1400`) confirmed to feel right on a real
      device — no further tuning needed for M1.
- [x] Simple fixed camera framing the full playfield (static environment
      — no scroll/follow behavior yet; see
      [environments.md](environments.md)).

## M2 — Navigator & real input

- [x] Tap-on-playing-field input sets a target point (world-space).
      Mouse-click on desktop and touch both handled in `main.gd`,
      restricted to the play-field region above the control strip.
- [x] Navigator auto-rotates the vehicle toward the target at a
      rate-limited turn speed (not instant). `navigator_turn_rate`
      (rad/s) in `vehicle.gd`, not yet tuned — see the open tuning item
      below.
- [x] Fixed thrust button UI, right side of the bottom control strip,
      tap = burst / hold = sustained burn (per
      [control-schemes.md](control-schemes.md)).
- [x] Touch input tested on an actual mobile device or emulator, not just
      desktop mouse emulation — touch behaves differently enough
      (multitouch, button hit-testing, screen size) that desktop-only
      testing risks missing real issues. Verified on a real Android
      device: tap-to-target rotation and thrust-button hold both confirmed
      working via touch, no crashes in logcat.
- [ ] Tune base navigator turn rate against thrust burst timing so the
      "burn early for a curve, wait for alignment for a straight line"
      skill (from control-schemes.md) actually reads as a skill in
      practice.

## M3 — Collision & failure state

- [ ] Terrain/wall collision shapes.
- [ ] Crash detection (e.g. velocity/impact-angle threshold) distinct from
      a soft landing/touch.
- [ ] Restart/reset flow on crash (instant retry, no menu round-trip —
      keep iteration fast for both dev and player).
- [ ] Level boundaries (what happens if the vehicle flies off-screen/off-
      level).

## M4 — First maze level & win condition

- [ ] Hand-built single maze level using placeholder geometry.
- [ ] Checkpoint/exit trigger and win state.
- [ ] Camera framing tuned for maze corridors (static environment — first
      maze fits on one screen, per [environments.md](environments.md);
      zoom to fit, no scroll/lookahead needed yet).
- [ ] First real playtest of the full loop: tap target → burn → navigate
      corridor → reach exit, without any placeholder dev-input shortcuts
      left in from M1.

## M5 — Delivery mode

- [ ] Cargo pickup mechanic (tractor beam/hook, per concept.md).
- [ ] Cargo affects flight (added mass/drag while carrying).
- [ ] Delivery target/drop-off trigger and success/fail conditions (e.g.
      dropped cargo, cargo destroyed on hard impact).

## M6 — Navigator upgrades / meta-progression

- [ ] Persistent save data (upgrade levels, unlocked tiers).
- [ ] "Faster navigator" upgrade tier(s) — higher turn rate.
- [ ] "Smarter navigator" upgrade tier(s) — velocity-aware anti-overshoot
      facing, then (later) obstacle-aware waypoint routing.
- [ ] Basic upgrade/progression screen UI.

## M7 — Weapons & shoot button

- [ ] Shoot button UI, left side of the control strip (opposite thrust,
      per control-schemes.md), placement/behavior (tap-fire vs hold-fire)
      decided and implemented.
- [ ] Projectile/weapon system.
- [ ] Turrets or simple enemy placements as the first combat encounter.
- [ ] Navigator behavior when a target is an enemy vs. a navigation point
      (aim-assist framing from control-schemes.md).

## M8 — Content & polish

- [ ] Additional maze/delivery levels.
- [ ] Real vehicle/environment art (replacing placeholder geometry).
- [ ] Audio: thrust sound, collision/crash, UI feedback, music.
- [ ] Menus: main menu, level select, pause, settings.
- [ ] Tutorial/onboarding for the point-to-navigate scheme (it's not a
      standard control scheme players will already know).

## M9 — Mobile release prep

- [ ] Performance pass on real low/mid-tier Android devices, not just a
      dev machine or emulator.
- [ ] App icon, store screenshots/listing assets.
- [ ] Signed release builds for both platforms targeted.
- [ ] Crash/analytics reporting hook, if wanted, before wide release.

## Not yet scheduled / needs a decision first

- Vehicle types (rocket vs. helicopter handling differences) — depends on
  M1 physics tuning results.
- Physics fidelity (arcade vs. simulation-accurate) — decide during M1
  tuning, not before.
- Scrolling environment support (camera follow, lookahead/deadzone
  tuning, off-screen level state) — deferred until static environments
  are validated through M1–M4; see [environments.md](environments.md).
