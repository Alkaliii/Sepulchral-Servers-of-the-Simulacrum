extends Control

@onready var pause_status = $MarginContainer/VBoxContainer/pauseStatus
@onready var playtime = $MarginContainer/VBoxContainer/playtime
@onready var quit = $MarginContainer/VBoxContainer/ScrollContainer/vbc/QUIT
@onready var blur = $Blur

# Called when the node enters the scene tree for the first time.
func _ready():
	process_mode = PROCESS_MODE_ALWAYS
	var lowpass : AudioEffectLowPassFilter = AudioEffectLowPassFilter.new()
	lowpass.db = AudioEffectFilter.FILTER_18DB
	#var reverb : AudioEffectReverb = AudioEffectReverb.new()
	#AudioServer.add_bus_effect(0,reverb,0)
	AudioServer.add_bus_effect(0,lowpass,0)
	filterMaster(false)
	
	if OS.has_feature("pc"): quit.show()
	else: quit.hide()

func seconds2hhmmss(total_seconds: float) -> String:
	#total_seconds = 12345
	var seconds:float = fmod(total_seconds , 60.0)
	var minutes:int   =  int(total_seconds / 60.0) % 60
	var hours:  int   =  int(total_seconds / 3600.0)
	var hhmmss_string:String = "%02d:%02d:%05.2f" % [hours, minutes, seconds]
	return hhmmss_string

func filterMaster(state:bool):
	AudioServer.set_bus_effect_enabled(0,0,state)
	#AudioServer.set_bus_effect_enabled(0,1,state)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_just_pressed("pause_game"): appear(!visible)
	if visible: playtime.text = seconds2hhmmss(App.uptime)

var atw : Tween
func appear(state:bool):
	if atw: atw.kill()
	
	var freeze = true
	if Plyrm.connected:
		freeze = false
	
	match state:
		true: #show
			if freeze:
				get_tree().paused = true
				pause_status.text = "|| GAME PAUSED"
				filterMaster(true)
			else:
				pause_status.text = "> [wave]GAME PROCESSING"
			
			show()
			atw = create_tween()
			atw.tween_property(self,"position:x",0.0,0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
			atw.parallel().tween_method(sbbv,0.0,16.0,0.25).set_ease(Tween.EASE_IN_OUT)
			await atw.finished
		false:
			get_tree().paused = false
			filterMaster(false)
			atw = create_tween()
			atw.tween_property(self,"position:x",-get_viewport().size.x,0.5).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
			atw.parallel().tween_method(sbbv,16.0,0.0,0.25).set_ease(Tween.EASE_IN_OUT)
			await atw.finished
			hide()

func sbbv(nv):
	blur.material.set_shader_parameter("blur_amount",nv)

@onready var mastersldr = $MarginContainer/VBoxContainer/ScrollContainer/vbc/MasterVolume/mastersldr
func _on_mastersldr_drag_ended(value_changed):
	if value_changed:
		if mastersldr.value > 0.0:
			AudioServer.set_bus_volume_db(0,linear_to_db(mastersldr.value))
		else:
			AudioServer.set_bus_volume_db(0,-100)
	
	SystemAudio.play(SoundLib.get_file_sfx(SoundLib.sound_files.NOTIFICATION_C),1.0,"Master")

#live master changes
func _on_mastersldr_value_changed(value):
	if value > 0.0:
		AudioServer.set_bus_volume_db(0,linear_to_db(value))
	else:
		AudioServer.set_bus_volume_db(0,-100)

@onready var musicsldr = $MarginContainer/VBoxContainer/ScrollContainer/vbc/MusicVolume/musicsldr
func _on_musicsldr_drag_ended(value_changed):
	if value_changed:
		if musicsldr.value > 0.0:
			AudioServer.set_bus_volume_db(1,linear_to_db(musicsldr.value))
		else:
			AudioServer.set_bus_volume_db(1,-100)
	
	SystemAudio.play(SoundLib.get_file_sfx(SoundLib.sound_files.NOTIFICATION_C),1.0,"Music")

#live music changes
func _on_musicsldr_value_changed(value):
	if value > 0.0:
		AudioServer.set_bus_volume_db(1,linear_to_db(value))
	else:
		AudioServer.set_bus_volume_db(1,-100)

@onready var sfxsldr = $MarginContainer/VBoxContainer/ScrollContainer/vbc/SfxVolume/sfxsldr
func _on_sfxsldr_drag_ended(value_changed):
	if value_changed:
		if sfxsldr.value > 0.0:
			AudioServer.set_bus_volume_db(2,linear_to_db(sfxsldr.value))
		else:
			AudioServer.set_bus_volume_db(2,-100)
	
	SystemAudio.play(SoundLib.get_file_sfx(SoundLib.sound_files.NOTIFICATION_C),1.0,"SFX")

@onready var muteswitch = $MarginContainer/VBoxContainer/ScrollContainer/vbc/MuteSwitch/muteswitch
func _on_muteswitch_toggled(toggled_on):
	muteswitch.release_focus()
	match toggled_on:
		false: AudioServer.set_bus_volume_db(0,linear_to_db(mastersldr.value))
		true: AudioServer.set_bus_volume_db(0,-100)

func _on_quit_pressed():
	print("Goodbye")
	get_tree().quit()
