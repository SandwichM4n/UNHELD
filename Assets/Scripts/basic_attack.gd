extends Node
@onready var blade = get_parent()
@onready var player = get_tree().get_first_node_in_group("player")
var combo_side = 1 
var linger_timer = 0.0
@export var slash_radius = 100.0 # How far from player the arc happens
var is_active = false

func _physics_process(delta):
	if is_active:
		linger_timer -= delta
		if linger_timer <= 0:
			is_active = false
			# We will tell the Blade to go IDLE here later
func start_attack(target_direction: Vector2):
	# 1. Math Setup
	var current_slash_dist = slash_radius
	var closest = player.get_closest_enemy()
	if closest:
		var dist_to_enemy = player.global_position.distance_to(closest.global_position)
		current_slash_dist = clamp(dist_to_enemy, 40.0, slash_radius)

	var center_angle = target_direction.angle()
	var start_angle = center_angle - (deg_to_rad(45) * combo_side)
	var end_angle = center_angle + (deg_to_rad(45) * combo_side)
	var wind_up_pos = player.global_position + Vector2.from_angle(start_angle) * current_slash_dist
	
	var slash_duration = (current_slash_dist / slash_radius) * 0.2
	var base_s = 0.05

	# 2. The Tween Chain
	var tween = create_tween()
	
	# WINDUP PHASE (We use 'blade' now because we are moving the parent!)
	tween.tween_property(blade, "global_position", wind_up_pos, 0.2).set_trans(Tween.TRANS_SINE)
	
	# ACTIVE PHASE
	tween.tween_callback(func(): blade.transition_to(blade.State.ACTIVE))
	
	tween.tween_method(blade.animate_arc.bind(start_angle, end_angle, current_slash_dist), 0.0, 1.0, slash_duration)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)
	
	# Squash and Stretch (Moving the blade's sprite)
	tween.parallel().tween_property(blade.sprite, "scale", Vector2(base_s * 1.4, base_s * 0.7), slash_duration * 0.5)
	tween.tween_property(blade.sprite, "scale", Vector2(base_s, base_s), slash_duration * 0.5)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)
	
	# RECOVERY PHASE
	tween.tween_callback(func(): blade.transition_to(blade.State.RECOVERY))
