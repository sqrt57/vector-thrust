# Godot Engine Gotchas

Non-obvious Godot 4 behavior discovered while working on this project.
Recorded here so we don't re-debug the same thing twice.

## Android screen orientation is an int enum, not a string

The project setting `display/window/handheld/orientation` (in
`project.godot`) is an **integer enum**:

```
0 = Landscape
1 = Portrait
2 = Reverse Landscape
3 = Reverse Portrait
4 = Sensor Landscape
5 = Sensor Portrait
6 = Sensor
```

Writing it as a string (e.g. `window/handheld/orientation="portrait"`)
doesn't error at load time — Godot's Android export plugin does
`int(get_project_setting(...))` when building the manifest, and
`int("portrait")` silently parses to `0` (Landscape). The exported
`AndroidManifest.xml`'s `android:screenOrientation` ends up wrong with no
warning anywhere. Always set this key as a bare integer.

## CanvasLayer/Control UI needs matching stretch mode to align with the viewport

With the default stretch mode (`display/window/stretch/mode = "disabled"`),
the base viewport renders at its native/design size, centered inside a
larger physical window — but `CanvasLayer`/`Control` nodes anchor to the
*actual window size*, not the centered viewport. Anchored UI (e.g. a
bottom-right button) ends up positioned relative to the full physical
screen, landing outside the visible, letterboxed game area.

Fix: set both

```
window/stretch/mode="canvas_items"
window/stretch/aspect="keep"
```

so the whole 2D canvas (world + UI) scales and letterboxes together as one
unit, keeping anchored UI aligned with the design-resolution playfield.
