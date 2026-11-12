extends Node2D
## Enemy projectile: a glowing bolt fired at the core. Pooled.
## The whip and chakra can destroy it mid-flight.

var active: bool = false
var vel: Vector2 = Vector2.ZERO
var damage: float = 6.0
var _time: float = 0.0

func fire(from: Vector2, target: Vector2, speed: float) -> void:
	position = from
	vel = (target - from).normalized() * speed
	active = true
	visible = true
	_time = 0.0
	queue_redraw()

func deactivate() -> void:
	active = false
	visible = false

func update(delta: float) -> void:
	if not active:
		return
	_time += delta
	position += vel * delta
	if position.x < -40.0 or position.x > 760.0 or position.y < -40.0 or position.y > 1320.0:
		deactivate()
		return
	queue_redraw()

func _draw() -> void:
	if not active:
		return
	var dir := vel.normalized()
	var perp := Vector2(-dir.y, dir.x)
	var tip := dir * 14.0
	var tail := -dir * 10.0
	var poly := PackedVector2Array([tip, tail + perp * 6.0, tail - perp * 6.0])
	draw_colored_polygon(poly, Color(1.0, 0.45, 0.2))
	draw_circle(Vector2.ZERO, 8.0 + sin(_time * 20.0) * 2.0, Color(1.0, 0.6, 0.25, 0.35))
