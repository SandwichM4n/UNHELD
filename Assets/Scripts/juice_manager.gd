extends Node

# This function is now a "Recipe" you can call later
func apply_fancy_hit(hit_object):
	# 1. Freeze Time
	Engine.time_scale = 0.05
	
	# 2. Wait
	# We use 'true' for process_always so the timer works while game is frozen
	await get_tree().create_timer(0.075, true, false, true).timeout
	
	# 3. Resume Time
	Engine.time_scale = 1.0
	
	# 4. Shake Camera
	var camera = get_viewport().get_camera_2d()
	if camera and camera.has_method("apply_shake"):
		camera.apply_shake(2.0)
