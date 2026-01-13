extends Node2D

@onready var sprite = $"../Sprite2D"
@onready var anim_player = $"../AnimationPlayer"

enum State { IDLE, RUN, DASH, ATTACK }

# Animation mapping for each state type
const ANIM_MAP = {
	"run": {
		Vector2(0, -1): "run_n",
		Vector2(0, 1): "run_s",
		Vector2(-1, 0): "run_w",
		Vector2(1, 0): "run_w",
		Vector2(-1, -1): "run_n_diag",
		Vector2(1, -1): "run_n_diag",
		Vector2(-1, 1): "run_s_diag",
		Vector2(1, 1): "run_s_diag"
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
	
	# Handle horizontal flipping
	sprite.flip_h = direction.x > 0
	
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
	
	# Scale sprite 1.3x for dash
	sprite.scale = original_sprite_scale * 1.3
	
	# Play animation at FULL SPEED
	anim_player.speed_scale = 1.0
	anim_player.play(anim_name)
	
	return anim_name

func end_dash():
	"""Manually called to end dash state"""
	is_dashing = false
	anim_player.speed_scale = 0.65
	sprite.scale = original_sprite_scale
	print("Dash ended - reset to normal")

func force_last_frame(anim_name: String):
	"""Jump to last frame - for when dash is too fast"""
	if not anim_player.has_animation(anim_name):
		print("Animation not found: ", anim_name)
		return
	
	# Stop the animation player
	anim_player.stop()
	
	# Manually find and set the last frame
	var anim = anim_player.get_animation(anim_name)
	var track_count = anim.get_track_count()
	
	print("Animation: ", anim_name, " has ", track_count, " tracks")
	
	# Look through all tracks to find the sprite frame track
	for track_idx in range(track_count):
		var track_path = anim.track_get_path(track_idx)
		print("Track ", track_idx, ": ", track_path)
		
		# Check if this track controls the sprite's frame
		if "frame" in str(track_path) or "Sprite2D:frame" in str(track_path):
			var key_count = anim.track_get_key_count(track_idx)
			print("Found frame track with ", key_count, " keys")
			
			if key_count > 0:
				# Get the LAST keyframe's value
				var last_frame_value = anim.track_get_key_value(track_idx, key_count - 1)
				sprite.frame = last_frame_value
				print("Set sprite.frame to: ", last_frame_value)
				return
	
	print("WARNING: Could not find frame track in animation!")
