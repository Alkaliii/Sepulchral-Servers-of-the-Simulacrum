extends Node2D

#Manages The Arena
#eg. regenerating enviroment
#eg. placing down boss, player, and puppets

const PUPPET = preload("res://Game/puppet.tscn")
const DAMAGE_RADIUS = preload("res://Game/damage_radius.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	Plyrm.PR_PLAYER_JOIN.connect(on_player_join)
	App.spawn_dmg.connect(spawn_dmg)

func spawn_dmg(pos : Vector2, data : DamageRadiusSettings):
	var new = DAMAGE_RADIUS.instantiate()
	new.settings = data
	add_child(new)
	new.top_level = true
	new.global_position = pos
	new.warn()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func on_player_join(args):
	if Plyrm.PLAYER and args[0].id == Plyrm.PLAYER.id: return
	var inst = PUPPET.instantiate()
	add_child(inst)
	inst.position.x = randf_range(30,60)
	inst.my_id = args[0].id
	
	inst.state = args[0]
