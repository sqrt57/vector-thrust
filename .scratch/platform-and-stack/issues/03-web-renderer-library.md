# Web renderer / game library choice

Type: research
Status: resolved
Blocked by: none

## Question

Which rendering/game library suits a portrait 2D vector-style game whose simulation is a separate pure deterministic TS module (the renderer only draws sim state and forwards input)? Compare raw Canvas2D, PixiJS (v8), Phaser (v3/v4), Excalibur, KAPLAY, and any strong current alternative on: fit with a "thin view over an external sim" architecture (vs. owning the game loop/physics), Android WebView performance, multitouch input handling, letterboxed scaling of world + UI together, TS typings quality, bundle size, maintenance health, and LLM familiarity/agent-friendliness (testability, screenshot-ability). End with a recommendation.

## Answer

Findings: [research/web-renderer-library.md](../research/web-renderer-library.md) (also on branch `research/web-renderer-library`).

Recommend **PixiJS v8 (8.22, 2026-10-01) as a renderer only**: our own fixed-timestep loop calls `renderer.render(root)`, the WebGL renderer is pinned with the v8.16+ Canvas2D renderer as fallback, input comes from DOM pointer events tracked per pointer id, and one scaled root container letterboxes world and UI together. Pixi fits because it does not own the loop or bring physics, is written in TS, releases roughly monthly, and has the largest user base plus an `llms.txt` doc index. Runner-up: raw Canvas2D (zero dependencies, most stable headless screenshots). Rejected as full engines that own the loop and duplicate the sim: Phaser 4 (about 369 KB gzipped), Excalibur (cannot tell which finger is which once touches start), KAPLAY (no stable release for 16 months), LittleJS. Bundle sizes are the agent's own esbuild measurements. Open: low-end Android WebView frame times could flip the choice to raw Canvas2D, so measure in the device spike.
