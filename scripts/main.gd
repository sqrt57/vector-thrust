extends Node2D

## Bottom edge of the play field in world/screen space (they coincide here
## since the camera sits centered on the full viewport at zoom 1). Must stay
## in sync with the control strip height in main.tscn.
@export var play_field_height: float = 992.0

func _unhandled_input(event: InputEvent) -> void:
	var tap_position: Vector2
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		tap_position = event.position
	elif event is InputEventScreenTouch and event.pressed:
		tap_position = event.position
	else:
		return

	if tap_position.y > play_field_height:
		return

	get_tree().call_group("vehicle", "set_navigator_target", tap_position)
