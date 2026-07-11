extends Node2D

## Visual marker for the vehicle's current navigator_target (see
## vehicle.gd), repositioned by main.gd whenever the target changes.

const RADIUS := 12.0
const COLOR := Color(1, 0.8, 0, 1)

func _draw() -> void:
	draw_arc(Vector2.ZERO, RADIUS, 0, TAU, 24, COLOR, 2.0)
	draw_line(Vector2(-RADIUS * 1.5, 0), Vector2(-RADIUS * 0.5, 0), COLOR, 2.0)
	draw_line(Vector2(RADIUS * 0.5, 0), Vector2(RADIUS * 1.5, 0), COLOR, 2.0)
	draw_line(Vector2(0, -RADIUS * 1.5), Vector2(0, -RADIUS * 0.5), COLOR, 2.0)
	draw_line(Vector2(0, RADIUS * 0.5), Vector2(0, RADIUS * 1.5), COLOR, 2.0)
