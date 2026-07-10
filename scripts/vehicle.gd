extends CharacterBody2D

## M1 prototype only: rotation is driven by dev keys (Left/Right) until the
## navigator (M2) replaces it with tap-to-target auto-rotation.

@export var gravity: float = 800.0
@export var thrust_acceleration: float = 1400.0
@export var dev_rotation_speed: float = 3.0

## Set by the temporary on-screen thrust button (see thrust_button.gd) so the
## dev-input prototype is testable on touch devices, not just keyboard.
var thrust_button_held: bool = false

func set_thrust_button_held(value: bool) -> void:
	thrust_button_held = value

func _physics_process(delta: float) -> void:
	if Input.is_key_pressed(KEY_LEFT):
		rotation -= dev_rotation_speed * delta
	if Input.is_key_pressed(KEY_RIGHT):
		rotation += dev_rotation_speed * delta

	velocity.y += gravity * delta

	if Input.is_key_pressed(KEY_SPACE) or thrust_button_held:
		velocity += Vector2.UP.rotated(rotation) * thrust_acceleration * delta

	move_and_slide()
