# Final Android platform decision

Type: grilling
Status: resolved
Blocked by: 01, 02, 05

## Question

TypeScript in the chosen Android wrapper, or Godot? Weigh the findings from [TypeScript-on-Android runtime options](01-ts-android-runtimes.md) and [Godot agent-feedback story](02-godot-agent-feedback.md) and the verdict from [Real-device spike: web build on Android vs. Godot APK](05-android-device-spike.md). The decision also fixes whether the HTML code is the real game or throwaway prototypes. Record it as an ADR in `docs/adr/`.

## Answer

ADR: [0001 TypeScript in Capacitor as the Android platform](../../../docs/adr/0001-typescript-capacitor-android-platform.md).

**TypeScript in Capacitor 8, final. Godot is dropped.** TWA (Bubblewrap) stays as the wrapper fallback, recorded in a single line. The new TS project is the real game, not a prototype, but it can still be thrown away and restarted if that's ever needed. Existing prototypes (the Godot M0–M3 code, `prototype-android-spike/`) are throwaway and kept only as reference. The reference device for "good enough" is the Redmi Note 13 Pro. Testing on a low-tier phone is deferred to the daily dev loop question. Reversal trigger: sustained frame drops on the reference phone at real game load that profiling can't fix.
