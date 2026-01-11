extends Node2D
class_name MeleeMovement

# We need to reference the parent (the CharacterBody2D)
@onready var enemy = get_parent() 
@onready var player = get_tree().get_first_node_in_group("player")

func _physics_process(_delta):
	# 1. Death/Player Checks
	if not enemy or enemy.is_dead or not player:
		return
		
	# 2. Movement Logic
	var direction = enemy.global_position.direction_to(player.global_position)
	
	# CRITICAL: We must set the ENEMY'S velocity, not the node's
	enemy.velocity = direction * enemy.move_speed
	enemy.move_and_slide()
