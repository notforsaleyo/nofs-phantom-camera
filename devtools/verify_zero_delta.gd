extends Node

var _checks: int = 0
var _failures: int = 0
var _velocity: float = 7.0


func _ready() -> void:
	var target := Node2D.new()
	add_child(target)
	var camera := PhantomCamera2D.new()
	camera.follow_mode = PhantomCamera2D.FollowMode.GLUED
	camera.follow_target = target
	add_child(camera)
	camera.set_process(false)

	# Inspect the shared damper as well as the public follow output.
	for destination: float in [10.0, 20.0]:
		_velocity = 7.0
		var result: float = camera._smooth_damp(destination, 10.0, 0, _velocity,
			_capture_velocity, 0.1, 0.0)
		_check(result == 10.0 and _velocity == 7.0,
			"zero elapsed time preserves position and velocity")

	for use_lookahead: bool in [false, true]:
		camera.follow_damping = true
		camera.lookahead = use_lookahead
		camera.lookahead_acceleration = 0.1
		camera.lookahead_deceleration = 0.1
		target.position = Vector2(100, 100)
		camera.teleport_position()
		camera.process_logic(0.0)
		_check(camera.get_transform_output().origin.is_equal_approx(target.position),
			"zero-time refresh keeps the teleport position")
		target.position += Vector2(20, 10)
		camera.process_logic(1.0 / 60.0)
		_check(camera.get_transform_output().origin.is_finite(),
			"following after teleport stays finite (lookahead=%s)" % use_lookahead)

	camera.lookahead = false
	camera.follow_damping = false
	camera.process_logic(1.0 / 60.0)
	camera.rotate_with_target = true
	camera.rotation_damping = true
	camera.process_logic(0.0)
	target.rotation += 0.2
	camera.process_logic(1.0 / 60.0)
	_check(is_finite(camera.get_transform_output().get_rotation()),
		"rotation damping after a zero-time refresh stays finite")

	_velocity = 0.0
	var advanced: float = camera._smooth_damp(20.0, 10.0, 0, _velocity,
		_capture_velocity, 0.1, 1.0 / 60.0)
	_check(advanced > 10.0 and advanced < 20.0 and is_finite(_velocity),
		"positive elapsed time still applies damping")
	camera.free()
	target.free()
	print("zero delta: %d checks, %d failures" % [_checks, _failures])
	get_tree().quit(0 if _failures == 0 else 1)


func _capture_velocity(_index: int, value: float) -> void:
	_velocity = value


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		printerr("FAIL: " + message)
