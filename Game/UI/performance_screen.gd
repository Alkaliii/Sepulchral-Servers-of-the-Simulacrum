extends MarginContainer

@onready var list = $StatList/list

#battle ends
#clients notified
#clents stash stats in player state?
#data ready by the time this screen opens...

#this screen will award you a weapon

@onready var tdmglbl = $StatList/statTotals/dmg
@onready var thealinglbl = $StatList/statTotals/healing
@onready var tclickslbl = $StatList/statTotals/clicks
@onready var trevlbl = $StatList/statTotals/rev
@onready var b_health = $StatList/bHealth
@onready var timetaken = $StatList/Time


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

const STAT_LISTING = preload("res://Game/UI/performance_screen_stat_listing.tscn")
func size_list():
	var dif = App.validate_players() - list.get_child_count()
	if dif < 0: #Negative, need to remove spots
		for i in dif:
			var remove = list.get_child(list.get_child_count() - 1)
			list.remove_child(remove)
			remove.queue_free()
	else: #Positive or Zero, add or do nothing
		for i in dif:
			var add =STAT_LISTING.instantiate()
			list.add_child(add)

var atw : Tween
func appear(state:bool):
	if atw: atw.kill()
	
	match state:
		true: #show
			await SystemUI.set_title(false)
			await SystemUI.set_background(true,Color("#b4b4b6"))
			show()
			atw = create_tween()
			atw.tween_property(self,"position:x",0.0,0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
			await atw.finished
		false:
			atw = create_tween()
			atw.tween_property(self,"position:x",-get_viewport().size.x,0.5).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
			await atw.finished
			position.x = 640
			hide()
			

func setlist():
	size_list()
	
	var perfdata : Array = []
	var total_dmg = 0
	var total_heal = 0
	var total_rev = 0
	var total_click = 0
	var ttl_time_taken = 0
	var ttl_boss_health = 0
	
	if Plyrm.connected:
		#get everyones data, also compare it, also total it?
		var all_dmg : Array = []
		var all_heal : Array = []
		var all_rev : Array = []
		var all_click : Array = []
		for i in Plyrm.connected_players:
			var metric = i.getState("pMetrics")
			var data
			if metric:
				data = JSON.parse_string(metric)
			else: continue
			perfdata.append(data)
			all_dmg.append(data.dmg)
			all_heal.append(data.heal)
			all_rev.append(data.rev)
			all_click.append(data.click)
		
		for i in perfdata:
			if i.name == App.player_name: i.name = "YOU"
			total_dmg += i.dmg
			if i.dmg == all_dmg.max(): i.dmg = str("[shake]",i.dmg,"!")
			total_heal += i.heal
			if i.heal == all_heal.max(): i.heal = str("[shake]",i.heal,"!")
			total_rev += i.rev
			if i.rev == all_rev.max(): i.rev = str("[shake]",i.rev,"!")
			total_click += i.click
			if i.click == all_click.max(): i.click = str("[shake]",i.click,"!")
		
		var boss_metric = Plyrm.Playroom.getState("bMetrics")
		var bm_data 
		if boss_metric: bm_data = JSON.parse_string(boss_metric)
		if bm_data:
			ttl_time_taken = bm_data.time
			ttl_boss_health = bm_data.bhp
	else:
		perfdata.append({
			"name":App.player_name,
			"dmg":App.dmg_dealt,
			"heal":App.healing_performed,
			"rev":App.revolutions_made,
			"click":App.clicks_made
		})
		
		total_dmg = App.dmg_dealt
		total_heal = App.healing_performed
		total_rev = App.revolutions_made
		total_click = App.clicks_made
		ttl_time_taken = App.performance_screen_details["time"]
		ttl_boss_health = App.performance_screen_details["bhp"]
		
		if perfdata[0]["dmg"] > App.performance_screen_details["bhp"]:
			perfdata[0]["dmg"] = str("[shake]",perfdata[0]["dmg"],"!")
	
	var idx = 0
	for i : perfStatListing in list.get_children():
		i.setlisting(perfdata[idx])
		idx += 1
	
	tdmglbl.text = str(total_dmg)
	thealinglbl.text = str(total_heal)
	trevlbl.text = str(total_rev)
	tclickslbl.text = str(total_click)
	timetaken.text = str("time/ ",seconds2hhmmss(ttl_time_taken))
	b_health.text = str(ttl_boss_health," hp")
	
	appear(true)

func seconds2hhmmss(total_seconds: float) -> String:
	#total_seconds = 12345
	var seconds:float = fmod(total_seconds , 60.0)
	var minutes:int   =  int(total_seconds / 60.0) % 60
	var hours:  int   =  int(total_seconds / 3600.0)
	var hhmmss_string:String = "%02d:%02d:%05.2f" % [hours, minutes, seconds]
	return hhmmss_string
