# Level Environments

## Two environment types

- **Static** — the level fits entirely within one screen/viewport. No
  camera movement: a fixed camera frames the whole playfield at a
  constant zoom for the level's duration.
- **Scrolling** — the level extends beyond the viewport. The camera
  follows the vehicle (with lookahead/framing as needed) as it moves
  through a space larger than one screen.

## Decision

**Start with static environments only.** Scrolling is a real environment
type the game will eventually need (larger mazes, longer delivery runs),
but it's deferred until the static case is working end to end.

Why: static levels are simpler to build and tune first — no
camera-follow logic, no off-screen vehicle/level state, no need to decide
lookahead/deadzone behavior — so the core gravity/thrust/navigator loop
can be validated (M1–M4) before scrolling adds its own complexity on top.

## Implications for the backlog

- **M1 camera** simplifies to a fixed camera framing the full static
  playfield — no follow behavior needed yet.
- **Level data should carry size as a property of the level**, not hardcode
  an engine-wide assumption — so a given level declares whether it fits
  on one screen (static) or is larger (scrolling), and scrolling support
  can be added later without reworking static levels.
- **M4's first maze level** should be built to fit on one screen (static).
- Scrolling camera support (follow, lookahead, deadzone tuning) is
  deferred to a later milestone, once static levels are validated.

## Open questions

- Exact criteria for "fits on screen" across different device aspect
  ratios/orientations (does static mean "fits on the smallest supported
  screen" or does the camera zoom to fit per-device?).
- When scrolling is added, whether it's a per-level toggle or a separate
  camera component swapped in based on level size.
