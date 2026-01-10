extends Node

@onready var blade = get_parent()
@onready var trail = $"../Line2D"
@onready var sprite = $"../Bladesprite"
@export var max_trail_points = 10

func update_trail(is_attacking: bool, pos: Vector2):
	if is_attacking:
		trail.add_point(pos)
		if trail.get_point_count() > max_trail_points:
			trail.remove_point(0)
	else:
		if trail.get_point_count() > 0:
			trail.remove_point(0)
