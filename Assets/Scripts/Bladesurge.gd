extends Node

@export var dash_speed: float = 600.0
@export var max_range: float = 200.0
@export var cone_angle_degrees: float = 50.0
@export var cooldown_duration: float = 6.0
@export var damage_multiplier: float = 0.5
@export var cursor_forgiveness_radius: float = 50.0
@export var min_dash_anim_duration: float = 0.2

@onready var player = get_parent() as CharacterBody2D
@onready var blade = get_tree().get_first_node_in_group("blades")
@onready var state_machine = player.get_node("StateMachine")
@onready var anim_manager = player.get_node("AnimManager")
@onready var sounds = $AbilitySounds

var is_on_cooldown: bool = false
var target_enemy = null
var dash_tween: Tween = null
var current_dash_anim: String = ""

func _ready():
	pass

func try_activate() -> bool:
	if is_on_cooldown:
		print("Bladesurge on cooldown!")
		return false
	
	if not state_machine.can_bladesurge():
		return false
	
	target_enemy = find_bladesurge_target()
	
	if not target_enemy:
		print("No valid target for Bladesurge")
		return false
	
	execute_bladesurge()
	return true

func find_bladesurge_target():
	"""Find the best enemy target based on cursor position and player facing"""
	
	var mouse_pos = player.get_global_mouse_position()
	var enemies = get_tree().get_nodes_in_group("enemies")
	
	var best_cursor_target = null
	var closest_to_cursor_dist = cursor_forgiveness_radius
	
	# PRIORITY 1: Find enemy closest to cursor
	for enemy in enemies:
		if not is_instance_valid(enemy) or enemy.is_dead:
			continue
		
		var dist_to_player = player.global_position.distance_to(enemy.global_position)
		
		if dist_to_player > max_range:
			continue
		
		var dist_to_cursor = mouse_pos.distance_to(enemy.global_position)
		
		if dist_to_cursor < closest_to_cursor_dist:
			closest_to_cursor_dist = dist_to_cursor
			best_cursor_target = enemy
	
	if best_cursor_target:
		return best_cursor_target
	
	# PRIORITY 2: Find enemy in movement direction cone
	var facing = player.last_direction
	var best_facing_target = null
	var closest_facing_dist = INF
	
	for enemy in enemies:
		if not is_instance_valid(enemy) or enemy.is_dead:
			continue
		
		var dist_to_player = player.global_position.distance_to(enemy.global_position)
		
		if dist_to_player > max_range:
			continue
		
		var dir_to_enemy = player.global_position.direction_to(enemy.global_position)
		var angle = rad_to_deg(facing.angle_to(dir_to_enemy))
		
		if abs(angle) <= cone_angle_degrees:
			if dist_to_player < closest_facing_dist:
				closest_facing_dist = dist_to_player
				best_facing_target = enemy
	
	return best_facing_target

func execute_bladesurge():
	"""Perform the dash and damage"""
	
	if not target_enemy:
		return
	
	# Change state
	state_machine.change_state(state_machine.State.BLADESURGE)
	
	# Disable player collision
	player.set_collision_layer_value(1, false)
	player.set_collision_mask_value(1, false)
	
	# Calculate dash direction and target
	var dir_to_enemy = player.global_position.direction_to(target_enemy.global_position)
	var dash_target = target_enemy.global_position - (dir_to_enemy * 30)
	
	# Play dash animation
	current_dash_anim = anim_manager.play_dash_anim(dir_to_enemy)
	
	# Play cast sound
	sounds.play_cast()
	
	# Calculate duration
	var distance = player.global_position.distance_to(dash_target)
	var dash_duration = distance / dash_speed
	
	# Ensure animation plays for minimum duration
	var actual_duration = max(dash_duration, min_dash_anim_duration)
	
	# Perform dash with tween
	dash_tween = player.create_tween()
	dash_tween.tween_property(player, "global_position", dash_target, dash_duration)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_IN_OUT)
	
	# If animation needs more time, wait
	if actual_duration > dash_duration:
		dash_tween.tween_interval(actual_duration - dash_duration)
	
	# Force last frame if dash was faster than anim
	dash_tween.tween_callback(func(): 
		if dash_duration < min_dash_anim_duration:
			anim_manager.force_last_frame(current_dash_anim)
	)
	
	dash_tween.tween_callback(_on_dash_complete)

func _on_dash_complete():
	"""Called when dash animation completes"""
	
	# Check if target is already dead BEFORE dealing damage
	if not is_instance_valid(target_enemy) or target_enemy.is_dead:
		print("Target already dead, no cooldown!")
		_end_bladesurge(true)
		return
	
	# Calculate damage
	var max_basic_damage = 6
	var surge_damage = int(max_basic_damage * damage_multiplier)
	
	var enemy_hp_before = target_enemy.current_hp
	
	# Deal damage
	target_enemy.take_damage(surge_damage, player.global_position)
	
	# Spawn damage number
	spawn_damage_number(surge_damage, target_enemy.global_position)
	
	# Check if enemy died
	var enemy_died = (not is_instance_valid(target_enemy)) or target_enemy.is_dead or (enemy_hp_before <= surge_damage)
	
	# Play hit sound ONLY if enemy was alive
	if enemy_died or enemy_hp_before > 0:
		sounds.play_hit()
	
	_end_bladesurge(enemy_died)

func _end_bladesurge(enemy_died: bool):
	"""Clean up after bladesurge"""
	
	# MANUALLY end dash state
	anim_manager.end_dash()
	
	# Re-enable player collision
	player.set_collision_layer_value(1, true)
	player.set_collision_mask_value(1, true)
	
	# Return to normal state
	state_machine.change_state(state_machine.State.NORMAL)
	
	# Only start cooldown if enemy survived
	if not enemy_died:
		start_cooldown()
	else:
		print("Enemy died! Bladesurge ready for next use!")

func start_cooldown():
	"""Start the 6-second cooldown"""
	is_on_cooldown = true
	await get_tree().create_timer(cooldown_duration).timeout
	is_on_cooldown = false
	sounds.play_ready()
	print("Bladesurge ready!")

func spawn_damage_number(amount: int, pos: Vector2):
	var label = Label.new()
	label.text = str(amount)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.global_position = pos + Vector2(-10, -20)
	label.z_index = 50
	label.modulate = Color.CYAN
	
	get_tree().current_scene.add_child(label)
	
	var t = label.create_tween()
	t.tween_property(label, "global_position:y", pos.y - 60, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(label, "global_position:x", pos.x + randf_range(-10, 10), 0.4)
	t.parallel().tween_property(label, "modulate:a", 0.0, 0.3).set_delay(0.2)
	t.chain().tween_callback(label.queue_free)
