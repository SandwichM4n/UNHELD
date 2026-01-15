extends Node2D
class_name WallCollisionHandler

@export var clank_duration: float = 0.6
@export var vibration_intensity: float = 3.0
@export var bounce_distance: float = 20.0

@onready var blade = get_parent()
@onready var audio = blade.get_node("AudioManager")
@onready var vfx = blade.get_node("VFX")
@onready var sprite = blade.get_node("Bladesprite")
@onready var wall_detector = $WallDetector  # Area2D child of this node

var is_clanking: bool = false
var clank_timer: float = 0.0

signal clank_started
signal clank_ended

func _ready():
	print("WallCollisionHandler ready!")
	
	if wall_detector:
		print("WallDetector found!")
		wall_detector.area_entered.connect(_on_wall_hit)
		wall_detector.body_entered.connect(_on_wall_hit_body)
		print("Signals connected")
		
		# Debug: print collision settings
		print("WallDetector collision_layer: ", wall_detector.collision_layer)
		print("WallDetector collision_mask: ", wall_detector.collision_mask)
	else:
		print("ERROR: WallDetector not found!")
	
	# Connect wall collision signals
	if wall_detector:
		wall_detector.area_entered.connect(_on_wall_hit)
		wall_detector.body_entered.connect(_on_wall_hit_body)
		wall_detector.monitoring = true  # ← Force enable
		wall_detector.monitorable = true

func _physics_process(delta):
	if is_clanking:
		clank_timer -= delta
		if clank_timer <= 0:
			_end_clank()

func _on_wall_hit(area: Area2D):
	print(">>> AREA HIT DETECTED: ", area.name, " from parent: ", area.get_parent().name)
	if blade.current_state == blade.State.ACTIVE and not is_clanking:
		print(">>> Conditions met, handling collision")
		_handle_wall_collision(area.get_parent())
	else:
		print(">>> Conditions NOT met. State: ", blade.current_state, " Is clanking: ", is_clanking)

func _on_wall_hit_body(body: Node2D):
	print("!!! BODY COLLISION DETECTED !!!")
	print("    Body name: ", body.name)
	print("    Body type: ", body.get_class())
	print("    Body collision_layer: ", body.collision_layer if "collision_layer" in body else "N/A")
	print("    Blade state: ", blade.current_state, " (ACTIVE = ", blade.State.ACTIVE, ")")
	print("    Is clanking: ", is_clanking)
	
	if blade.current_state == blade.State.ACTIVE and not is_clanking:
		print("    → Handling collision")
		_handle_wall_collision(body)
	else:
		print("    → Ignoring - State:", blade.current_state, " Clanking:", is_clanking)

func _handle_wall_collision(hit_object):
	"""Check if object is breakable, if not -> clank"""
	
	# Check if it's breakable
	if hit_object.has_method("is_breakable") and hit_object.is_breakable():
		hit_object.break_object()
		return
	
	# Not breakable -> CLANK!
	print("Blade clanked off wall!")
	_start_clank()

func _start_clank():
	"""Begin the clank sequence"""
	is_clanking = true
	clank_timer = clank_duration
	
	# Play effects
	audio.play_sfx("clank")
	vfx.spawn_spark_effect(blade.global_position)
	
	# Calculate bounce direction (away from player)
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var hit_normal = (blade.global_position - player.global_position).normalized()
		var bounce_pos = blade.global_position + (hit_normal * bounce_distance)
		
		# Bounce back
		var bounce_tween = blade.create_tween()
		bounce_tween.tween_property(blade, "global_position", bounce_pos, 0.1)\
			.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	
	# Start vibration
	_start_vibration()
	
	# Emit signal
	clank_started.emit()

func _start_vibration():
	"""Vibrate the sprite"""
	var vibration_tween = sprite.create_tween()
	var vibration_count = int(clank_duration / 0.05)  # 20 vibrations per second
	
	for i in range(vibration_count):
		var offset = Vector2(
			randf_range(-vibration_intensity, vibration_intensity),
			randf_range(-vibration_intensity, vibration_intensity)
		)
		vibration_tween.tween_property(sprite, "position", offset, 0.05)
	
	# Reset position
	vibration_tween.tween_property(sprite, "position", Vector2.ZERO, 0.05)

func _end_clank():
	"""Called when clank ends"""
	is_clanking = false
	sprite.position = Vector2.ZERO  # Ensure reset
	clank_ended.emit()
	print("Clank ended")

func can_attack() -> bool:
	"""Check if blade can attack (not clanking)"""
	return not is_clanking
