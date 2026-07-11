extends CharacterBody2D

@export var gravity: float = 800.0
@export var thrust_acceleration: float = 1400.0

## Rate-limited turn speed the navigator uses to align toward the desired
## facing computed each tick (see _desired_rotation), in radians/sec.
## Tuned against thrust burst timing in M2 (see backlog.md); unaffected
## by the M3 targeting model below.
@export var navigator_turn_rate: float = 3.0

## Minimum vertical-thrust margin over gravity the navigator will reserve
## when leaning the ship sideways for horizontal acceleration, as a
## multiple of gravity (1.2 = held thrust must still net at least
## 0.2*gravity of upward acceleration). Bounds how far off vertical the
## navigator will ever aim, regardless of how urgently it wants
## horizontal thrust (see backlog.md M3).
@export var navigator_min_climb_ratio: float = 1.2

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

## Desired facing angle (radians, 0 = straight up) that gives held thrust
## an accelerate-then-decelerate horizontal profile toward
## navigator_target: burn toward the target while stopping distance at
## the current horizontal speed is less than the remaining horizontal
## gap, then flip to braking once it isn't. Tilt is capped so held
## thrust always keeps navigator_min_climb_ratio worth of vertical
## climb, however urgent the horizontal need. Vertical distance to the
## target isn't considered — when to burn vertically is left to the
## player's thrust hold, per control-schemes.md.
func _desired_rotation() -> float:
	var max_tilt := acos(clamp(gravity * navigator_min_climb_ratio / thrust_acceleration, -1.0, 1.0))
	var horizontal_max_accel := thrust_acceleration * sin(max_tilt)
	if horizontal_max_accel <= 0.0:
		return 0.0

	var dx := navigator_target.x - position.x
	var vx := velocity.x
	var stopping_distance := (vx * vx) / (2.0 * horizontal_max_accel)
	var approaching := dx * vx > 0.0

	var ax_desired := 0.0
	if approaching and stopping_distance >= absf(dx):
		ax_desired = -sign(vx) * horizontal_max_accel
	elif dx != 0.0:
		ax_desired = sign(dx) * horizontal_max_accel
	else:
		ax_desired = -sign(vx) * horizontal_max_accel

	return asin(clamp(ax_desired / thrust_acceleration, -1.0, 1.0))

func _physics_process(delta: float) -> void:
	var desired_rotation := _desired_rotation()
	var angle_diff := wrapf(desired_rotation - rotation, -PI, PI)
	var max_delta := navigator_turn_rate * delta
	rotation += clamp(angle_diff, -max_delta, max_delta)

	velocity.y += gravity * delta

	if Input.is_key_pressed(KEY_SPACE) or thrust_button_held:
		velocity += Vector2.UP.rotated(rotation) * thrust_acceleration * delta

	move_and_slide()
