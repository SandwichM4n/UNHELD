extends Node

@export var whoosh_sounds : Array[AudioStream] = []
@export var hit_sounds : Array[AudioStream] = []

var whoosh_pool : Array[AudioStream] = []
var hit_pool : Array[AudioStream] = []

@onready var sfx_attack = $"../SFXOnAttack" # Path to your Audio players
@onready var sfx_hit = $"../SFXOnHit"

func play_sfx(type: String):
	var library = whoosh_sounds if type == "whoosh" else hit_sounds
	var pool = whoosh_pool if type == "whoosh" else hit_pool
	var player = sfx_attack if type == "whoosh" else sfx_hit
	
	if library.is_empty(): return
	
	if pool.is_empty():
		pool.assign(library.duplicate())
		pool.shuffle()
	
	player.stream = pool.pop_back()
	player.pitch_scale = randf_range(0.9, 1.1)
	player.play()
