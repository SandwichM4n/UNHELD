extends Camera2D

@export var target_path : NodePath
@onready var target = get_node_or_null(target_path)

# --- SHAKE VARIABLES ---
var shake_strength: float = 0.0
var shake_decay: float = 15.0 # How fast the shake stops

func _ready():
	process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	position_smoothing_enabled = false

func _physics_process(delta):
	if not target:
		target = get_tree().get_first_node_in_group("player")
	
	if target:
		# 1. Start with the "Pixel Perfect" base position
		var target_pos = target.global_position.round()
		
		# 2. Add the Shake Offset if strength > 0
		if shake_strength > 0:
			var shake_offset = Vector2(
				randf_range(-shake_strength, shake_strength),
				randf_range(-shake_strength, shake_strength)
			)
			target_pos += shake_offset
			
			# 3. Decay the shake over time
			shake_strength = lerp(shake_strength, 0.0, shake_decay * delta)
			if shake_strength < 0.1: shake_strength = 0.0
			
		global_position = target_pos

# Call this function from your Blade script!
func apply_shake(strength: float):
	shake_strength = strength
