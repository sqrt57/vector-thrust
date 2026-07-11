extends CharacterBody2D

@export var gravity: float = 800.0
@export var thrust_acceleration: float = 1400.0

## Rate-limited turn speed the navigator uses to align toward
## navigator_target, in radians/sec. First-pass value, not yet tuned
## against thrust burst timing (see backlog.md M2).
@export var navigator_turn_rate: float = 3.0

## World-space point the navigator is rotating the vehicle toward. Set by
## tap-to-target input (see main.gd).
var navigator_target: Vector2

## Set by the on-screen thrust button (see thrust_button.gd).
var thrust_button_held: bool = false

func _ready() -> void:
	# Ahead of the vehicle's initial facing, so it doesn't spin at rest
	# before the first tap sets a real target.
	navigator_target = position + Vector2.UP * 100.0

func set_thrust_button_held(value: bool) -> void:
	thrust_button_held = value

func set_navigator_target(target: Vector2) -> void:
	navigator_target = target

func _physics_process(delta: float) -> void:
	var desired_rotation := (navigator_target - position).angle() + PI / 2.0
	var angle_diff := wrapf(desired_rotation - rotation, -PI, PI)
	var max_delta := navigator_turn_rate * delta
	rotation += clamp(angle_diff, -max_delta, max_delta)

	velocity.y += gravity * delta

	if Input.is_key_pressed(KEY_SPACE) or thrust_button_held:
		velocity += Vector2.UP.rotated(rotation) * thrust_acceleration * delta

	move_and_slide()
