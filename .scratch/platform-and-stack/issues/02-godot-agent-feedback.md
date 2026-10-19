# Godot agent-feedback story

Type: research
Status: resolved
Blocked by: none

## Question

What is the best achievable agent build-and-verify loop for a Godot 4.x (GDScript) 2D mobile game, so the Godot fallback is judged fairly against TypeScript? Cover: headless unit/integration test frameworks (GUT, gdUnit4) and running physics deterministically headless; capturing screenshots/frames headless (`--write-movie`, viewport capture) so an LLM can see output; scripted input injection; GDScript LSP/linting/formatting from the CLI; how well current LLMs know Godot 4.x APIs (vs. Godot 3 drift); a faster Android deploy loop (one-click remote deploy, `adb` scripting, live reload); and Godot's web export as a browser preview target. End with a frank comparison of where Godot's loop stays weaker than a Vite/Vitest/Playwright web loop.

## Answer

Findings: [research/godot-agent-feedback.md](../research/godot-agent-feedback.md) (also on branch `research/godot-agent-feedback`).

Logic and physics tests can run headless: GUT 9.7.1 and gdUnit4 6.2.x both support 4.7, run from the CLI with exit codes and JUnit XML, and `--fixed-fps` decouples frame delta from real time. But `--headless` disables all rendering, and gdUnit4 refuses headless runs by default because injected input is dropped, so screenshots (`--write-movie` PNG sequences or viewport capture) and input-replay tests need a windowed GPU process or a virtual display. gdtoolkit and the GDQuest Rust formatter only parse; real type errors need `--check-only` or the language server, which requires a running Godot instance. The Android loop scripts as CLI export, `adb install -r`, `logcat -s godot` and `screencap`. Several community MCP servers exist, none official and none tested; `satelliteoflove/godot-mcp` is closest to "Playwright for Godot" (time stepping, input injection, JSON state, screenshots). Web export works with the Compatibility renderer and Playwright can drive it, but the agent only sees an opaque canvas. Frank comparison: Godot stays weaker on headless visuals and input, editor-bound live reload, CLI project-wide type checking and LLM fluency (3-to-4 API drift); it is equal or better on built-in fixed-timestep capture and native Android. The determinism and LLM-fluency claims are inference, with no primary source.
