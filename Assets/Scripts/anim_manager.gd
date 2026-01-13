extends Node2D

@onready var sprite = $"../Sprite2D"
@onready var anim_player = $"../AnimationPlayer"

enum State { IDLE, RUN, DASH, ATTACK }

const ANIM_MAP = {
	"run": {
		Vector2(0, -1): "run_n",           # North
		Vector2(0, 1): "run_s",            # South
		Vector2(-1, 0): "run_w",           # West (no flip)
		Vector2(1, 0): "run_e",            # East (no flip) ← NEW!
		Vector2(-1, -1): "run_n_diag",     # NW (no flip)
		Vector2(1, -1): "run_n_diag",      # NE (flipped) ← Still flips
		Vector2(-1, 1): "run_s_diag",      # SW (no flip)
		Vector2(1, 1): "run_s_diag"        # SE (flipped) ← Still flips
	},
	"dash": {
		Vector2(0, -1): "dash_n",
		Vector2(0, 1): "dash_s",
		Vector2(-1, 0): "dash_w",
		Vector2(1, 0): "dash_w",
		Vector2(-1, -1): "dash_n_diag",
		Vector2(1, -1): "dash_n_diag",
		Vector2(-1, 1): "dash_s_diag",
		Vector2(1, 1): "dash_s_diag"
	}
}

var original_sprite_scale: Vector2
var is_dashing: bool = false

func _ready():
	original_sprite_scale = sprite.scale
	anim_player.speed_scale = 0.65

func update_visuals(_state, _dir):
	# Don't interrupt dash animations
	if is_dashing:
		return
	
	# Get 8-way input direction
	var input_dir = get_8way_input()
	
	if input_dir != Vector2.ZERO:
		play_directional_anim("run", input_dir)
	else:
		anim_player.stop()

func get_8way_input() -> Vector2:
	"""Convert input to one of 8 cardinal directions"""
	var raw = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	if raw == Vector2.ZERO:
		return Vector2.ZERO
	
	# Snap to 8 directions
	var angle = raw.angle()
	var snapped_angle = round(angle / (PI/4)) * (PI/4)
	return Vector2.from_angle(snapped_angle).round()

func play_directional_anim(anim_type: String, direction: Vector2):
	"""Play animation based on type and direction"""
	if not ANIM_MAP.has(anim_type):
		return
	
	var anim_name = ANIM_MAP[anim_type].get(direction, "")
	if anim_name.is_empty():
		return
	
	# Special handling: only flip for diagonal east directions
	# Don't flip for pure east (run_e has its own animation now)
	if direction == Vector2(1, 0):  # Pure east
		sprite.flip_h = false  # Don't flip, use run_e as-is
		sprite.scale = original_sprite_scale * 0.85  # ← 10% smaller for pure east
	elif direction == Vector2(-1, 0):  # Pure west
		sprite.flip_h = false
		sprite.scale = original_sprite_scale * 0.85  # ← 10% smaller for pure west
	elif direction.x > 0:  # NE or SE diagonals
		sprite.flip_h = true
		sprite.scale = original_sprite_scale  # ← Normal size for diagonals
	else:
		sprite.flip_h = false
		sprite.scale = original_sprite_scale  # ← Normal size for other directions
	
	# Only play if not already playing this animation
	if anim_player.current_animation != anim_name:
		anim_player.play(anim_name)

func play_dash_anim(direction: Vector2) -> String:
	"""Play dash animation - ALWAYS plays to completion"""
	is_dashing = true
	
	var normalized_dir = direction.normalized()
	
	# Snap to 8 directions
	var angle = normalized_dir.angle()
	var snapped_angle = round(angle / (PI/4)) * (PI/4)
	var snapped_dir = Vector2.from_angle(snapped_angle).round()
	
	# Get the animation name
	var anim_name = ANIM_MAP["dash"].get(snapped_dir, "dash_s")
	
	# Handle flipping
	sprite.flip_h = snapped_dir.x > 0
	
	# Scale sprite 1.42x for dash
	sprite.scale = original_sprite_scale * 1.42
	
	# Play animation at 1.5x speed
	anim_player.speed_scale = 1.5
	anim_player.play(anim_name)
	
	return anim_name

func end_dash():
	"""Manually called to end dash state"""
	is_dashing = false
	anim_player.speed_scale = 0.65
	sprite.scale = original_sprite_scale
