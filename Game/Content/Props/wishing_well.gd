extends Node2D

@onready var hit_detector = $HitDetector
#Random job change (~6.25%) 1
#Max Charge up (~6.25%) 1 
#Charge up (~12.5%) 2
#Health up (~25%) 4
#Damage up (~25%) 4
#Nothing (~25%) 3
@onready var pull_vfx = $PullVFX
@onready var starburst = $Starburst

const weights = [1.0,1.0,2.0,4.0,4.0,3.0]
var clicked : bool = false
var player : system_controller

# Called when the node enters the scene tree for the first time.
func _ready():
	if Plyrm.connected: 
		Plyrm.PLAYER.state.setState("pMapSelect",false)
		Plyrm.PLAYER.state.setState("pREADY",false)
	
	create_tween().tween_property(self,"modulate:a",1.0,0.5).set_ease(Tween.EASE_IN_OUT).set_delay(1.0)
	App.can_job_change = true
	hit_detector.disabled = true
	add_to_group("monster")
	hit_detector.CLICKED.connect(on_click)
	pull_vfx.emitting = true
	
	await App.time_delay(3.0)
	pull_vfx.emitting = true
	hit_detector.disabled = false
	SystemAudio.play(SoundLib.get_file_sfx(SoundLib.sound_files.LEVEL_SKYLIGHT))
	SystemAudio.play_music(SoundLib.get_file(SoundLib.music_files.NIGHTTIME))
	
	#"Press [color=f2b63d][wave]ONE [1][/wave][/color] to access your inventory!"
	SystemUI.push_lateral({
	"speaker":"s",
	"message":"You can change your job here.",
	"type":LateralNotification.nt.SYSTEM
	})
	
	SystemUI.push_lateral({
	"speaker":"s",
	"message":"Press [color=f2b63d][wave]ONE [1][/wave][/color] to do so!",
	"type":LateralNotification.nt.SYSTEM
	})

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func blurry():
	hit_detector.disabled = true
	await SystemUI.blur_effect(true)
	await App.time_delay(0.5)
	await SystemUI.blur_effect(false)
	hit_detector.disabled = false

const KNIGHT_TREE = [
	system_job.j.KNIGHT, system_job.j.LEGIONNAIRE, system_job.j.MAGIC_KNIGHT, system_job.j.HIGH_PALADIN, system_job.j.GUARDIAN ]
const MAGE_TREE = [
	system_job.j.MAGE, system_job.j.ARCANE_MYSTIC, system_job.j.MAGIC_KNIGHT, system_job.j.DIVINE_SAGE, system_job.j.SIBYL ]
const SAINT_TREE = [
	system_job.j.SAINT, system_job.j.OCCULT_PSYCHIC, system_job.j.DIVINE_SAGE, system_job.j.HIGH_PALADIN, system_job.j.ORACLE ]
const JOB_WEIGHTS = [4,4,2,2,1]

func new_job():
	#select tree
	var possible_trees : Array[Array] = []
	if player.job.JOB in KNIGHT_TREE: possible_trees.append(KNIGHT_TREE)
	if player.job.JOB in MAGE_TREE: possible_trees.append(MAGE_TREE)
	if player.job.JOB in SAINT_TREE: possible_trees.append(SAINT_TREE)
	possible_trees.append([KNIGHT_TREE,MAGE_TREE,SAINT_TREE].pick_random())
	
	var tree : Array
	tree = possible_trees.pick_random()
	
	var rand = RandomNumberGenerator.new()
	var select = tree[rand.rand_weighted(JOB_WEIGHTS)]
	
	player.job.JOB = select
	if !App.job_inventory.has(select): App.job_inventory.append(select)
	player.set_job()
	
	await SystemUI.set_title(true,2,str(system_job.j.keys()[select]).replace("_"," "),"JOB CHANGED",Color("#8fc"))
	await App.time_delay(3.0)
	SystemUI.set_title(false)
	
	var ana = "an" if system_job.j.keys()[select][0] in ["a","e","i","o","u"] else "a"
	
	SystemUI.push_lateral({
	"speaker":"(!)",
	"message":str("You became ",ana," [color=88ffcc]",str(system_job.j.keys()[select]).replace("_"," "),"!"),
	"type":LateralNotification.nt.SPECIAL,
	"duration":4.0
	})
	SystemUI.sync_lateral({
	"speaker":str(App.player_name),
	"message":"changed job!",
	"type":LateralNotification.nt.CHAT
	})

func max_charge_up():
	player.job.additional_max_pcache += 1
	player.set_job()
	SystemUI.push_lateral({
	"speaker":"(!)",
	"message":str("~max cache increased!"),
	"type":LateralNotification.nt.SPECIAL,
	"duration":4.0
	})

func charge_up():
	player.job.additional_pcache_charge_amt += 1
	player.set_job()
	SystemUI.push_lateral({
	"speaker":"(!)",
	"message":str("~malloc size increased!"),
	"type":LateralNotification.nt.SPECIAL,
	"duration":4.0
	})

const health_weights = [8,2,1]
const health_increases : Array[int] = [1,2,3]
func health_up():
	var rand = RandomNumberGenerator.new()
	var increase := health_increases[rand.rand_weighted(health_weights)]
	player.job.additional_health += increase
	player.set_job()
	SystemUI.push_lateral({
	"speaker":"(!)",
	"message":str("~health increased! (+",increase,")"),
	"type":LateralNotification.nt.SPECIAL,
	"duration":4.0
	})

func damage_up():
	var rand = RandomNumberGenerator.new()
	var increase := health_increases[rand.rand_weighted(health_weights)]
	player.job.additional_damage += increase
	player.set_job()
	SystemUI.push_lateral({
	"speaker":"(!)",
	"message":str("~damage increased! (+",increase,")"),
	"type":LateralNotification.nt.SPECIAL,
	"duration":4.0
	})

func nothing_happened():
	SystemUI.push_lateral({
	"speaker":"(!)",
	"message":str("nothing seemed to happen"),
	"type":LateralNotification.nt.SYSTEM,
	"duration":4.0
	})

func sfx():
	var sound = [SoundLib.sound_files.NOTIFICATION_E,SoundLib.sound_files.NOTIFICATION_F]
	SystemAudio.play(SoundLib.get_file_sfx(sound.pick_random()))

func on_click():
	if clicked:
		App.can_job_change = false
		hit_detector.disabled = true
		await App.time_delay(0.25)
		SystemUI.open_level_select(true)
		return
	player = get_tree().get_first_node_in_group("player_persistant")
	clicked = true
	pull_vfx.emitting = false
	SystemUI.push_lateral({
	"speaker":"(!)",
	"message":str("You make a wish!"),
	"type":LateralNotification.nt.SYSTEM,
	"duration":4.0
	})
	
	var rand = RandomNumberGenerator.new()
	var pick = rand.rand_weighted(weights)
	if pick < 5: sfx()
	await blurry()
	
	match pick:
		0: #Job Change
			await new_job()
			starburst.emitting = true
		1: #Max Charge Up
			max_charge_up()
			starburst.emitting = true
		2: #Charge up
			charge_up()
			starburst.emitting = true
		3: #Health up
			health_up()
			starburst.emitting = true
		4 when player and player.job and player.job.additional_damage <= 9: #Damage up
			damage_up()
			starburst.emitting = true
		5: #Nothing
			nothing_happened()
		_: #Nothing again
			nothing_happened()
	
	await App.time_delay(0.5)
	SystemUI.push_lateral({
		"speaker":"nme",
		"message":str("click again to continue"),
		"type":LateralNotification.nt.SYSTEM,
		"duration":4.0
	})
