extends CharacterBody2D
@export var move_speed = 96.0
@onready var player = get_tree().get_first_node_in_group("player")
var is_dying = false

func _ready():
	add_to_group("enemies") # CRITICAL: The spawner and blade need this group!
	
func _physics_process(_delta):
	# --- THE FIX ---
	# If we are dying or player is gone, don't move!
	if is_dying or not player:
		return
		
	var direction = global_position.direction_to(player.global_position)
	velocity = direction * move_speed
	move_and_slide()

func take_damage(blade_pos: Vector2):
	if is_dying: return
	is_dying = true # This instantly disables _physics_process
	
	# 1. White Flash 
	modulate = Color(10, 10, 10, 1) 
	
	# 2. Knockback Tween
	var tween = create_tween()
	# THE DRAG: Move the enemy to the blade's tip almost instantly
	# This creates the "impaled" look.
	tween.tween_property(self, "global_position", blade_pos, 0.05).set_trans(Tween.TRANS_CUBIC)
# We calculate the "away" direction from the point they were dragged to
	var away_dir = player.global_position.direction_to(blade_pos)
	var short_knockback = blade_pos + (away_dir * 20.0)
	
	tween.parallel().tween_property(self, "global_position", short_knockback, 0.15).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "modulate", Color(1, 1, 1, 0), 0.2)
	
	tween.tween_callback(queue_free)

# Keep a simple die() just in case other things call it
func die():
	take_damage(Vector2.ZERO)
