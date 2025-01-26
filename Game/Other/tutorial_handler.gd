extends Node

#{"obj":"",
	#"help":""}

@export var objective_ui : ObjectiveNotification

var tutorial_text = [
	{"obj":"Find the scarecrow",
	"help":"Use [color=f2b63d][wave][WASD][/wave][/color] to move around!"},
	
	{"obj":"Allocate memory to cache",
	"help":"Press [color=f2b63d][wave][SPACEBAR][/wave][/color] to dash!"},
	
	{"obj":"Attack the scarecrow (4x)",
	"help":"After allocating memory, use [color=f2b63d][wave]LEFT CLICK[/wave][/color] to attack!"},
	
	{"obj":"Overclock your hard disk",
	"help":"Hold [color=f2b63d][wave]RIGHT CLICK[/wave][/color] and draw a circle around yourself!"},
	
	{"obj":"Use a heavy attack (2x)",
	"help":"Use [color=f2b63d][wave]RIGHT CLICK[/wave][/color] after overclocking to heavy attack!"},
	
	{"obj":"Equip a weapon",
	"help":"Press [color=f2b63d][wave]ONE [1][/wave][/color] to access your inventory!"},
	
	{"obj":"Express yourself",
	"help":"Press [color=f2b63d][wave]SLASH [/][/wave][/color] to open text chat!"}
]

var watch_WASD : bool = false
var WASD_progress : float = 0.0

var watch_SPACEBAR : bool = false
var SPACEBAR_progress : float = 0.0

var watch_LIGHT_ATTACK : bool = false
var LIGHT_ATTACK_progress : float = 0.0

var watch_SPIN : bool = false
var SPIN_progress : float = 0.0

var watch_HEAVY_ATTACK : bool = false
var HEAVY_ATTACK_progress : float = 0.0

var watch_WEAPON : bool = false
var watch_CHAT : bool = false

const OLD_BLADE = preload("res://Game/Content/DefaultWeapons/OldBlade.tres")
const OLD_DAGGER = preload("res://Game/Content/DefaultWeapons/OldDagger.tres")
const OLD_STAFF = preload("res://Game/Content/DefaultWeapons/OldStaff.tres")

func _ready():
	pass
	#coonect to signal for starting it
	App.tutorial_click.connect(on_click)
	
	await App.time_delay(4.0)
	start_tutorial()

var track_spin
var track_weapon
var player
func _process(delta):
	if watch_WASD:
		if Input.get_vector("MLEFT", "MRIGHT", "MUP", "MDOWN").length() >= 0.3:
			WASD_progress += delta * 0.2
			objective_ui.set_objective_progress(clamp(WASD_progress,0.0,1.0))
		if WASD_progress >= 1.0:
			watch_WASD = false
			next_objective()
	
	if watch_SPACEBAR:
		if Input.is_action_just_pressed("ACTIONA"):
			SPACEBAR_progress += 1.0/3.0
			objective_ui.set_objective_progress(clamp(SPACEBAR_progress,0.0,1.0))
		if SPACEBAR_progress >= 1.0:
			watch_SPACEBAR = false
			next_objective()
	
	if watch_SPIN:
		if track_spin != App.revolutions_made:
			track_spin = App.revolutions_made
			SPIN_progress += 1.0/4.0
			objective_ui.set_objective_progress(clamp(SPIN_progress,0.0,1.0))
		if SPIN_progress >= 1.0:
			watch_SPIN = false
			next_objective()
	
	if watch_WEAPON:
		if track_weapon != player.weapon:
			watch_WEAPON = false
			next_objective()
	
	if watch_CHAT:
		if Input.is_action_just_pressed("open_console"):
			watch_CHAT = false
			await App.time_delay(1.0)
			next_objective()

func on_click(click : int):
	if watch_LIGHT_ATTACK and click == 0:
		LIGHT_ATTACK_progress += 1.0/4.0
		objective_ui.set_objective_progress(clamp(LIGHT_ATTACK_progress,0.0,1.0))
		
		if LIGHT_ATTACK_progress >= 1.0:
			watch_LIGHT_ATTACK = false
			next_objective()
	
	if watch_HEAVY_ATTACK and click == 1:
		HEAVY_ATTACK_progress += 1.0/2.0
		objective_ui.set_objective_progress(clamp(HEAVY_ATTACK_progress,0.0,1.0))
		
		if HEAVY_ATTACK_progress >= 1.0:
			watch_HEAVY_ATTACK = false
			next_objective()

var tutorial_idx : int = 0
func start_tutorial():
	if !objective_ui: return
	SystemAudio.play_music(SoundLib.get_file(SoundLib.music_files.NIGHTTIME))
	await App.time_delay(1.0)
	await objective_ui.set_objective(tutorial_text[tutorial_idx])
	watch_WASD = true

func next_objective():
	tutorial_idx += 1
	
	if tutorial_idx == 6 and !Plyrm.connected:
		complete_tutorial()
		return
	
	if tutorial_idx < 7:
		await objective_ui.set_objective(tutorial_text[tutorial_idx])
	
	match tutorial_idx:
		0: #WASD
			pass
		1: #SPACEBAR
			watch_SPACEBAR = true
		2: #LIGHT ATTACK
			watch_LIGHT_ATTACK = true
		3: #SPIN
			track_spin = App.revolutions_made
			watch_SPIN = true
		4: #HEAVY ATTACK
			watch_HEAVY_ATTACK = true
		5: #WEAPON
			if App.weapon_inventory.is_empty():
				App.weapon_inventory.append(OLD_DAGGER)
				App.weapon_inventory.append(OLD_BLADE)
				App.weapon_inventory.append(OLD_STAFF)
			elif [true,false,false,false].pick_random(): 
				tutorial_secret()
			player = get_tree().get_first_node_in_group("player")
			track_weapon = player.weapon
			watch_WEAPON = true
		6: #TEXT CHAT
			watch_CHAT = true
		7: #FINISHED YAY!
			complete_tutorial()

func complete_tutorial():
	await objective_ui.hide_obj()
	SystemAudio.play(SoundLib.get_file_sfx(SoundLib.sound_files.NOTIFICATION_D))
	SystemUI.push_lateral({
	"speaker":"nme",
	"message":"Tutorial complete!",
	"type":LateralNotification.nt.SYSTEM,
	"duration":4.0
	})
	SystemAudio.play_music(SoundLib.get_file(SoundLib.music_files.NIGHTTIMENOPERC))
	
	#map select open, ready up on MP/load selected map in SP

func tutorial_secret():
	SystemAudio.play(SoundLib.get_file_sfx(SoundLib.sound_files.NOTIFICATION_D))
	SystemUI.push_lateral({
	"speaker":"nme",
	"message":"You found a secret!",
	"type":LateralNotification.nt.SYSTEM,
	"duration":4.0
	})
	var tut_secret_weapon = system_weapon.new()
	tut_secret_weapon.generate_random()
	App.weapon_inventory.append(tut_secret_weapon)
