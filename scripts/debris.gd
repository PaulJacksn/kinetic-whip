extends Node2D
## Scatter debris: a robot part that flies off in the hit direction with
## real physics (velocity, spin, friction), then transforms into a little
## collectible orb that drifts to the core. Pooled.

enum Phase { SCATTER, ORB, DONE }

const CORE_POS := Vector2(360, 640)
const COLLECT_RADIUS := 62.0
const MAGNET_RADIUS := 220.0

var active: bool = false
var phase: int = Phase.DONE
var poly: PackedVector2Array = PackedVector2Array()
var col: Color = Color.WHITE
var vel: Vector2 = Vector2.ZERO
var ang_vel: float = 0.0
var rot: float = 0.0
var value: int = 1
var _timer: float = 0.0
var _time: float = 0.0

func launch(p: PackedVector2Array, c: Color, from: Vector2, direction: Vector2, power: float, p_value: int) -> void:
	poly = p
	col = c
	position = from
	vel = direction.normalized() * power + Vector2(randf_range(-40.0, 40.0), randf_range(-40.0, 40.0))
	ang_vel = randf_range(-9.0, 9.0)
	rot = randf_range(0.0, TAU)
	value = p_value
	phase = Phase.SCATTER
	_timer = 0.85
	active = true
	visible = true
	queue_redraw()

func deactivate() -> void:
	active = false
	phase = Phase.DONE
	visible = false

## Returns "collected" when the orb reaches the core, "" otherwise.
func update(delta: float) -> String:
	if not active:
		return ""
	_time += delta
	match phase:
		Phase.SCATTER:
			vel *= exp(-2.2 * delta)
			position += vel * delta
			rot += ang_vel * delta
			ang_vel *= exp(-1.5 * delta)
			_timer -= delta
			if _timer <= 0.0:
				phase = Phase.ORB
		Phase.ORB:
			var to_core := CORE_POS - position
			var d := to_core.length()
			if d < MAGNET_RADIUS:
				vel = vel.move_toward(to_core.normalized() * 260.0, 700.0 * delta)
			else:
				vel = vel.move_toward(Vector2.ZERO, 120.0 * delta)
				# Gentle drift so orbs do not sit still
				position += Vector2(sin(_time * 2.0), cos(_time * 1.7)) * 12.0 * delta
			position += vel * delta
			if d < COLLECT_RADIUS:
				deactivate()
				return "collected"
	queue_redraw()
	return ""

func _draw() -> void:
	if not active:
		return
	if phase == Phase.SCATTER:
		var moved := PackedVector2Array()
		for p in poly:
			moved.append(p.rotated(rot))
		draw_colored_polygon(moved, col)
		var outline := PackedVector2Array(moved)
		outline.append(moved[0])
		draw_polyline(outline, Color(0.05, 0.06, 0.1, 0.9), 1.5)
	else:
		var pulse := 1.0 + 0.15 * sin(_time * 6.0)
		draw_circle(Vector2.ZERO, 11.0 * pulse, Color(1.0, 0.85, 0.3, 0.3))
		draw_circle(Vector2.ZERO, 6.5 * pulse, Color(1.0, 0.85, 0.3))
		draw_circle(Vector2.ZERO, 2.5, Color(1, 1, 1))
