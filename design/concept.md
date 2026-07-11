# Vector Thrust — Concept

## Pitch

Mobile-first 2D side-view game. The player pilots a flying vehicle (rocket,
helicopter, thruster-pod, etc.) through gravity-affected flight: gravity
constantly pulls the vehicle down, and the player controls orientation
(rotation) and throttle (thrust magnitude) to move around. Core loop is
navigating tight spaces (mazes, caves, corridors) and/or delivering cargo to
target locations, similar in feel to *Thrust* (1986) / *Gravity Force* /
*Lunar Lander* style games, but built fresh for touch controls.

## Core mechanics

- **Gravity**: constant downward force on the vehicle at all times.
- **Orientation control**: delegated to an in-fiction "navigator" — the
  player taps a point on the playing field to set a target, and the
  vehicle auto-rotates toward it at a rate-limited (not instant) turn
  speed. The player does not directly command rotation; navigator turn
  rate/quality is an upgradeable stat (see
  [control-schemes.md](control-schemes.md)).
- **Throttle control**: player applies thrust along the vehicle's current
  facing direction via a fixed thrust button (right side of the bottom
  control strip); tap for a burst, hold for a sustained burn.
- **Momentum-based flight**: the vehicle still has real inertia and a
  rate-limited turn — the skill is timing thrust bursts against how far
  the navigator has rotated (burn early for a curved shot, wait for full
  alignment for a straight one), not manual stick-and-rudder control.
- **Collision**: touching walls/terrain at speed is penalized or fatal;
  precision maneuvering (via target placement + burn timing) is the skill
  being tested.

## Modes (candidates)

- **Maze navigation**: reach an exit/checkpoint through a constrained 2D
  layout.
- **Delivery**: pick up cargo (e.g. via tractor beam / hook, similar to
  *Thrust*) and ferry it to a destination without crashing or dropping it.
- **Combat (stretch goal)**: weapons for offense/defense against turrets,
  obstacles, or other vehicles.

## Platform

- Mobile-first. Touch input is the primary interaction model.
- Control scheme: tap-to-set-navigator-target on the playing field, plus a
  fixed thrust button (right side of the bottom control strip). A shoot
  button will be added on the left side of the same strip once weapons
  are implemented. Desktop and web builds share the same scheme via mouse
  (click-to-target, click-to-thrust) plus Space bar as a keyboard
  equivalent for thrust. See
  [control-schemes.md](control-schemes.md) for the full analysis.

## Tech stack

- **Engine: Godot** (GDScript, built-in 2D physics). Chosen for genuine 2D
  physics support well-suited to gravity/thrust movement, text-based scene
  files, and native mobile export (iOS/Android).

## Open questions

- Physics model fidelity (arcade-y vs. more simulation-accurate)
- Navigator turn-rate/smartness upgrade curve — see
  [control-schemes.md](control-schemes.md) open questions.
- Vehicle types and how they differ (rocket vs. helicopter handling)
- Cargo/tractor-beam mechanic details, if adopted
- Weapon system scope and shoot-button behavior, once adopted
- Level format and editor/tooling for maze design
