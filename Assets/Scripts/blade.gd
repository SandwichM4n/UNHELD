extends Node2D
var bob_phase = 0.0
@export var whoosh_sounds : Array[AudioStream] = []
var sound_pool : Array[AudioStream] = []
@export var hit_flesh_sounds : Array[AudioStream] = []
@onready var sfx_hit = $SFXOnGetHit # Add a second AudioStreamPlayer2D to your Blade named SfxHit
var hit_pool : Array[AudioStream] = []
@onready var sprite = $Bladesprite # Make sure this matches your node name!
var combo_side = 1 
var linger_timer = 0.0
var is_lingering = false
var ghost_timer = 0.0
var speed = 100.0        # How fast the blade chases you
var dead_zone = 60.0    # The "Invisible Circle" radius
var stop_distance = 40.0 # Distance to keep from the player center
@export var slash_radius = 100.0 # How far from player the arc happens
@onready var trail = $Line2D # Ensure this matches your node name
@export var max_trail_points = 10

var is_attacking = false
@onready var player = get_tree().get_first_node_in_group("player")
@onready var hit_zone = $Area2D # Your Area2D sensor

func _ready():
	add_to_group("blades")
	var _base_s = 0.05 # Your original scale
	hit_zone.monitoring = false # Ensure it's "Safe" by default
# ... ATTACK LOGIC
#region Attack
func execute_slash(target_direction: Vector2):
	is_attacking = true
	is_lingering = false # We are active now
	hit_zone.monitoring = false # No damage during the "travel" phase
	# --- NEW LOGIC: FIND DISTANCE ---
	var current_slash_dist = slash_radius
	var closest = player.get_closest_enemy() # We can call the PC's function!
	
	if closest:
		var dist_to_enemy = player.global_position.distance_to(closest.global_position)
		# If the enemy is closer than our default radius, shrink the radius to hit them
		# but don't go lower than 40 so we don't hit ourselves
		current_slash_dist = clamp(dist_to_enemy, 40.0, slash_radius)
	# --------------------------------
	
	# Calculate the 90 degree arc (45 degrees left and right of target)
	var center_angle = target_direction.angle()
	var start_angle = center_angle - (deg_to_rad(45) * combo_side)
	var end_angle = center_angle + (deg_to_rad(45) * combo_side)
	
	
	# Where the blade needs to be to START the slash
	var wind_up_pos = player.global_position + Vector2.from_angle(start_angle) * current_slash_dist
	
	var tween = create_tween()
	var slash_duration = (current_slash_dist / slash_radius) * 0.2
	# 1. Travel to the start point (The Wind-up)
	tween.tween_property(self, "global_position", wind_up_pos, 0.15).set_trans(Tween.TRANS_SINE)
	
	# 2. The "Point of No Return" (The actual Slash)
	var base_s = 0.05 # Your original scale
	tween.tween_callback(play_whoosh)
	tween.tween_callback(func(): hit_zone.monitoring = true) # Turn on killing power
	tween.tween_method(animate_arc.bind(start_angle, end_angle, current_slash_dist), 0.0, 1.0, slash_duration)\
	.set_trans(Tween.TRANS_BACK)\
	.set_ease(Tween.EASE_OUT)
	# The Squash & Stretch (Parallel to the movement)
	# 1. Stretch: Make it long (0.07) and thin (0.035) during the swing
	tween.parallel().tween_property(sprite, "scale", Vector2(base_s * 1.4, base_s * 0.7), slash_duration * 0.5)
	
	# 2. Bounce: Snap back to base scale (0.05) with that same springy back-trans
	tween.tween_property(sprite, "scale", Vector2(base_s, base_s), slash_duration * 0.5)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)
	
	
	# 3. Recovery
	tween.tween_callback(func():
		hit_zone.monitoring = false
		is_attacking = false
		is_lingering = true
		linger_timer = 2.5 # Start the 2.5s window
		combo_side *= -1   # Flip the side for the NEXT hit
	)
#endregion

func animate_arc(weight: float, start: float, end: float, dist:float):
	if not player: return
	# This moves the blade along the 90-degree curve
	var current_angle = lerp_angle(start, end, weight)
	var offset = Vector2.from_angle(current_angle) * dist # Use dynamic dist!
	global_position = player.global_position + offset
	rotation = current_angle + PI/2 # Point the tip outward
	# --- GHOST TRAIL LOGIC ---
	ghost_timer += get_process_delta_time()
# This is the function Godot created when you connected the signal
func _on_area_2d_area_entered(area):
	print("Blade touched something: ", area.name) # This will tell us IF it hit
	var hit_object = area.get_parent() 
	#KILLING ENEMIES
	if hit_object.has_method("take_damage"):
		play_hit_sound(false)
		# --- THE HIT STOP ---
		# 1. Freeze time (0.0 is stopped, 1.0 is normal)
		Engine.time_scale = 0.05
		
		# 2. Wait for a tiny fraction of real-time (not game-time!)
		# We use a SceneTreeTimer with 'process_always' set to true
		await get_tree().create_timer(0.075, true, false, true).timeout
		
		# 3. Resume normal time
		Engine.time_scale = 1.0
		# --------------------
	var camera = get_viewport().get_camera_2d()
	if camera and camera.has_method("apply_shake"):
		# 4.0 or 5.0 is a solid "heavy" shake
		camera.apply_shake(2.0)
		hit_object.take_damage(global_position) 
	elif hit_object.has_method("die"):
		hit_object.die()
		print("Hit object has no die method: ", hit_object.name)

	#MOVEMENT
