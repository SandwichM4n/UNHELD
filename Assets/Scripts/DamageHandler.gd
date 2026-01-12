extends Node2D
class_name DamageHandler

@export var min_damage: int = 1
@export var max_damage: int = 6
@export var hit_sfx_name: String = "hit" # You can change this in Inspector for different weapons!
@export var allow_multi_hit: bool = false  # ← New: for attacks that can hit same enemy multiple times
@onready var audio = %AudioManager # Path: Area2D -> Blade -> AudioManager
@onready var hit_zone = get_parent() as Area2D  # The Area2D this is attached to
var enemies_hit_this_attack: Array = []

func _ready():
	if hit_zone:
		hit_zone.area_entered.connect(_on_area_entered)

func reset_hit_tracking():
	"""Call this when a new attack starts"""
	enemies_hit_this_attack.clear()

func _on_area_entered(area: Area2D) -> void:
	# After you calculate final_damage
	var victim = area.get_parent()
	# Check if what we hit is a BaseEnemy
	if not victim is BaseEnemy:
		return
	# Check if already hit (unless multi-hit is allowed)
	if not allow_multi_hit and victim in enemies_hit_this_attack:
		return
	enemies_hit_this_attack.append(victim)	
	var final_damage = randi_range(min_damage, max_damage)
	spawn_damage_number(final_damage, victim.global_position)
		# 1. Play the sound via the AudioManager
	if audio:
		audio.play_sfx(hit_sfx_name)
		# 2. Deal the damage
	victim.take_damage(final_damage, global_position)


func spawn_damage_number(amount: int, pos: Vector2):
	var label = Label.new()
	label.text = str(amount)
	
	# Style the label (Optional: make it smaller/white)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.global_position = pos + Vector2(-10, -20) # Center it over head
	label.z_index = 50 # On top of enemies
	
	# Add it to the main world so it stays where the hit happened
	get_tree().current_scene.add_child(label)
	
	# The Animation
	var t = create_tween()
	# Float Up + Slight arc
	t.tween_property(label, "global_position:y", pos.y - 60, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(label, "global_position:x", pos.x + randf_range(-10, 10), 0.4)
	# Fade out
	t.parallel().tween_property(label, "modulate:a", 0.0, 0.3).set_delay(0.2)
	# Cleanup
	t.chain().tween_callback(label.queue_free)
