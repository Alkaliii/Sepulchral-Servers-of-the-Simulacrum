extends Node2D

var stroke : Line2D

signal circle_drawn

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_pressed("ACTIONC"):
		var pos = get_local_mouse_position()
		if !stroke:
			create_stroke()
		if stroke.points.is_empty() and Input.is_action_just_pressed("ACTIONC"):
			stroke.add_point(pos)
			stroke.default_color = Color("#ffffff14")
		elif !stroke.points.is_empty() and (stroke.points[stroke.get_point_count() - 1] - pos).length() >= 5:
			stroke.add_point(pos)
			eval_stroke()
	elif Input.is_action_just_released("ACTIONC"):
		if stroke: stroke.clear_points()

func create_stroke():
	var s = Line2D.new()
	s.width = 2
	s.default_color = Color("#ffffff14")
	s.joint_mode = Line2D.LINE_JOINT_ROUND
	s.begin_cap_mode = Line2D.LINE_CAP_ROUND
	s.end_cap_mode = Line2D.LINE_CAP_ROUND
	add_child(s)
	stroke = s

const centoid_tolerance := 50
## Thanks Stack Overflow! https://stackoverflow.com/questions/2393553/simple-circular-gesture-detection
func eval_stroke():
	#Looks at points in line 3D and determines if they are "circular"
	#Or at the very least a continious curve with interior angles of atleast 340 and a centoid near (0,0)
	if !stroke or stroke.points.is_empty(): return
	
	var np : Vector2 #next_point
	var angle : float
	var prev_angle : float = 0.0
	var angle_diff : float
	var degree_accum : float = 0.0
	var average_point : Vector2
	#var angle_accum : Array = []
	for i : Vector2 in stroke.points:
		if stroke.points.find(i) + 1 >= stroke.get_point_count(): continue
		np = stroke.points[(stroke.points.find(i) + 1) % stroke.get_point_count()]
		angle = atan2(np.y - i.y,np.x - i.x)
		average_point.x += i.x
		average_point.y += i.y
		
		angle_diff = rad_to_deg(abs(angle_difference(angle,prev_angle)))
		
		if stroke.points.find(i) != 0 and (angle_diff < 80):
			degree_accum += angle_diff #abs(prev_angle-angle)
		elif stroke.points.find(i) != 0: print("bad angle!")
		#angle_accum.append([round(rad_to_deg(abs(angle_difference(angle,prev_angle)))),round(rad_to_deg(prev_angle)),round(rad_to_deg(angle))])
		prev_angle = angle
	
	var centoid = Vector2(average_point.x / float(stroke.get_point_count()),average_point.y / float(stroke.get_point_count()))
	var horizontal_eval = centoid.x < centoid_tolerance and centoid.x > -centoid_tolerance
	var vertical_eval = centoid.y < centoid_tolerance and centoid.y > -centoid_tolerance
	
	if degree_accum > 340 and (horizontal_eval and vertical_eval):
		#print("full circle!", centoid)
		var f = stroke.points[stroke.get_point_count() - 1]
		stroke.clear_points()
		stroke.add_point(f)
		if stroke.default_color != Color("#ffffff14"):
			stroke.default_color = Color("#ffffff14")
		else: circle_drawn.emit()
		#print("full circle! ",degree_accum," ",angle_accum)
	elif degree_accum > 340:
		#print("off center!")
		stroke.default_color = Color("#e34262")
