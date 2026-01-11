extends CharacterBody2D
class_name BaseEnemy



@onready var sprite = $Sprite2D
@export var max_hp: int = 1
var current_hp: int = max_hp
var is_dead: bool = false
@onready var health_bar = $HealthBar
var hp_display_timer: float = 0.0
@export var knockback_resistance: float = 0.0 
@export var move_speed = 96.0
func _ready():
	if not is_in_group("enemies"):
		add_to_group("enemies")
	current_hp = max_hp

func _process(delta: float) -> void:
	# This handles the "Hide after 5 seconds" logic
	if hp_display_timer > 0:
		hp_display_timer -= delta
		health_bar.show()
	else:
		health_bar.hide()
func take_damage(amount: int, source_pos: Vector2):
	if is_dead: return 
	current_hp -= amount
	# Update the bar and start the 5-second countdown
	health_bar.max_value = max_hp
	health_bar.value = current_hp
	if current_hp < max_hp:
		hp_display_timer = 5.0
	if current_hp <= 0:
		die(source_pos)
	else:
		play_hit_effect(source_pos)

func play_hit_effect(source_pos: Vector2) -> Tween:
	sprite.modulate = Color(10, 10, 10, 1)
	
	var player = get_tree().get_first_node_in_group("player")
	var away_dir = player.global_position.direction_to(source_pos)
	var snap_pos = global_position.lerp(source_pos, 1.0 - knockback_resistance)
	var push_dist = 20.0 * (1.0 - knockback_resistance) 
	var target_pos = snap_pos + (away_dir * push_dist)
	var t = create_tween()
	# THE SNAP (Impale)
	t.tween_property(self, "global_position", snap_pos, 0.05).set_trans(Tween.TRANS_CUBIC)

	# THE FLING (Release)
	t.parallel().tween_property(self, "global_position", target_pos, 0.15).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	
	var target_alpha = 0.0 if is_dead else 1.0
	t.parallel().tween_property(sprite, "modulate", Color(1, 1, 1, target_alpha), 0.15)
	
	return t
	
func die(source_pos: Vector2):
	is_dead = true # This kills the _physics_process movement
	if health_bar:
		health_bar.hide()
		hp_display_timer = 0 # Ensure _process doesn't turn it back on
	# Disable collisions immediately
	set_collision_layer_value(1, false)
	set_collision_mask_value(1, false)

	# Play the exact same hit effect
	var death_tween = play_hit_effect(source_pos)
	
	# Wait for THAT specific tween to finish, then delete
	death_tween.chain().tween_callback(queue_free)
