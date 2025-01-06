extends Node2D


@onready var click_burst = $ClickBurst

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if !App.can_click: return
	global_position = get_global_mouse_position()
	if Input.is_action_just_pressed("ACTIONB"):
			repeat()
	if Input.is_action_just_pressed("ACTIONC"):
		click()

func repeat():
	var increment := 0.5
	while Input.is_action_pressed("ACTIONB") and !Input.is_action_just_released("ACTIONB"):
		increment += get_process_delta_time()
		await get_tree().process_frame
		if increment > 0.5: 
			increment = 0.0
			click()
		if !Input.is_action_pressed("ACTIONB"): break

func click():
	if !click_burst.material.get_shader_parameter("progress") in [1.0,0.0]:
		#make new
		var new : ColorRect = ColorRect.new()
		new.top_level = true
		new.material = click_burst.material.duplicate()
		new.material.set_shader_parameter("progress",0.0)
		add_child(new)
		
		new.size = Vector2(40,40)
		new.z_index = 10
		new.z_as_relative = false
		new.global_position = get_global_mouse_position() - Vector2(20,20)
		var sspn = func(nv):
			new.material.set_shader_parameter("progress",nv)
		await create_tween().tween_method(sspn,0.0,1.0,1.0).finished
		remove_child(new)
		new.queue_free()
	else:
		click_burst.global_position = get_global_mouse_position() - Vector2(20,20)
		create_tween().tween_method(ssp,0.0,1.0,1.0)


func ssp(nv : float):
	click_burst.material.set_shader_parameter("progress",nv)
