extends Node

var _checks: int = 0
var _failures: int = 0
var _target_changes: int = 0


func _ready() -> void:
	var target := Node2D.new()
	add_child(target)
	var camera := PhantomCamera2D.new()
	camera.follow_mode = PhantomCamera2D.FollowMode.GLUED
	camera.follow_target = target
	add_child(camera)
	camera.set_process(false)
	camera.follow_target_changed.connect(_on_target_changed)
	_check(camera.is_following(), "initial target is followed")

	for _cycle: int in 2:
		remove_child(target)
		_check(not camera.is_following(), "target exit stops following")
		add_child(target)
		target.position += Vector2(50, 20)
		camera.follow_target = target
		_check(camera.is_following(), "same target resumes following after reentry")
		camera.process_logic(1.0 / 60.0)
		_check(camera.get_transform_output().origin.is_equal_approx(target.global_position),
			"resumed following reaches the moved target")
	_check(_target_changes == 0, "same target does not emit a target change")

	camera.follow_mode = PhantomCamera2D.FollowMode.PATH
	camera.follow_target = target
	_check(not camera.is_following(), "PATH without a path cannot resume following")
	camera.follow_mode = PhantomCamera2D.FollowMode.NONE
	camera.follow_target = target
	_check(not camera.is_following(), "fixed camera does not start following")
	camera.follow_mode = PhantomCamera2D.FollowMode.GLUED
	camera.follow_target = null
	camera.follow_target = null
	_check(not camera.is_following(), "repeated null target stays inactive")
	camera.free()
	target.free()
	print("follow target reentry: %d checks, %d failures" % [_checks, _failures])
	get_tree().quit(0 if _failures == 0 else 1)


func _on_target_changed() -> void:
	_target_changes += 1


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		printerr("FAIL: " + message)
