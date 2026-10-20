# TypeScript in Capacitor as the Android platform

Vector Thrust ships on Android as a single TypeScript codebase wrapped in Capacitor 8 (system WebView), replacing Godot. The deciding factor is how well an agent can build *and verify* the game unattended: the web loop (Vite, Vitest, Playwright, ~0.65 s live reload onto the phone) gives headless visuals, input injection and CLI type checks that Godot's loop lacks, and a real-device spike on the reference phone (Redmi Note 13 Pro) showed the web build feels the same as the Godot APK at 60 fps.

The new TypeScript project is the real game, not a prototype, though we stay willing to throw it away and restart if it goes wrong. Existing prototypes (the Godot M0–M3 code, `prototype-android-spike/`) are throwaway and serve only as reference.

## Considered Options

- **Godot 4 (GDScript)**: native Android and equal feel, but rendering and input tests need a windowed GPU process, type checks need a running editor, live reload is editor-bound, and LLMs drift between Godot 3 and 4 APIs.
- **TWA (Bubblewrap)** instead of Capacitor: kept as the wrapper fallback; needs public HTTPS hosting and gives less native control (the spike already needed native code for system bars and theme).

## Consequences

Reopen the Godot question only if the game shows sustained frame drops on the reference phone at real game load that profiling can't fix.
