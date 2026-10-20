# Sim module conventions

Type: grilling
Status: open
Blocked by: 07

## Question

Given the split in [Web stack decision: renderer and physics](07-web-stack-decision.md) (pure 60 Hz sim owns geometry and contacts, our own loop, Pixi as a read-only view), what are the sim module's conventions? Decide its public interface (create/step/read state), how input reaches it each tick (DOM pointer events for the tap target and held thrust, sampled into a per-tick input record), how levels are loaded into it, how agents assert on trajectories and contacts in Vitest (scripted input sequences, golden trajectories, tolerances), and the conventions for visual/screenshot checks of the rendered view in Playwright.
