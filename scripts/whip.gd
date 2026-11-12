extends Node2D
## Chained Blade: multi-link physics chain on a verlet integrator.
## The anchor orbits the core; the player drags to set the orbit angle.
## Spin builds centrifugal force, which straightens the chain radially
## outward. Damage scales with the blade-tip speed and the spin ratio.
## Reference approach: pin first point to the anchor, integrate points
## with verlet, relax distance constraints several times per frame.

const BASE_LINKS := 12
const SEG_LEN := 16.0
const BASE_ORBIT := 150.0
const ORBIT_GROW := 45.0
const CENTRIFUGAL := 2600.0
const DAMPING := 0.982
const RELAX_ITERS := 4

var core_pos: Vector2 = Vector2(360, 640)
var link_count: int = BASE_LINKS
var damage_mult: float = 1.0
var max_ang_vel: float = 9.0
var anchor_angle: float = -PI * 0.5
var angular_vel: float = 0.0
var spin_ratio: float = 0.0
var visible_weapon: bool = true
var sim_active: bool = true

var _points: Array[Vector2] = []
var _prev: Array[Vector2] = []
var _last_angle: float = -PI * 0.5
var _angle_init: bool = false
var _time: float = 0.0

func _ready() -> void:
	_rebuild_chain()

func _rebuild_chain() -> void:
	_points.clear()
	_prev.clear()
	var a := anchor_angle
	for i in link_count + 1:
		var p := _anchor_pos(a) + Vector2(cos(a + PI * 0.5), sin(a + PI * 0.5)) * float(i) * SEG_LEN * 0.4
		_points.append(p)
		_prev.append(p)

func set_link_count(n: int) -> void:
	link_count = n
	_rebuild_chain()

func orbit_radius() -> float:
	return BASE_ORBIT + spin_ratio * ORBIT_GROW

func _anchor_pos(a: float) -> Vector2:
	return core_pos + Vector2(cos(a), sin(a)) * orbit_radius()

func anchor_pos() -> Vector2:
	return _anchor_pos(anchor_angle)

func tip_pos() -> Vector2:
	return _points[_points.size() - 1]

func tip_speed() -> float:
	var last := _points.size() - 1
	return _points[last].distance_to(_prev[last]) / maxf(get_physics_process_delta_time(), 0.001)

func spin_percent() -> float:
	return spin_ratio * 100.0

func update_spin(target_angle: float, dragging: bool, delta: float) -> void:
	if not _angle_init:
		_last_angle = target_angle
		_angle_init = true
	var d := wrapf(target_angle - _last_angle, -PI, PI)
	_last_angle = target_angle
	if dragging:
		var inst := d / maxf(delta, 0.001)
		angular_vel = lerpf(angular_vel, inst, 1.0 - exp(-14.0 * delta))
		anchor_angle = target_angle
	else:
		angular_vel = lerpf(angular_vel, 0.0, 1.0 - exp(-1.6 * delta))
		anchor_angle += angular_vel * delta
	spin_ratio = clampf(absf(angular_vel) / max_ang_vel, 0.0, 1.0)

func _physics_process(delta: float) -> void:
	_time += delta
	if _points.is_empty():
		return
	if not sim_active:
		queue_redraw()
		return
	var anchor := _anchor_pos(anchor_angle)
	var spin2 := angular_vel * angular_vel
	# Verlet integration with centrifugal force away from the core
	for i in range(1, _points.size()):
		var p := _points[i]
		var vel := (p - _prev[i]) * DAMPING
		_prev[i] = p
		var dir_out := (p - core_pos).normalized()
		var acc := dir_out * spin2 * CENTRIFUGAL * 0.0012
		# Slight pull back toward the anchor so the chain never flies off
		acc += (anchor - p).normalized() * 18.0
		_points[i] = p + vel + acc * delta * delta * 60.0
	# Pin the first point to the anchor
	_points[0] = anchor
	_prev[0] = anchor
	# Relax distance constraints
	for _it in RELAX_ITERS:
		_points[0] = anchor
		for i in range(_points.size() - 1):
			var a := _points[i]
			var b := _points[i + 1]
			var d := b - a
			var dist := d.length()
			if dist < 0.001:
				continue
			var diff := (dist - SEG_LEN) / dist
			if i == 0:
				_points[i + 1] = b - d * diff
			else:
				_points[i] = a + d * diff * 0.5
				_points[i + 1] = b - d * diff * 0.5
	queue_redraw()

## Collision samples: blade tip (strong) plus every second link.
## Each sample carries its motion direction (the hit direction).
func hit_samples() -> Array:
	var out: Array = []
	var n := _points.size()
	for i in range(1, n, 2):
		var speed := _points[i].distance_to(_prev[i]) / maxf(get_physics_process_delta_time(), 0.001)
		var dir := _points[i] - _prev[i]
		if dir.length() < 0.5:
			dir = (_points[i] - core_pos).normalized()
		else:
			dir = dir.normalized()
		out.append({"pos": _points[i], "speed": speed, "tip": i == n - 1, "dir": dir})
	return out

func _draw() -> void:
	if not visible_weapon or _points.size() < 2:
		return
	var cond := 1.0
	if get_parent() != null and get_parent().has_method("weapon_condition"):
		cond = get_parent().weapon_condition()
	var flicker := 1.0
	if cond < 0.3 and int(_time * 10.0) % 3 == 0:
		flicker = 0.45
	var base_col := Color(0.35, 0.95, 1.0).lerp(Color(0.6, 0.6, 0.6), 1.0 - cond)
	# Chain: tapered polyline with glow underlay
	for pass_i in 2:
		var w := 7.0 if pass_i == 0 else 3.0
		var col := base_col
		col.a = (0.25 if pass_i == 0 else 0.95) * flicker
		for i in range(_points.size() - 1):
			var t := float(i) / float(_points.size() - 1)
			var ww := w * (1.0 - t * 0.45)
			draw_line(_points[i], _points[i + 1], col, ww, true)
	# Links as small rings
	for i in range(1, _points.size() - 1, 2):
		draw_arc(_points[i], 4.5, 0.0, TAU, 10, Color(base_col, 0.8 * flicker), 1.5)
	# Blade at the tip, oriented along the last segment
	var last := _points.size() - 1
	var dir := (_points[last] - _points[last - 1]).normalized()
	var perp := Vector2(-dir.y, dir.x)
	var tip := _points[last]
	var blade_col := Color(0.9, 1.0, 1.0).lerp(Color(0.7, 0.55, 0.5), 1.0 - cond)
	var poly := PackedVector2Array([
		tip + dir * 26.0,
		tip - dir * 6.0 + perp * 9.0,
		tip - dir * 12.0,
		tip - dir * 6.0 - perp * 9.0,
	])
	draw_colored_polygon(poly, Color(blade_col, 0.95 * flicker))
	draw_polyline(PackedVector2Array([poly[0], poly[1], poly[2], poly[3], poly[0]]), Color(0.4, 0.9, 1.0, 0.8 * flicker), 1.5)
	# Spin-speed glow at the tip
	var glow_a := 0.25 + spin_ratio * 0.5
	draw_circle(tip, 14.0 + spin_ratio * 12.0, Color(base_col, glow_a * 0.5 * flicker))
