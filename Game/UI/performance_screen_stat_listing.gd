extends HBoxContainer
class_name perfStatListing


@onready var namelbl = $name
@onready var dmg = $dmg
@onready var healing = $healing
@onready var spins = $spins
@onready var clicks = $clicks

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func setlisting(data : Dictionary):
	namelbl.text = str("[wave]",data["name"])
	dmg.text = str(data["dmg"])
	healing.text = str(data["heal"])
	spins.text = str(data["rev"])
	clicks.text = str(data["click"])
