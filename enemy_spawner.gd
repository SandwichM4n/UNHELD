extends Node

@export var enemy_scene: PackedScene = preload("res://enemy.tscn") # Make sure path is correct!
@export var max_enemies = 10
@export var spawn_distance = 200 # Pixels beyond the screen edge

func _on_timer_timeout():
	# 1. Count current enemies
	var current_enemies = get_tree().get_nodes_in_group("enemies")
	# Debug print to see if the counter is working
	print("Current enemies in game: ", current_enemies.size())
	
	if current_enemies.size() < max_enemies:
		spawn_enemy()

func spawn_enemy():
	var enemy = enemy_scene.instantiate()
	
	# Find player to spawn around
	var player = get_tree().get_first_node_in_group("player")
	if not player: 
		print("Spawner Error: No player found in 'player' group!")
		return
	
	# Pick a random spot in a circle 700 pixels away
	var random_direction = Vector2.RIGHT.rotated(randf() * TAU)
	var spawn_pos = player.global_position + (random_direction * 700)
	
	enemy.global_position = spawn_pos
	
	# Add to the main scene (the root of the running game)
	get_tree().current_scene.add_child(enemy)
	print("Spawned new enemy at: ", spawn_pos)
