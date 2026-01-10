extends Node
# mover_component.gd
@export var speed = 100.0        
@export var dead_zone = 60.0    
@export var stop_distance = 40.0
@onready var blade = get_parent()
@onready var sprite = $"../Bladesprite"

var bob_phase = 0.0

func process_movement(player, delta, is_lingering):
	var dist = blade.global_position.distance_to(player.global_position)
	
	# 1. Chase Logic
	if dist > dead_zone:
		var dir = blade.global_position.direction_to(player.global_position)
		var move_amount = speed * delta
		if dist < move_amount:
			blade.global_position = player.global_position - (dir * stop_distance)
		else:
			blade.global_position += dir * move_amount
			
	# 2. Stop/Push Logic
	if dist < stop_distance:
		var push_dir = player.global_position.direction_to(blade.global_position)
		if push_dir == Vector2.ZERO: push_dir = Vector2.RIGHT
		blade.global_position = player.global_position + (push_dir * stop_distance)

	# 3. Rotation Logic
	if not is_lingering:
		var base_angle = player.velocity.angle() if player.velocity.length() > 1.0 else player.last_direction.angle()
		blade.rotation = lerp_angle(blade.rotation, base_angle, 0.1)

func process_bobbing(player, delta):
	var speed_factor = player.velocity.length() / player.speed
	var current_amp = lerp(12.0, 5.0, speed_factor)
	var current_spd = lerp(3.0, 4.0, speed_factor)
	
	bob_phase += delta * current_spd
	sprite.position.y = sin(bob_phase) * current_amp
