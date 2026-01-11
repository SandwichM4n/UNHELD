extends Node2D

# Connect to the other nodes on the Player
@onready var sprite = $"../Sprite2D"
@onready var anim_player = $"../AnimationPlayer"

# This list makes it easy to add more states later (Scalability!)
enum State { IDLE, RUN, DASH, ATTACK }
func _ready():
	anim_player.speed_scale = 0.65

func update_visuals(_state, _dir):
	# 1. Get the raw input from keys
	var up = Input.is_action_pressed("move_up")
	var down = Input.is_action_pressed("move_down")
	var left = Input.is_action_pressed("move_left")
	var right = Input.is_action_pressed("move_right")

	# 2. Check for DIAGONALS first
	if up and right:
		sprite.flip_h = true
		anim_player.play("run_n_diag")
	elif up and left:
		sprite.flip_h = false
		anim_player.play("run_n_diag")
	elif down and right:
		sprite.flip_h = true
		anim_player.play("run_s_diag")
	elif down and left:
		sprite.flip_h = false
		anim_player.play("run_s_diag")

	# 3. Check for STRAIGHT directions
	elif up:
		anim_player.play("run_n")
	elif down:
		anim_player.play("run_s")
	elif right:
		sprite.flip_h = true
		anim_player.play("run_w") # Using your 'West' sheet flipped
	elif left:
		sprite.flip_h = false
		anim_player.play("run_w")
	
	# 4. If nothing is pressed
	else:
		anim_player.stop()
