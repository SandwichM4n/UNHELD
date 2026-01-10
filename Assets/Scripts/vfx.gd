extends Node
var is_active = false
@onready var blade = get_parent()
@onready var trail = $"../Line2D"
@onready var sprite = $"../Bladesprite"
@export var max_trail_points = 10

func _physics_process(_delta):
	if is_active:
		trail.add_point(blade.global_position)
		if trail.get_point_count() > max_trail_points:
			trail.remove_point(0)
	else:
		if trail.get_point_count() > 0:
			trail.remove_point(0)
