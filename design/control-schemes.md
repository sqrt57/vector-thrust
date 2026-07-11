# Control Schemes

## Problem

Core flight model needs two simultaneous, continuous inputs at all times:

1. **Orientation** — rotate the vehicle (as a rate/torque, or possibly set
   directly).
2. **Throttle** — thrust magnitude along the vehicle's current facing.

Unlike a twin-stick shooter, both inputs are needed *constantly* during
flight, not intermittently — so the scheme has to keep both reachable by
thumbs at all times on a phone screen, without occluding the play area more
than necessary.

## Key design dimensions

- **Relative vs. absolute rotation** — does input apply a turn rate/torque
  (relative, momentum-preserving, closer to the original *Thrust*/*Lunar
  Lander* skill of fighting inertia), or does it snap the vehicle to point
  wherever the input indicates (absolute, easier, but removes some of the
  "fighting rotational momentum" challenge)? This is the single biggest
  fork — most of the variants below are really "how do I express relative
  rotation, absolute rotation, or throttle" in different input widgets.
- **Binary vs. analog throttle** — on/off thrust vs. variable magnitude.
  Analog throttle adds a real skill dimension (soft corrections vs. full
  burns) but is harder to hit precisely on touch.
- **One-handed vs. two-handed** — mobile-first favors thumb-reachable
  controls; two-handed (landscape, both thumbs) is more common for this
  genre than one-handed.
- **Touch-only vs. device tilt** — tilt frees up a finger/thumb but requires
  the phone to be held in the air and calibrated, and fights with any
  simultaneous on-screen tapping.

## What existing games do

- **Thrust remakes (e.g. *Thrust 30*)** — direct port of the arcade scheme:
  discrete on-screen buttons for rotate-left, rotate-right, thrust, and
  fire. Relative rotation (turn rate), binary thrust. Simple to implement,
  proven for the genre, but buttons are static targets that partially
  occlude the screen and give no analog throttle feel.
- **Lunar Lander mobile ports** — a mix of approaches across different
  apps: (a) on-screen left/right + thrust buttons, same as Thrust; (b) tilt
  the device left/right for side thrusters and tilt back for the main
  thruster; (c) touch anywhere to thrust while dragging left/right to
  rotate; (d) on some hardware, press-harder-for-more-thrust via pressure-
  sensitive touch (3D Touch), which is not portable across today's
  Android/iOS devices and not a viable cross-platform baseline.
- **"Helicopter Game" / *Flappy Bird* style one-button flight** — hold
  anywhere = thrust up, release = fall; gravity always pulls down; the
  vehicle doesn't rotate at all (or auto-orients to velocity). Removes
  orientation control entirely. Not sufficient for our core loop (which
  explicitly wants orientation as a player skill), but worth noting as the
  degenerate/simplified end of the spectrum — could inform an "easy mode"
  or tutorial step.
- **Twin-stick shooters (e.g. mobile ports of *Geometry Wars*-likes)** —
  left virtual joystick for movement, right for aim/fire. Adapted to our
  game, one stick's angle could set orientation directly (absolute) while
  push distance sets throttle — trading the "fighting momentum" feel for
  immediacy.

## Candidate variants for Vector Thrust

1. **Two rotate buttons + separate throttle** (arcade-authentic)
   On-screen ⟲ / ⟳ buttons (relative rotation, hold to keep turning) plus a
   thrust button — binary or a vertical thrust slider for analog magnitude.
   - Pros: proven, easy to build, precise, no ambiguity.
   - Cons: buttons are dead screen space; binary-thrust version loses
     analog feel; discrete rotation can feel stiff on touch vs. keys.

2. **Dual virtual joysticks** — left stick: push up/down = throttle
   magnitude (or push in any direction but only vertical component is
   read); right stick: horizontal deflection = turn rate (relative), or
   stick angle = absolute facing.
   - Pros: both inputs analog and simultaneously available; familiar
     twin-stick muscle memory for mobile gamers.
   - Cons: two sticks eat significant screen real estate on a phone;
     mapping a 2D stick to a 1D throttle feels unnatural (wrong shape for
     the intent).

3. **Drag-to-rotate + tap/hold-to-thrust** — one thumb drags
   left/right anywhere on screen to set turn rate (or absolute angle);
   other thumb taps/holds for thrust, hold-duration or a small vertical
   drag sets magnitude.
   - Pros: no fixed buttons, full screen stays visible as play area;
     scales well to different hand sizes/screen sizes.
   - Cons: absolute-drag-to-rotate removes rotational-momentum challenge
     unless deliberately dampened; relative-drag-to-rotate needs a clear
     "drag speed = turn rate" mapping that's discoverable without a
     tutorial.

4. **Tilt-to-rotate + tap/hold-to-thrust** — accelerometer tilt maps to
   turn rate or bank angle; one thumb/tap for thrust magnitude (hold
   duration or a vertical slider).
   - Pros: frees a full thumb for throttle control; physical tilt matches
     the "banking a vehicle" fantasy well for rocket/helicopter framing.
   - Cons: requires the phone held in the air, awkward on a train/couch;
     needs per-session calibration (rest angle); less precise for tight
     maze corridors than direct touch; harder to pause/rest mid-level.

5. **Simplified one-button** (thrust-only, no player rotation; vehicle
   auto-orients to velocity or stays level) — the *Flappy Bird*/helicopter-
   game degenerate case.
   - Pros: trivial to learn, one-thumb, great for a tutorial or an "easy"
     difficulty tier.
   - Cons: drops orientation control, which is the core mechanic — not
     viable as the primary scheme for this game.

6. **Point-to-navigate + thrust-only** (proposed) — player taps a point in
   the world to set a target; an in-fiction "navigator" auto-rotates the
   vehicle toward it over time (not instantly); the player's only direct
   input is thrust (tap for a burst, hold for sustained burn). Rotation is
   delegated, not removed — it still has a rate limit and momentum, so
   there's a real skill in choosing *when* to burn relative to how far the
   navigator has turned (burn early for a diagonal/curved shot, wait for
   full alignment for a straight burn). This reframes the game's core skill
   from "manual rotation + throttle" to "target placement + burn timing",
   with rotation performance itself becoming an upgradeable stat.
   - **Input disambiguation**: split by screen zone rather than gesture
     timing — a fixed thrust control (button in the bottom control strip)
     stays separate from the play-area tap-to-target zone, using
     multitouch so both can be active at once (one thumb resting on
     thrust, the other tapping targets). This avoids the latency a
     tap-vs-hold timing heuristic would add on the thrust input, which is
     the one input where responsiveness matters most.
   - **Upgrade hook**: navigator quality becomes a natural, legible
     progression axis —
     - *faster navigator*: higher max rotation rate/torque, so it aligns
       to a new target sooner;
     - *smarter navigator*: better prediction — leads a moving target,
       accounts for the vehicle's current velocity to pick a facing that
       avoids overshoot rather than just pointing at the raw target, or
       (advanced tier) picks a facing/waypoint that routes around known
       obstacles instead of aiming straight through a wall.
     This gives upgrades a directly-felt gameplay effect (visibly faster/
     smarter turning) rather than an abstract stat, and fits an
     RPG-lite/meta-progression layer cleanly.
   - Pros: one-thumb-friendly (or fixed-button + tap, very low input
     complexity), strong and legible upgrade path, still preserves a real
     timing-skill challenge despite removing manual rotation, plays well
     for "delivery" mode (tap destination, manage burns) and could extend
     to weapons later (tap enemy = navigator aims, player times fire).
   - Cons: **conflicts with the concept doc's current core-mechanics line
     that rules out auto-leveling/assisted stabilization** — this is a
     deliberate pivot, not a variant of manual rotation, and should be a
     conscious call, not a side effect of solving the input-ambiguity
     problem. Also changes maze navigation feel: precise micro-corrections
     (e.g. threading a needle-width gap) are harder when rotation isn't
     directly commanded, so maze difficulty/geometry may need to be tuned
     around navigator turn rate rather than player reflexes.

## Decision

**Variant 6 (point-to-navigate + thrust-only) is the chosen scheme**,
concretely laid out as:

- **Thrust**: fixed button, right side of the bottom control strip (see
  Screen layout below). Tap for a burst, hold for sustained burn.
- **Navigation target**: tapping anywhere on the playing field sets the
  navigator's target point; the vehicle auto-rotates toward it over time
  (rate-limited, not instant — see variant 6 above for why this preserves
  a timing-skill challenge).
- **Shoot** (later, once weapons are added): a second fixed button. Exact
  position TBD, but follows the same control-strip pattern as thrust so
  it doesn't compete with the tap-to-target play area — likely the left
  side of the strip, to keep the two buttons thumb-reachable on opposite
  sides.

This resolves the tap-vs-tap ambiguity by screen zone (per the analysis
above): the play area is exclusively for setting targets, and all direct
action buttons live in the bottom control strip (see Screen layout
below).

**Orientation: portrait.** Matches the M1 prototype's existing portrait
layout and borders.

## Screen layout

The screen splits into two fixed vertical regions rather than floating
buttons on top of the play field:

- **Play field** — most of the screen (top region). Tap-to-target input
  only applies here.
- **Control strip** — a fixed-height band across the bottom of the
  screen, reserved for buttons. Keeps buttons off the play area entirely
  instead of overlaying a screen corner.

Current buttons in the control strip: **thrust**, on the right side.
(Shoot, once weapons are added, is expected on the left side of the same
strip — see below.)

This also settles the core-skill pivot flagged earlier: rotation is
delegated to the navigator by design, so `concept.md`'s "no auto-leveling
or assisted stabilization" line is now outdated and should be revised to
describe navigator-assisted rotation instead of ruling it out.

Variants 1–5 are superseded as the primary scheme; variant 1 (buttons)
remains worth keeping in mind only if a manual-override/accessibility mode
is ever wanted later.

## Desktop & web controls

Mobile-first, but Godot exports to desktop and web (HTML5) essentially for
free, so it's worth locking the mouse/keyboard mapping now rather than
leaving it implicit. Desktop and web share one scheme (no reason to treat
them separately — both are mouse + keyboard):

- **Navigation target**: left-click anywhere on the playing field sets the
  navigator's target, same as mobile tap. Same zone rule applies — clicks
  inside the thrust (or later shoot) button's UI bounds are consumed by
  the button, not the playfield.
- **Thrust**: the same on-screen control-strip button is present and
  mouse-clickable (click/hold with the mouse works exactly like a touch
  hold), **plus** Space bar as a keyboard equivalent — press for a burst,
  hold for sustained burn. Both drive the same underlying "thrust active"
  input action, so they're interchangeable, not two separate behaviors to
  maintain.
- Mouse and keyboard are independent input channels, so — unlike mobile,
  which needed multitouch to click-target and hold-thrust
  simultaneously — desktop gets that concurrency for free: click to
  retarget while Space is held down works without any special handling.
- **Shoot** (later): expect the same pattern — on-screen button stays
  mouse-clickable, plus a keyboard equivalent (exact key TBD, e.g. Ctrl or
  a mouse right-click) chosen once the weapon system is designed.

## Open questions

- Exact navigator turn-rate (base, pre-upgrade) and how thrust timing
  relative to rotation progress affects trajectory — needs in-engine
  tuning.
- Shoot button's exact placement and whether it's a tap-fire or hold-fire
  action once weapons are designed, and its desktop keyboard/mouse
  equivalent.
- Exact height of the control strip, and how the buttons within it sit
  relative to screen edges/safe areas across device sizes.
- Navigator turn-rate/smartness curve across upgrade tiers, and how
  "smart" (predictive/obstacle-aware) the top tier gets before it starts
  trivializing maze mode.
- Whether a manual-rotation override or alternate control scheme is ever
  offered as a settings option, or whether point-to-navigate is the only
  scheme for v1.

## Sources

- [Thrust 30 by hayesmaker64 - Itch.io](https://hayesmaker64.itch.io/thrust-30)
- [Thrust (video game) - Wikipedia](https://en.wikipedia.org/wiki/Thrust_(video_game))
- [Moon Lander Lunar Lander - App Store - Apple](https://apps.apple.com/us/app/moon-lander-lunar-lander/id1347278168)
- [LunarLander! | Classic Retro Space Simulation](https://spark.mwm.ai/us/apps/lunarlander/6593668928)
