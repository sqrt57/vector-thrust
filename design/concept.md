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
- **Orientation control**: player rotates the vehicle (touch drag, tilt, or
  twin virtual sticks — TBD).
- **Throttle control**: player applies thrust along the vehicle's current
  facing direction; thrust magnitude is adjustable, not just on/off.
- **Momentum-based flight**: no auto-leveling or assisted stabilization by
  default — the challenge is mastering inertia against gravity, similar to
  lunar-lander physics.
- **Collision**: touching walls/terrain at speed is penalized or fatal;
  precision maneuvering is the skill being tested.

## Modes (candidates)

- **Maze navigation**: reach an exit/checkpoint through a constrained 2D
  layout.
- **Delivery**: pick up cargo (e.g. via tractor beam / hook, similar to
  *Thrust*) and ferry it to a destination without crashing or dropping it.
- **Combat (stretch goal)**: weapons for offense/defense against turrets,
  obstacles, or other vehicles.

## Platform

- Mobile-first. Touch input is the primary interaction model.
- Needs a control scheme that maps rotation + throttle to touch cleanly
  (e.g. tilt-based rotation, on-screen thrust button; or dual virtual
  joysticks; or drag-to-aim + thrust slider). To be prototyped and compared.

## Open questions

- Engine/tech stack (native mobile, Unity, Godot, web/HTML5 + wrapper, etc.)
- Control scheme (tilt vs. touch joystick vs. drag-to-aim)
- Physics model fidelity (arcade-y vs. more simulation-accurate)
- Vehicle types and how they differ (rocket vs. helicopter handling)
- Cargo/tractor-beam mechanic details, if adopted
- Weapon system scope, if adopted
- Level format and editor/tooling for maze design
