extends Control

@onready var title = $Title
@onready var story_text = $storyText
@onready var click_2_start = $MarginContainer/click2start

@onready var pos_top = $MarginContainer/top
@onready var pos_center = $MarginContainer/center

@onready var click_detect = $ClickDetect
@onready var glitch = $Glitch

@onready var click_2_continue = $ClickDetect/click2continue

#Authenthicating class.system_npc
#Error
#Your authenthication token is expired!
#Your connection has been blocked by Firewallis
#Retrying
#Retrying
#Retrying
#Securi isolated your process
#Reconnecting...

var c2stw : Tween
var sttw : Tween

# Called when the node enters the scene tree for the first time.
func _ready():
	var starttw : Tween = create_tween()
	starttw.tween_property(title,"position:y",156,1.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	starttw.parallel().tween_property(title,"modulate:a",1.0,0.25).set_ease(Tween.EASE_IN_OUT).set_delay(0.5)
	starttw.parallel().tween_property(story_text,"visible_ratio",1.0,0.25).set_ease(Tween.EASE_IN_OUT).set_delay(0.5)
	await starttw.finished
	
	c2stw = create_tween()
	c2stw.tween_property(click_2_start,"modulate:a",1.0,0.125).set_ease(Tween.EASE_IN_OUT)
	await c2stw.finished
	click_detect.show()

signal clicked
var started : bool = false
func _on_click_detect_gui_input(event : InputEvent):
	if event is InputEventMouse and event.button_mask in [MOUSE_BUTTON_LEFT,MOUSE_BUTTON_RIGHT]:
		if !started:
			started = true
			intro()
			click_2_continue.show()
		if event.button_mask == MOUSE_BUTTON_LEFT: 
			clicked.emit()
			click_detect.hide()
		elif event.button_mask == MOUSE_BUTTON_RIGHT:
			SystemUI.push_lateral({
			"speaker":"nme",
			"message":str("Skip!"),
			"type":LateralNotification.nt.SYSTEM,
			"duration":2.0
			})
			await SystemUI.set_background(true)
			App.to_config()
			queue_free()

func intro():
	SystemAudio.play(SoundLib.get_file_sfx(SoundLib.sound_files.NOTIFICATION_H))
	SystemAudio.play_music(SoundLib.get_file(SoundLib.music_files.NIGHTTIMENOPERC))
	sttw = create_tween()
	sttw.tween_property(title,"modulate:a",0.0,0.25).set_ease(Tween.EASE_IN_OUT)
	sttw.tween_property(story_text,"position:y",pos_center.position.y,0.25).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CIRC)
	
	await set_c2s("[center]Authenthicating [color=#8fc]class.[/color][color=#d4dad4]system_npc[/color][wave]...")
	await App.time_delay(1.0)
	
	click_detect.show()
	await clicked
	
	SystemAudio.stop_music(0.1)
	SystemAudio.play(SoundLib.get_file_sfx(SoundLib.sound_files.ERROR_A))
	await vfx_glitch()
	
	story_text.text = """
	[color=orange]Networkus Firewalla[/color] has blocked your process.
		Authenthication failed, Access DENIED.
		
		ERR. 344 - Bad Token
		00012@ PORT: 00034.00.22 
		<object>
			<object>"""
	await App.process_frame()
	center_st()
	
	await set_c2s("[color=orange]ERROR[/color]")
	await App.time_delay(1.0)
	
	click_detect.show()
	await clicked
	
	SystemAudio.play(SoundLib.get_file_sfx(SoundLib.sound_files.NOTIFICATION_H))
	story_text.text = "[center]GAUSSGRANDINE PROGRAM PORTAL"
	center_st()
	
	await vfx_glitch()
	await set_c2s("Retrying[wave]...")
	await App.time_delay(1.5)
	await vfx_glitch()
	await set_c2s("Failed. (1)")
	await App.time_delay(0.5)
	await vfx_glitch()
	await set_c2s("Retrying[wave]...")
	await App.time_delay(1.5)
	await vfx_glitch()
	await set_c2s("Failed. (2)")
	await App.time_delay(0.5)
	await vfx_glitch()
	await set_c2s("Retrying[wave]...")
	await App.time_delay(1.5)
	await vfx_glitch()
	await set_c2s("Failed. (3)")
	await App.time_delay(0.5)
	await set_c2s("Retrying[wave]...")
	await App.time_delay(1.0)
	
	#click_detect.show()
	#await clicked
	
	SystemAudio.play(SoundLib.get_file_sfx(SoundLib.sound_files.ERROR_A))
	await vfx_glitch()
	
	story_text.text = """
	[color=orange]Securi Programa[/color] has isolated your process.
		Automatic timeout, program sandboxed.
		
		ERR. 233 - Too Many Requests
		00012@ PORT: 00034.00.22 
		<object>
			<object>"""
	await App.process_frame()
	center_st()
	
	await set_c2s("[color=orange]ERROR[/color]")
	await App.time_delay(1.0)
	
	click_detect.show()
	await clicked
	
	await set_c2s("Connecting to new server[wave]...")
	await App.time_delay(1.0)
	
	click_detect.show()
	await clicked
	
	await SystemUI.set_background(true)
	App.to_config()
	queue_free()

func set_c2s(nt : String):
	c2stw = create_tween()
	c2stw.tween_property(click_2_start,"visible_ratio",0.0,0.125).set_ease(Tween.EASE_IN_OUT)
	await c2stw.finished
	click_2_start.text = nt
	c2stw = create_tween()
	c2stw.tween_property(click_2_start,"visible_ratio",1.0,0.125).set_ease(Tween.EASE_IN_OUT)
	await c2stw.finished

func vfx_glitch():
	var gtw : Tween = create_tween()
	gtw.tween_method(ssvog,0.0,2.0,0.125).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	gtw.tween_method(ssvog,2.0,0.0,0.125).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	await gtw.finished

func ssvog(nv : float):
	glitch.material.set_shader_parameter("sort",nv)

func center_st():
	await App.process_frame()
	story_text.size = Vector2.ZERO
	story_text.position.y = 180.0-(story_text.size.y / 2.0)
	story_text.position.x = 320.0-(story_text.size.x / 2.0)
