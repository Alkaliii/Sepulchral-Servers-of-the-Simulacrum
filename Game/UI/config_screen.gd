extends MarginContainer

@onready var name_input = $PanelContainer/HeaderVbc/nameInput
@onready var mp_options = $VBoxContainer/HBoxContainer/HBoxContainer

# Called when the node enters the scene tree for the first time.
func _ready():
	name_input.placeholder_text = App.player_name
	if OS.has_feature("pc"): mp_options.hide()
	
	name_input.text_submitted.connect(set_player_name)


var atw : Tween
func appear(state:bool):
	if atw: atw.kill()
	
	match state:
		true:
			SystemAudio.play_music(SoundLib.get_file(SoundLib.music_files.NIGHTTIMENOPERC))
			await SystemUI.set_background(true,Color("#b4b4b6"))
			show()
			atw = create_tween()
			atw.tween_property(self,"modulate:a",1.0,0.25).set_ease(Tween.EASE_IN_OUT)
			await atw.finished
		false:
			atw = create_tween()
			atw.tween_property(self,"modulate:a",0.0,0.25).set_ease(Tween.EASE_IN_OUT)
			await atw.finished
			hide()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

@onready var playbtn = $VBoxContainer/HBoxContainer/PLAY

func set_player_name(nnme : String):
	if nnme == "": return
	name_input.release_focus()
	if nnme.is_valid_filename():
		App.player_name = nnme
	else:
		SystemUI.sync_and_push_lateral({
		"speaker":"nme",
		"message":"Invalid Name!",
		"type":LateralNotification.nt.WARN,
		"duration":2.0
		})

func _on_play_pressed():
	set_player_name(name_input.text)
	playbtn.release_focus()
	appear(false)
	App.load_level(0) #THIS SHOULD BE ZERO

@onready var multiplayerbtn = $VBoxContainer/HBoxContainer/HBoxContainer/MULTIPLAYER
@onready var room_input = $VBoxContainer/HBoxContainer/HBoxContainer/roomInput
func _on_multiplayer_pressed():
	set_player_name(name_input.text)
	multiplayerbtn.release_focus()
	appear(false)
	await App.load_level(0)
	
	var rc = room_input.text
	if !str(rc).is_valid_identifier():
		rc = ""
	
	Plyrm._on_join_room_pressed(room_input.text)


@onready var settings = $VBoxContainer/HBoxContainer/SETTINGS
func _on_settings_pressed():
	settings.release_focus()
	SystemUI.open_settings(true)
