extends Node2D
enum State { IDLE, WINDUP, ACTIVE, RECOVERY }
var current_state = State.IDLE
@onready var audio = $AudioManager
@onready var mover = $Mover
@onready var vfx = $VFX
@onready var sprite = $Bladesprite # Make sure this matches your node name!
var combo_side = 1 
var linger_timer = 0.0
var is_lingering = false
@export var slash_radius = 100.0 # How far from player the arc happens
var is_attacking = false
@onready var player = get_tree().get_first_node_in_group("player")
@onready var hit_zone = $Area2D # Your Area2D sensor

func _ready():
	add_to_group("blades")
	hit_zone.monitoring = false # Ensure it's "Safe" by default
	
	
	

func execute_slash(target_direction: Vector2):
	transition_to(State.WINDUP, target_direction)

func _start_attack_sequence(target_direction: Vector2):
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
	
	# WINDUP PHASE
	tween.tween_property(self, "global_position", wind_up_pos, 0.15).set_trans(Tween.TRANS_SINE)
	
	# ACTIVE PHASE (Transition happens at the start of the callback)
	tween.tween_callback(func(): transition_to(State.ACTIVE))
	
	tween.tween_method(animate_arc.bind(start_angle, end_angle, current_slash_dist), 0.0, 1.0, slash_duration)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)
	
	# Squash and Stretch
	tween.parallel().tween_property(sprite, "scale", Vector2(base_s * 1.4, base_s * 0.7), slash_duration * 0.5)
	tween.tween_property(sprite, "scale", Vector2(base_s, base_s), slash_duration * 0.5)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)
	
	# RECOVERY PHASE
	tween.tween_callback(func(): transition_to(State.RECOVERY))
	
# ... ATTACK LOGIC
func transition_to(new_state: State, data = null):
	current_state = new_state
	
	match current_state:
		State.IDLE:
			is_attacking = false
			hit_zone.monitoring = false
		
		State.WINDUP:
			# data here is the 'target_direction' passed from the player
			is_attacking = true
			is_lingering = false
			_start_attack_sequence(data)
			
		State.ACTIVE:
			hit_zone.monitoring = true
			audio.play_sfx("whoosh")
			
		State.RECOVERY:
			hit_zone.monitoring = false
			is_attacking = false
			is_lingering = true
			linger_timer = 2.5
			combo_side *= -1

func animate_arc(weight: float, start: float, end: float, dist:float):
	if not player: return
	# This moves the blade along the 90-degree curve
	var current_angle = lerp_angle(start, end, weight)
	var offset = Vector2.from_angle(current_angle) * dist # Use dynamic dist!
	global_position = player.global_position + offset
	rotation = current_angle + PI/2 # Point the tip outward
	# --- GHOST TRAIL LOGIC ---
# This is the function Godot created when you connected the signal
func _on_area_2d_area_entered(area):
	var hit_object = area.get_parent() 
	if hit_object.has_method("take_damage"):
		apply_hitstop(hit_object)
	elif hit_object.has_method("die"):
		hit_object.die()

func _physics_process(delta):
	# The Brain simply tells the components what to do
	vfx.update_trail(is_attacking, global_position)
	
	if not is_attacking:
		if is_lingering:
			linger_timer -= delta
			if linger_timer <= 0: is_lingering = false
			
		mover.process_movement(player, delta, is_lingering)
		mover.process_bobbing(player, delta)

# Add this helper function at the bottom
func apply_hitstop(hit_object):
	Engine.time_scale = 0.05
	audio.play_sfx("hit")
	await get_tree().create_timer(0.075, true, false, true).timeout
	Engine.time_scale = 1.0
	
	if is_instance_valid(hit_object):
		var camera = get_viewport().get_camera_2d()
		if camera: camera.apply_shake(2.0)
		hit_object.take_damage(global_position)