#region handle_follow_logic
func handle_follow_logic(delta):
	if is_attacking: return
	if is_lingering:
		linger_timer -= delta
		if linger_timer <= 0:
			is_lingering = false # Time's up, return to passive follow mode
#Movement Logic: Only move if outside the "Dead Zone"
	var distance_to_player = global_position.distance_to(player.global_position)
	if distance_to_player > dead_zone:
	# Direction from blade to player
		var direction = global_position.direction_to(player.global_position)
		var move_amount = speed * delta
		# If we are closer than the move_amount, just move exactly the distance needed
		if distance_to_player < move_amount:
			global_position = player.global_position - (direction * stop_distance)
		else:
			global_position += direction * move_amount
	# 3. Stop Logic: If it gets too close to the player's center, stop moving
	# This prevents the blade from overlapping your square perfectly
	if distance_to_player < stop_distance:
		var push_away_dir = player.global_position.direction_to(global_position)
		# If the blade is exactly on top of the player, direction is 0. 
		# We provide a fallback so it doesn't break.
		if push_away_dir == Vector2.ZERO: push_away_dir = Vector2.RIGHT
		global_position = player.global_position + (push_away_dir * stop_distance)
	# 4. Rotation Logic (CLEANED UP)
	if not is_lingering:
		var base_angle = player.velocity.angle() if player.velocity.length() > 1.0 else player.last_direction.angle()
		# If your sprite points RIGHT:
		# 0 = tip forward
		# deg_to_rad(90) = tip down
		# deg_to_rad(180) = tip backward
		# deg_to_rad(270) = tip up
		# Try changing this offset until the narrow part points where you move:
		var offset = deg_to_rad(0) 
		var target_angle = base_angle + offset
		rotation = lerp_angle(rotation, target_angle, 0.1)
	# --- NEW SMOOTH BOBBING ---
	var speed_factor = player.velocity.length() / player.speed
	var current_amplitude = lerp(12.0, 5.0, speed_factor)
	var current_speed = lerp(3.0, 4.0, speed_factor)
# Instead of multiplying time by speed, we increment the phase
# This ensures a smooth transition regardless of speed changesa
	bob_phase += delta * current_speed
	sprite.position.y = sin(bob_phase) * current_amplitude
#endregion
func create_ghost():
	var ghost = sprite.duplicate()
	get_parent().add_child(ghost)
	
	# Set ghost properties to match current blade state
	ghost.global_position = sprite.global_position
	ghost.global_rotation = sprite.global_rotation
	ghost.scale = sprite.scale
	ghost.modulate = Color(1, 1, 1, 0.5) # Semi-transparent
	
	# Use a quick tween to fade it out and delete it
	var t = create_tween()
	t.tween_property(ghost, "modulate", Color(1, 1, 1, 0), 0.15)
	t.tween_callback(ghost.queue_free)
func _physics_process(_delta):
	if is_attacking:
		# Feed the REAL world position to the trail
		# Since 'Top Level' is on, these points will stay where they were born
		trail.add_point(global_position)
		
		if trail.get_point_count() > max_trail_points:
			trail.remove_point(0)
	else:
		# Smoothly erase the trail when not attacking
		if trail.get_point_count() > 0:
			trail.remove_point(0)
func play_whoosh():
	if whoosh_sounds.size() == 0: return
		# 1. If the pool is empty, refill it and shuffle
	if sound_pool.is_empty():
		sound_pool = whoosh_sounds.duplicate()
		sound_pool.shuffle()
		
		# PRO TIP: If the first sound of the new shuffle is the same as 
		# the last sound we just played, move it to the end of the list.
		# (This prevents a repeat during the "refill" moment)
	
	# 2. Pull the last sound out of the pool (pop_back removes it)
	var selected_sound = sound_pool.pop_back()
	
	# 3. Play it
	if $SFXOnAttack:
		$SFXOnAttack.stream = selected_sound
		$SFXOnAttack.pitch_scale = randf_range(0.9, 1.1)
		$SFXOnAttack.play()
func play_hit_sound(_is_armored: bool):
	# For now, let's focus on the Flesh pool logic
	if hit_flesh_sounds.is_empty(): return
	
	if hit_pool.is_empty():
		hit_pool = hit_flesh_sounds.duplicate()
		hit_pool.shuffle()
		
	var selected_hit = hit_pool.pop_back()
	
	if sfx_hit:
		sfx_hit.stream = selected_hit
		# Hits usually sound better with a wider pitch range than whooshes
		sfx_hit.pitch_scale = randf_range(0.80, 1.20) 
		sfx_hit.play()
