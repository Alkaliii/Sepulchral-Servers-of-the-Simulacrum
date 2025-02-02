extends Control


# Called when the node enters the scene tree for the first time.
func _ready():
	await App.time_delay(1.0)
	
	SystemAudio.play_music(SoundLib.get_file(SoundLib.music_files.BEYOND_SCORCHED_SKIES),Vector2(2,2),true)
	await SystemUI.set_title(false)
	#SystemUI.set_background(false)
	SystemUI.fade_background()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass


@onready var ali = $MarginContainer/HBoxContainer/Me/ali
func _on_ali_pressed():
	ali.release_focus()
	OS.shell_open("https://alkaliii.itch.io/")

@onready var andrea = $MarginContainer/HBoxContainer/firstcol/Musicians/andrea
func _on_andrea_pressed():
	andrea.release_focus()
	OS.shell_open("https://andreabaroni.com/")

@onready var chris = $MarginContainer/HBoxContainer/firstcol/Musicians/chris
func _on_chris_pressed():
	chris.release_focus()
	OS.shell_open("https://chrislsound.com/")

@onready var ryan = $MarginContainer/HBoxContainer/firstcol/Musicians/ryan
@onready var ryan2 = $MarginContainer/HBoxContainer/firstcol/SoundDesigners/ryan
func _on_ryan_pressed():
	ryan.release_focus()
	ryan2.release_focus()
	OS.shell_open("https://audiojungle.net/user/blinnaudio?ref=Blinn")

@onready var youfulca = $MarginContainer/HBoxContainer/firstcol/Musicians/youfulca
func _on_youfulca_pressed():
	youfulca.release_focus()
	OS.shell_open("https://youfulca.com/en/profile/")

@onready var atelier = $MarginContainer/HBoxContainer/firstcol/SoundDesigners/atelier
func _on_atelier_pressed():
	atelier.release_focus()
	OS.shell_open("https://ateliermagicae.itch.io/")

@onready var denisse = $MarginContainer/HBoxContainer/firstcol/SoundDesigners/denisse
func _on_denisse_pressed():
	denisse.release_focus()
	OS.shell_open("https://beacons.ai/denissetakes")

@onready var kenney = $MarginContainer/HBoxContainer/firstcol/SoundDesigners/kenney
func _on_kenney_pressed():
	kenney.release_focus()
	OS.shell_open("https://kenney.nl/")

@onready var noam = $MarginContainer/HBoxContainer/firstcol/SoundDesigners/noam
func _on_noam_pressed():
	noam.release_focus()
	OS.shell_open("https://noamguterman.dev/")

@onready var playroom = $MarginContainer/HBoxContainer/seccol/SpecialThanks/playroom
func _on_playroom_pressed():
	playroom.release_focus()
	OS.shell_open("https://joinplayroom.com/")

@onready var godot = $MarginContainer/HBoxContainer/seccol/SpecialThanks/godot
func _on_godot_pressed():
	godot.release_focus()
	OS.shell_open("https://godotengine.org/")

@onready var playtesters = $MarginContainer/HBoxContainer/seccol/SpecialThanks/playtesters
func _on_playtesters_pressed():
	playtesters.release_focus()
	SystemUI.push_lateral({
	"speaker":"Ali",
	"message":"THANKS SO MUCH!",
	"type":LateralNotification.nt.SPECIAL,
	"duration":3.0
	})
