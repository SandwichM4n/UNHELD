extends Node
class_name AbilitySounds

# Sound pools for different ability events
@export var cast_sounds: Array[AudioStream] = []
@export var hit_sounds: Array[AudioStream] = []
@export var miss_sounds: Array[AudioStream] = []
@export var cooldown_ready_sounds: Array[AudioStream] = []

# Audio players
var cast_player: AudioStreamPlayer
var hit_player: AudioStreamPlayer
var misc_player: AudioStreamPlayer

func _ready():
	# Create audio players
	cast_player = AudioStreamPlayer.new()
	hit_player = AudioStreamPlayer.new()
	misc_player = AudioStreamPlayer.new()
	
	add_child(cast_player)
	add_child(hit_player)
	add_child(misc_player)

func play_cast():
	"""Play a random cast sound"""
	if cast_sounds.is_empty():
		return
	
	var sound = cast_sounds[randi() % cast_sounds.size()]
	cast_player.stream = sound
	cast_player.play()

func play_hit():
	"""Play a random hit sound"""
	if hit_sounds.is_empty():
		return
	
	var sound = hit_sounds[randi() % hit_sounds.size()]
	hit_player.stream = sound
	hit_player.play()

func play_miss():
	"""Play a random miss sound"""
	if miss_sounds.is_empty():
		return
	
	var sound = miss_sounds[randi() % miss_sounds.size()]
	misc_player.stream = sound
	misc_player.play()

func play_ready():
	"""Play cooldown ready sound"""
	if cooldown_ready_sounds.is_empty():
		return
	
	var sound = cooldown_ready_sounds[randi() % cooldown_ready_sounds.size()]
	misc_player.stream = sound
	misc_player.play()
