extends Panel

var song = ""
var song_name = ""
var score = 0
var length = 0
var producer = ""
var difficulty = 0
var completed = false
var nosong = false
var combo = 0
var times_played = 0
var total = 0
var id = 0
var checkpoint = 0

var color = Color(1,1,1,1)
var selected = false

var gonna_touch = false

@onready var main = $"../.."

func _ready():
	if !completed:
		$Label7.hide()
		$Label8.hide()
		$Label9.hide()
		print(checkpoint)
		if checkpoint != 0: $Label10.show()
		else: $Label10.hide()
	else:
		$Label10.hide()
	#print(nosong,",",song_name)
	$Label6.visible = nosong
	#if nosong: $Label6.text = "#"
	#print($Label6.visible)
	$Label.text = song_name
	$Label4.text = producer
	$Label7.text = str(int(combo))
	$Label8.text = str(int(times_played))
	$Label9.text = str(int(total))
	$Label10.text = str(checkpoint)+"%"
	#print(difficulty,",",typeof(difficulty))
	var d = snapped(difficulty,0.5)
	for i in range(1,6):
		if d >= i: get_node("stars/"+str(i)).frame = 2
		if d == i - 0.5: get_node("stars/"+str(i)).frame = 1
		if d < i - 0.5: get_node("stars/"+str(i)).frame = 0
	#match snapped(difficulty,0.5):
		#1.0: $Label5.text = "★☆☆☆☆"
		#1.5: $Label5.text = "★⯪☆☆☆"
		#2.0: $Label5.text = "★★☆☆☆"
		#2.5: $Label5.text = "★★⯪☆☆"
		#3.0: $Label5.text = "★★★☆☆"
		#3.5: $Label5.text = "★★★⯪☆"
		#4.0: $Label5.text = "★★★★☆"
		#4.5: $Label5.text = "★★★★⯪"
		#5.0: $Label5.text = "★★★★★"
		#_: $Label5.text = str(difficulty) + " ★"
	#if OS.get_name() == "Android": $Label5.text = str(difficulty) + " ★"
	if score < 100:
		$Label2.text = str(snapped(score,0.01))
		match $Label2.text.length():
			1: $Label2.text = "0"+$Label2.text+".00%"
			2: $Label2.text = $Label2.text+".00%"
			4: $Label2.text = $Label2.text+"0%"
			5: $Label2.text = $Label2.text+"%"
	else:
		$Label2.text = "100.00%"
	if score >= 80:
		if score >= 90:
			if score >= 95:
				if score >= 98:
					if score >= 100:
						color = Color.YELLOW
					else:
						color = Color.MAGENTA
				else:
					color = Color.CYAN
			else:
				color = Color.GREEN
		else:
			color = Color.BLUE
	else:
		color = Color.RED
	$Label3.text = secs2mins(snapped(length,1))

func _process(delta: float) -> void:
	if selected:
		self_modulate = color.blend(Color(1,1,1,0.8))
		#self_modulate = color.blend(Color(1,1,0))
		#print(self_modulate,",",color)
	else:
		self_modulate = color
	if (main.dragging or main.drag_free) && is_equal_approx(snapped(global_position.y,16),main.vbox_y) && completed == main.completed:
		main.active_vbox.get_node(str(main.songs_showing[main.selected].id)).selected = false
		selected = true
		
		main.selected = main.active_refs.find(self)
	#if selected: print(global_position.y)

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch && event.pressed:
		gonna_touch = true
	if main.dragging: gonna_touch = false
		
	if !main.dragging && !main.settings_open && (get_global_rect().has_point(get_global_mouse_position()) && event is InputEventMouseButton && get_global_mouse_position().y >= 64) or (event is InputEventScreenTouch && get_global_rect().has_point(event.position) && event.position >= 64):
		if !selected:
			if (event is InputEventMouseButton && event.is_action_released("left_click")) or (event is InputEventScreenTouch && !event.pressed && gonna_touch):
				print($"../..".songs_showing)
				var c = -1
				for i in $"../..".songs_showing:
					c += 1
					if i.song == song: $"../..".selected = c
				#$"../..".selected = $"../..".songs_showing.find(song)
				GL.settings.last_song = $"../..".songs_showing[$"../..".selected].song
				#GL.save()
		else:
			if (event is InputEventMouseButton && event.double_click) or (event is InputEventScreenTouch && event.double_tap):
				$"../.."._on_play_pressed()


func secs2mins(s):
	var secs = s
	var mins = 0
	while secs >= 60:
		secs -= 60
		mins += 1
	var secs_str = str(secs)
	var mins_str = str(mins)
	if secs < 10:
		secs_str = secs_str.insert(0,"0")
	if mins < 10:
		mins_str = mins_str.insert(0,"0")
	return mins_str+":"+secs_str
