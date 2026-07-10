extends Button

func _ready() -> void:
	button_down.connect(func(): get_tree().call_group("vehicle", "set_thrust_button_held", true))
	button_up.connect(func(): get_tree().call_group("vehicle", "set_thrust_button_held", false))
