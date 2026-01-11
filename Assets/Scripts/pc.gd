extends CharacterBody2D
@onready var anim_manager = $AnimManager
@onready var blade = get_tree().get_first_node_in_group("blades")
@onready var cooldown_bar = $DebugHUD/AttackCooldownBar
var last_direction = Vector2.RIGHT
@export var speed = 100.0
@export var attack_range = 80.0
var is_attacking = false
@onready var sprite = $Sprite2D
@onready var blade_pivot = $BladePivot
@onready var anim = $AnimationPlayer # Assuming you have one
var is_auto_flowing = false
var can_attack = true
var current_state

func _ready():
	get_window().grab_focus()
	current_state = anim_manager.State.RUN

func _physics_process(_delta):
	anim_manager.update_visuals(current_state, velocity)
	# 1. MOVEMENT LOGIC
	if is_attacking:
		velocity = velocity.lerp(Vector2.ZERO, 0.01)
	else:
		var input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
		if input_dir != Vector2.ZERO:
			velocity = input_dir * speed
			last_direction = input_dir.normalized()
			update_sprite_direction(input_dir)
		else:
			velocity = velocity.move_toward(Vector2.ZERO, 30.0)
			if velocity.length() < 1.0:
				velocity = Vector2.ZERO
	
	move_and_slide()

	# 2. BLADE MANAGEMENT
	if not blade:
		blade = get_tree().get_first_node_in_group("blades")
	
	# We only need to tell the blade to redraw if you are using it for debug lines
	if is_instance_valid(blade):
		blade.queue_redraw()

	# 3. ATTACK INPUT
	if Input.is_action_just_pressed("attack") and not is_attacking:
		attack()

func update_sprite_direction(dir: Vector2):
	if dir == Vector2.ZERO: return
	

# PC.gd
func attack():    
	if not can_attack:
		return
	# Keep your safety check: ensures blade is ready
	if blade and not blade.is_attacking:
		can_attack = false
		is_attacking = true
		cooldown_bar.value = 100
		create_tween().tween_property(cooldown_bar, "value", 0, 1.0)
		# We replace the long manual math with the new function call
		var attack_vec: Vector2
		if is_auto_flowing:
			attack_vec = get_aim_direction(true) # Force auto
		else:
			attack_vec = get_aim_direction(false) # Manual first
		
		# Execute the slash
		blade.execute_slash(attack_vec)
		
		# Your existing timer logic
		await get_tree().create_timer(1).timeout # 0.4 is usually snappier than 1.0!
		is_attacking = false
		# --- THE ELEGANT CHECK ---
		# If the player is STILL holding the attack button after the timer...
		if Input.is_action_pressed("attack") or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			is_auto_flowing = true
			can_attack = true
			attack() # Loop the attack automatically!
		else:
			is_auto_flowing = false
			can_attack = true



func get_aim_direction(force_auto: bool) -> Vector2:
	# If we are in the 'Auto-Flow' state, look for enemies first
	if force_auto:
		var closest = get_closest_enemy()
		if closest:
			return global_position.direction_to(closest.global_position)
	# 1. Check Controller Right Stick (Twin Stick)
	var stick_dir = Input.get_vector("look_left", "look_right", "look_up", "look_down")
	if stick_dir.length() > 0.2: # 0.2 is a "deadzone" to prevent drifting
		return stick_dir.normalized()



# 3. PRIORITY: Mouse (Only if no enemies are in range)
	# We remove the "is_action_just_pressed" check here so it doesn't override auto-target
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var mouse_pos = get_global_mouse_position()
		return global_position.direction_to(mouse_pos)

	# 4. Fallback to movement direction
	return last_direction

func get_closest_enemy():
	var enemies = get_tree().get_nodes_in_group("enemies")
	var closest = null
	var min_dist = 400.0 # Only auto-target within this range
	
	for e in enemies:
		var dist = global_position.distance_to(e.global_position)
		if dist < min_dist:
			min_dist = dist
			closest = e
	return closest
