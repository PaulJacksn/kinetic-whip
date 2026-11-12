extends Node2D
## Chain-feel verification for the reworked whip. Measures the physics,
## not just the math: spin, extension vs spin, tip speed vs hand speed
## (whip crack), lag angle (trail, not rigid rotation), collapse when
## spin dies, and weight on direction reversal.
## Run: godot --headless --path . test_chain.tscn

const MainScene = preload("res://main.tscn")
const CORE := Vector2(360, 640)

var _main: Node2D
var _step: int = 0
var _frames: int = 0
var _results: Array = []
var _tip_full: float = 0.0
var _anchor_tangential: float = 0.0

func _ready() -> void:
	_main = MainScene.instantiate()
	add_child(_main)
	print("[CHAIN] starting")

func _check(name: String, ok: bool, detail: String = "") -> void:
	_results.append([name, ok, detail])
	print("[CHAIN] %s: %s %s" % [name, "PASS" if ok else "FAIL", detail])

func _mid_angle() -> float:
	var w = _main._whip
	var pts: Array = w._points
	var mid: Vector2 = pts[pts.size() / 2]
	return (mid - CORE).angle()

func _tip_angle() -> float:
	return (_main._whip.tip_pos() - CORE).angle()

func _lag() -> float:
	return wrapf(_main._whip.anchor_angle - _mid_angle(), -PI, PI)

func _physics_process(_delta: float) -> void:
	_frames += 1
	match _step:
		0:
			if _frames >= 5:
				_main.start_game()
				_step = 1
				_frames = 0
		1:
			# Drive at constant +9 rad/s for 120 frames (steady state).
			_main._pointer_angle += 0.15
			_main._dragging = true
			if _frames >= 120:
				_main._dragging = false
				var w = _main._whip
				_tip_full = w.tip_pos().distance_to(CORE)
				_anchor_tangential = w.orbit_radius() * absf(w.angular_vel)
				var tip_speed: float = w.tip_speed()
				var lag := _lag()
				_check("spin_full", w.spin_ratio > 0.9, "spin=%.2f" % w.spin_ratio)
				_check("extension_full", _tip_full > 300.0, "tip_dist=%.0f" % _tip_full)
				_check("tip_faster_than_hand", tip_speed > _anchor_tangential * 1.15, "tip=%.0f hand=%.0f" % [tip_speed, _anchor_tangential])
				_check("chain_lags_not_rigid", absf(lag) > 0.15, "lag=%.2f rad (%.0f deg)" % [lag, rad_to_deg(lag)])
				_step = 2
				_frames = 0
		2:
			# Let spin die for 150 frames: chain must collapse, smoothly.
			if _frames >= 150:
				var w = _main._whip
				var tip_d: float = w.tip_pos().distance_to(CORE)
				_check("spin_dies", w.spin_ratio < 0.15, "spin=%.2f" % w.spin_ratio)
				_check("chain_collapses", tip_d < _tip_full - 60.0 and tip_d < 280.0, "tip_dist=%.0f was %.0f" % [tip_d, _tip_full])
				_step = 3
				_frames = 0
		3:
			# Reverse direction hard: the chain must NOT track instantly.
			# After 15 frames of reversed driving, the tip is still trailing
			# the old way (weight), not glued to the anchor.
			_main._pointer_angle -= 0.15
			_main._dragging = true
			if _frames >= 15:
				var lag := wrapf(_main._whip.anchor_angle - _tip_angle(), -PI, PI)
				_check("reversal_weight", absf(lag) > 0.25, "tip_lag=%.2f rad (%.0f deg)" % [lag, rad_to_deg(lag)])
				_main._dragging = false
				_finish()

func _finish() -> void:
	var fails := 0
	for r in _results:
		if not r[1]:
			fails += 1
	print("[CHAIN] DONE: %d/%d passed, %d failed" % [_results.size() - fails, _results.size(), fails])
	get_tree().quit(1 if fails > 0 else 0)
