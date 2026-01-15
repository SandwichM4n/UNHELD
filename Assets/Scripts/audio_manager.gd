extends Node

@export var whoosh_sounds : Array[AudioStream] = []
@export var hit_sounds : Array[AudioStream] = []
@export var clank_sounds : Array[AudioStream] = []  # ← ADD THIS

var whoosh_pool : Array[AudioStream] = []
var hit_pool : Array[AudioStream] = []
var clank_pool : Array[AudioStream] = []  # ← ADD THIS

@onready var sfx_attack = $"../SFXOnAttack"
@onready var sfx_hit = $"../SFXOnHit"
@onready var sfx_clank = $"../SFXOnClank"  # ← ADD THIS (create this AudioStreamPlayer node)

func play_sfx(type: String):
	var library
	var pool
	var player
	
	# ← ADD THIS MATCH BLOCK (replace your current if/else)
	match type:
		"whoosh":
			library = whoosh_sounds
			pool = whoosh_pool
			player = sfx_attack
		"hit":
			library = hit_sounds
			pool = hit_pool
			player = sfx_hit
		"clank":
			library = clank_sounds
			pool = clank_pool
			player = sfx_clank
		_:
			return
	
	if library.is_empty(): return
	
	if pool.is_empty():
		pool.assign(library.duplicate())
		pool.shuffle()
	
	player.stream = pool.pop_back()
	player.pitch_scale = randf_range(0.9, 1.1)
	player.play()
