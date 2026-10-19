# Web stack decision: renderer and physics

Type: grilling
Status: open
Blocked by: 03, 04, 05

## Question

Which renderer/game library and which physics/collision approach does the web codebase use, given [Web renderer / game library choice](03-web-renderer-library.md), [Physics & collision approach](04-physics-collision.md), and what [Real-device spike: web build on Android vs. Godot APK](05-android-device-spike.md) exposed? Settle how they sit around the pure deterministic sim module (who owns the game loop, fixed-timestep accumulator, where collision lives). Record it as an ADR in `docs/adr/`.
