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
	hit_detector.CLICKED.connect(on_click)
	pull_vfx.emitting = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func blurry():
	await SystemUI.blur_effect(true)
	await App.time_delay(0.5)
	await SystemUI.blur_effect(false)

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
	player.set_job()
	
	await SystemUI.set_title(true,2,str(system_job.j.keys()[select]).replace("_"," "),"JOB CHANGED",Color("#8fc"))
	await App.time_delay(3.0)
	SystemUI.set_title(false)
	
	var ana = "an" if system_job.j.keys()[select][0] in ["a","e","i","o","u"] else "a"
	
	SystemUI.push_lateral({
	"speaker":"nme",
	"message":str("You became ",ana," [color=88ffcc]",str(system_job.j.keys()[select]).replace("_"," "),"!"),
	"type":LateralNotification.nt.SYSTEM,
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
	"speaker":"nme",
	"message":str("~max cache increased!"),
	"type":LateralNotification.nt.SYSTEM,
	"duration":4.0
	})

func charge_up():
	player.job.additional_pcache_charge_amt += 1
	player.set_job()
	SystemUI.push_lateral({
	"speaker":"nme",
	"message":str("~malloc size increased!"),
	"type":LateralNotification.nt.SYSTEM,
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
	"speaker":"nme",
	"message":str("~health increased! (+",increase,")"),
	"type":LateralNotification.nt.SYSTEM,
	"duration":4.0
	})

func damage_up():
	var rand = RandomNumberGenerator.new()
	var increase := health_increases[rand.rand_weighted(health_weights)]
	player.job.additional_damage += increase
	player.set_job()
	SystemUI.push_lateral({
	"speaker":"nme",
	"message":str("~damage increased! (+",increase,")"),
	"type":LateralNotification.nt.SYSTEM,
	"duration":4.0
	})

func nothing_happened():
	SystemUI.push_lateral({
	"speaker":"nme",
	"message":str("nothing seemed to happen"),
	"type":LateralNotification.nt.SYSTEM,
	"duration":4.0
	})

func on_click():
	if clicked: return
	player = get_tree().get_first_node_in_group("player_persistant")
	clicked = true
	pull_vfx.emitting = false
	
	await blurry()
	
	var rand = RandomNumberGenerator.new()
	match rand.rand_weighted(weights):
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
