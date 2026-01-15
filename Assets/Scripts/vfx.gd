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
# Add this to your existing VFX.gd

func spawn_spark_effect(pos: Vector2):
	"""Spawn visual sparks at collision point"""
	
	# Simple flash effect
	var flash = ColorRect.new()
	flash.color = Color.ORANGE
	flash.size = Vector2(16, 16)
	flash.position = pos - flash.size / 2
	
	get_tree().current_scene.add_child(flash)
	
	var flash_tween = flash.create_tween()
	flash_tween.tween_property(flash, "modulate:a", 0.0, 0.3)
	flash_tween.tween_property(flash, "scale", Vector2(2, 2), 0.3)
	flash_tween.tween_callback(flash.queue_free)
