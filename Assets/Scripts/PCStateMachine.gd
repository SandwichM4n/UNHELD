extends Node
class_name PCStateMachine

enum State { NORMAL, BLADESURGE }
var current_state = State.NORMAL

signal state_changed(new_state)

@onready var player = get_parent() as CharacterBody2D

func _ready():
	pass

func change_state(new_state: State):
	if current_state == new_state:
		return
	
	# Exit current state
	match current_state:
		State.BLADESURGE:
			_exit_bladesurge()
	
	current_state = new_state
	state_changed.emit(new_state)
	
	# Enter new state
	match new_state:
		State.BLADESURGE:
			_enter_bladesurge()

func _enter_bladesurge():
	print("Entering Bladesurge")
	# We'll fill this in next

func _exit_bladesurge():
	print("Exiting Bladesurge")
	# We'll fill this in next

func can_bladesurge() -> bool:
	"""Check if bladesurge is currently available"""
	return current_state == State.NORMAL

# We'll add more functions here
