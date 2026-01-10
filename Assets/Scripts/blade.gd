extends Node2D
enum State { IDLE, WINDUP, ACTIVE, RECOVERY }
var current_state = State.IDLE
@onready var audio = $AudioManager
@onready var mover = $Mover
@onready var vfx = $VFX
@onready var sprite = $Bladesprite # Make sure this matches your node name!
@onready var basic_attack = $BasicAttack
var is_attacking = false
@onready var player = get_tree().get_first_node_in_group("player")
@onready var hit_zone = $Area2D # Your Area2D sensor

func _ready():
	add_to_group("blades")
	hit_zone.monitoring = false # Ensure it's "Safe" by default
	
	
	

func execute_slash(target_direction: Vector2):
	transition_to(State.WINDUP, target_direction)
	
# ... ATTACK LOGIC
func transition_to(new_state: State, data = null):
	current_state = new_state
	
	match current_state:
		State.IDLE:
			is_attacking = false
			hit_zone.monitoring = false
			vfx.is_active = false # Trail Off
		
		State.WINDUP:
			# data here is the 'target_direction' passed from the player
			is_attacking = true
			vfx.is_active = true # Trail On
			basic_attack.is_active = false
			basic_attack.start_attack(data)
			
		State.ACTIVE:
			hit_zone.monitoring = true
			audio.play_sfx("whoosh")
			
		State.RECOVERY:
			hit_zone.monitoring = false
			is_attacking = false
			vfx.is_active = false # Trail Off
			basic_attack.is_active = true
			basic_attack.linger_timer = 2.5
			basic_attack.combo_side *= -1

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
		audio.play_sfx("hit") # <--- Add this line here
		hit_object.take_damage(global_position)
	elif hit_object.has_method("die"):
		hit_object.die()

func _physics_process(delta):
	if not is_attacking:
		mover.process_movement(player, delta, basic_attack.is_active)
		mover.process_bobbing(player, delta)
