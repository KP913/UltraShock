extends Node2D

@onready var item = preload("res://menu_songs.tscn")

var songs = []
var songs_c = []
var songs_u = []
var songs_showing = []
var order_c = []
var order_u = []
var refs_c = []
var refs_u = []
var active_refs = []

var selected_c = 0
var selected_u = 0
var selected = 0

var active_vbox
const vbox_y = 256
const vbox_scale = 1.3

var unsnapped_pos = 0
var dragging = false
var drag_free = false
var free_speed = 0

var position_temp = null

var completed = true

var funny = 0

var scores
var settings_open = false


func _ready():
	Engine.time_scale = 1
	if OS.get_name() == "Android":
		$touch.show()
	print(OS.get_user_data_dir())
	$Label.text = OS.get_user_data_dir()
	#var c
	if !FileAccess.file_exists(GL.systemdir+"scores.save"):
		var r = FileAccess.open(GL.systemdir+"scores.save",FileAccess.WRITE)
		r.store_string("[]")
		scores = []
		r.close()
	else:
		var scores_file = FileAccess.open(GL.systemdir+"scores.save",FileAccess.READ)
		scores = JSON.parse_string(scores_file.get_as_text())
	
	if !DirAccess.dir_exists_absolute(GL.systemdir+"songs"):
		DirAccess.make_dir_absolute(GL.systemdir+"songs")
	
	var d = DirAccess.open(GL.systemdir+"songs")
	d.list_dir_begin()
	var id = 0
	while true:
		var folder = d.get_next()
		if folder == "": break
		#var filepath = GL.systemdir+file
		var path = GL.systemdir+"songs/"+folder+"/"
		if !FileAccess.file_exists(path+"level.lvl") or folder.begins_with("."): continue
		var song = folder
		
		load_level(song,id)
		id += 1
		#$VBoxContainer.add_child(a)
	d.list_dir_end()
	GL.sorted = GL.settings.sorting
	
	#dir.list_dir_end()
	#songs_showing = songs_c if completed else songs_u
	update_actives()
	var b
	for i in songs:
		if i.song == GL.settings.last_song: b = i
	if GL.settings.last_song != "" && b:
		#print(GL.settings.last_song)
		var a = GL.settings.last_song
		select_song(a)
	else: songs_showing = songs.duplicate()
	if songs != []: sort(GL.settings.sorting)
	#print(GL.settings.sorting)
	setup_touch()
	#print(order_c)
	
	for i in ["Name","Producer","Score","Difficulty","Notes","Clears","Combo"]: $Sort.add_item(i)
	$Sort.select(["name","producer","score","difficulty","notes","times_played","combo"].find(GL.settings.sorting))
	
	$Gamemode.selected = GL.settings.gamemode
	#for i in ["Normal", ""]
	
	if songs == []:
		$no_songs.show()
		$no_songs/Label.text += OS.get_user_data_dir()
	
	
	var style = $Settings.get_theme_stylebox("panel").duplicate()
	style.bg_color = Color(0.2,0.2,0.2,1)
	$Settings.add_theme_stylebox_override("panel",style)

func update_settings():
	pass


func load_level(song,id):
	#200 ms
	var path = GL.systemdir+"songs/"+song+"/"
	var a = item.instantiate()
	a.song = song
	var score
	for i in scores:
		if i.song == song:
			score = i
	var combo = 0
	if score != null:
		a.score = score.score
		combo = score.combo
		a.combo = score.combo
		if score.has("times_played"):a.times_played = score.times_played
		#2 ms
		#if FileAccess.file_exists(path+"music.ogg"):
			#if !score.has("time"):
				#var q
				#q = load_audio(path+"music.ogg")
				#a.length = q.get_length()
				#var r = FileAccess.open(GL.systemdir+"scores.save",FileAccess.READ_WRITE)
				#var temp = JSON.parse_string(r.get_as_text())
				#for i in temp:
					#if i.song == song:
						#i.time = a.length
				#r.store_string(JSON.stringify(temp))
				#r.close()
			#else: a.length = score.time
	#else:
		#if FileAccess.file_exists(path+"music.ogg"):
			#var q = load_audio(path+"music.ogg")
			#a.length = q.get_length()
	p2(path,song,a,id,combo)
func p2(path,song,a,id,combo):
	var lvl
	if GL.cached_levels.has(song):
		#pouco ms
		lvl = GL.cached_levels[song]
	else:
		#135 ms
		var r = FileAccess.open(path+"level.lvl",FileAccess.READ)
		#800 ms
		lvl = JSON.parse_string(r.get_as_text()) #!!!!
		r.close()
	p21(lvl,song,a,path,id,combo)
func p21(lvl,song,a,path,id,combo):
	#2 ms
	var lvl_info = lvl.duplicate()
	lvl_info.erase("level")
	lvl_info.erase("subtitles")
	lvl_info.erase("special")
	#print(song)
	GL.cached_levels[song] = lvl_info
	p3(lvl,a,path,id,combo)
func p3(lvl,a,path,id,combo):
	#11 ms
	a.song_name = lvl.name
	a.nosong = !FileAccess.file_exists(path+"music.ogg")
	if lvl.has("producer"): a.producer = lvl.producer
	if lvl.has("difficulty"): a.difficulty = lvl.difficulty
	if lvl.has("completed"): a.completed = lvl.completed
	if lvl.has("total"): a.total = lvl.total
	if lvl.has("duration"): a.length = lvl.duration
	if lvl.has("checkpoint") && a.length > 0:
		var v = 1
		if lvl.checkpoint.size() > 2: v = 3
		a.checkpoint = snappedi(100 * lvl.checkpoint[v] / a.length,1)
	#print(a.song,a.song_name)
	a.id = id
	a.name = str(id)
	var dict = {"song":a.song,"song_name":a.song_name,"percent":a.score,"time":a.size,"combo":combo,"length":a.length,"producer":a.producer,"completed":a.completed,"difficulty":a.difficulty,"nosong":a.nosong,"times_played":a.times_played,"total":a.total,"id":a.id}
	songs.append(dict)
	p4(a,dict)
func p4(a,dict):
	#710 ms
	if a.completed:
		songs_c.append(dict)
		order_c.append(a.id)
		#486 ms
		$SongsCompleted.add_child(a)
	else:
		songs_u.append(dict)
		order_u.append(a.id)
		#227 ms
		$SongsUncompleted.add_child(a)
	#r.close()


func select_song(song):
	var b
	for i in songs:
		if i.song == song: b = i
	completed = b.completed
	$CheckBox.button_pressed = completed
	_on_check_box_toggled(completed)
	#update_completed()
	for i in songs:
		if i.song == song: b = i
	selected = songs_showing.find(b)

func sort(type:String,refocus = true):
	#print("type:",GL.settings.sorting)
	var prev_song
	if refocus: prev_song = songs_showing[selected].song
	GL.settings.sorting = type
	#GL.save()
	GL.sorted = type
	refs_c = []
	refs_u = []
	for u in [[songs_c,$SongsCompleted,refs_c],[songs_u,$SongsUncompleted,refs_u]]:
		var a = u[0]
		a.sort_custom(Callable(self, "sort_"+type))
		var c = -1
		#u[2] = []
		for i in a:
			c += 1
			u[1].move_child(u[1].get_node(str(i.id)),c)
			u[2].append(u[1].get_node(str(i.id)))
	active_refs = refs_c if completed else refs_u
	if refocus: select_song(prev_song)
	#print(refs_c)

#func update_completed():
	#return
	#songs_showing = []
	#for i in songs:
		##print(i.completed,",",i.song_name)
		#if i.completed == $CheckBox.button_pressed:
			#songs_showing.append(i)
			#var b = item.instantiate()
			#b.song = i.song
			#b.score = i.percent
			#b.song_name = i.song_name
			##b.size = i.time
			#b.length = i.length
			#b.producer = i.producer
			#b.difficulty = i.difficulty
			#b.completed = i.completed
			#b.nosong = i.nosong
			#b.combo = i.combo
			#b.times_played = i.times_played
			#b.total = i.total
			#$VBoxContainer.add_child(b)

func update_actives():
	if completed:
		songs_showing = songs_c
		$SongsCompleted.show()
		$SongsUncompleted.hide()
		active_vbox = $SongsCompleted
		selected = selected_c
		active_refs = refs_c
	else:
		songs_showing = songs_u
		$SongsCompleted.hide()
		$SongsUncompleted.show()
		active_vbox = $SongsUncompleted
		selected = selected_u
		active_refs = refs_u
	

func sort_numbered(arr,nums):
	var res = []
	res.resize(nums.size())
	for i in nums.size():
		res[i] = arr[nums[i]]
	return res

func setup_touch():
	for i in $touch.get_children():
		i.connect("pressed",GL.vibrate)

func _process(delta):
	settings_open = false
	#print($VBoxContainer.get_child(0).song,",",$VBoxContainer.get_child(0).song_name)
	if songs != []:
		$select/Label.text = songs_showing[selected].song_name
	if position_temp == null:
		position_temp = vbox_y - selected*36*vbox_scale
		active_vbox.position.y = vbox_y - selected*36*vbox_scale
		for i in active_vbox.get_children():
			i.selected = i.song == songs_showing[selected].song
		return
	if !is_equal_approx(active_vbox.position.y,position_temp) && !dragging && !drag_free:
		active_vbox.position.y = lerpf(active_vbox.position.y,vbox_y - selected*36*vbox_scale,0.4)
		for i in active_vbox.get_children():
			#print(i.song,",",songs_showing[selected].song)
			i.selected = i.song == songs_showing[selected].song
	elif is_equal_approx(active_vbox.position.y,position_temp) && !dragging:
		#print(position_temp)
		active_vbox.position.y = position_temp
	assert(!(dragging and drag_free))
	if dragging:
		pass
			
	if drag_free:
		active_vbox.position.y += free_speed
		free_speed = lerpf(free_speed,0,5*delta)
		active_vbox.position.y = lerpf(active_vbox.position.y,vbox_y - selected*36*vbox_scale,0.02)
	if drag_free && abs(free_speed) < 01.5: drag_free = false
		#var tween = get_tree().create_tween()
		#tween.set_trans(Tween.TRANS_QUAD)
		#tween.set_ease(Tween.EASE_OUT)
		#tween.tween_property($VBoxContainer,"position:y",184 - selected*54,abs((184 - selected*54)-$VBoxContainer.position.y)/10.0)
		#await tween.finished
	position_temp = vbox_y - selected*36*vbox_scale
	#$VBoxContainer.position.y = 184 - selected*54
	$debug.text = "Dragging: "+str(dragging)
	$debug2.text = "Free drag: "+str(drag_free)

func _notification(what: int) -> void:
	if what == NOTIFICATION_EXIT_TREE:
		if songs != []: GL.settings.last_song = songs_showing[selected].song
		GL.settings.gamemode = $Gamemode.selected
		GL.save()

func _input(event):
	if event.is_action_pressed("m_up"):
		#$VBoxContainer.position.y += 54
		selected = wrapi(selected-1,0,songs_showing.size())
		if completed: selected_c = selected
		else: selected_u = selected
		#GL.settings.last_song = songs_showing[selected].song
		#GL.save()
	if event.is_action_pressed("m_down"):
		#$VBoxContainer.position.y -= 54
		selected = wrapi(selected+1,0,songs_showing.size())
		if completed: selected_c = selected
		else: selected_u = selected
		#GL.settings.last_song = songs_showing[selected].song
		#GL.save()
	if event.is_action_pressed("m_accept"):
		_on_play_pressed()
	if !settings_open && ((event is InputEventMouseMotion && event.button_mask & 1 == 1) or event is InputEventScreenDrag) && event.position.x >= 32 && event.position.x <= 644 && event.position.y >= 64:
			#print(event.relative.y)
			drag_free = false
			dragging = true
			active_vbox.position.y += event.relative.y
			free_speed = event.relative.y
	if (event.is_action_released("left_click") or (event is InputEventScreenTouch && event.pressed == false)) && dragging:
		dragging = false
		drag_free = true

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

func _on_Button_pressed():
	sort("name")

func _on_Button2_pressed():
	sort("score")


func sort_name(a,b): return a.song_name.naturalnocasecmp_to(b.song_name) == -1
func sort_score(a,b): return a.percent > b.percent
func sort_producer(a,b): return a.producer.naturalnocasecmp_to(b.producer) == -1
func sort_difficulty(a,b): return a.difficulty < b.difficulty
func sort_total(a,b): return a.total < b.total
func sort_times_played(a,b): return a.times_played < b.times_played
func sort_combo(a,b): return a.combo < b.combo

func _on_Button4_pressed():
	if songs != []: GL.settings.last_song = songs_showing[selected].song
	GL.editor_load = false
	get_tree().change_scene_to_file("res://editor.tscn")


func load_audio(audio):
	return AudioStreamOggVorbis.load_from_file(audio)
#	var file = FileAccess.open(audio,FileAccess.READ)
#	var buffer = file.get_buffer(file.get_length())
#	var stream = AudioStreamOggVorbis.new()
#	var a = OggPacketSequence.new()
#	a.packet_data = buffer
#	stream.packet_sequence = a
##	stream.data = buffer
#	file.close()
#	return stream


func _on_play_pressed():
	if songs_showing[selected].nosong: return
	GL.song = songs_showing[selected].song
	GL.settings.last_song = songs_showing[selected].song
	#GL.save()
	GL.settings.gamemode = $Gamemode.selected
	
	GL.enter_level()


func _on_edit_pressed():
	GL.editor_load = true
	GL.song = songs_showing[selected].song
	GL.settings.last_song = songs_showing[selected].song
	#GL.save()
	get_tree().change_scene_to_file("res://editor.tscn")


func _on_button_3_pressed():
	sort("producer")


func _on_button_5_pressed():
	sort("difficulty")


func _on_check_box_toggled(toggled_on):
	completed = toggled_on
	update_actives()
	#position_temp = null
	#selected = 0
	#$VBoxContainer.position = Vector2(32,238)
	#sort(GL.sorted,false)
	#GL.settings.last_song = songs_showing[selected].song
	#GL.save()


func _on_convert_pressed() -> void:
	var dir = DirAccess.open(GL.systemdir+"levels")
	dir.list_dir_begin()
	while true:
		var file = dir.get_next()
		if file == "": break
		var song = file.substr(0,file.length()-4)
		
		DirAccess.make_dir_absolute(GL.systemdir+"songs/"+song)
		var dir2 = DirAccess.open(GL.systemdir)
		dir2.get_open_error()
		
		DirAccess.copy_absolute(GL.systemdir+"levels/"+song+".lvl",GL.systemdir+"songs/"+song+"/level.lvl")
		DirAccess.copy_absolute(GL.systemdir+"audio/"+song+".ogg",GL.systemdir+"songs/"+song+"/music.ogg")
		DirAccess.copy_absolute(GL.systemdir+"video/"+song+".ogv",GL.systemdir+"songs/"+song+"/video.ogv")
		DirAccess.copy_absolute(GL.systemdir+"subs_jp/"+song+".txt",GL.systemdir+"songs/"+song+"/subs_jp.txt")
		DirAccess.copy_absolute(GL.systemdir+"subs_ro/"+song+".txt",GL.systemdir+"songs/"+song+"/subs_ro.txt")
		DirAccess.copy_absolute(GL.systemdir+"subs_en/"+song+".txt",GL.systemdir+"songs/"+song+"/subs_en.txt")
	dir.list_dir_end()


func _on_button_6_pressed() -> void:
	sort("total")


func _on_button_7_pressed() -> void:
	sort("times_played")


func _on_option_button_item_selected(index: int) -> void:
	match index:
		0: sort("name")
		1: sort("producer")
		2: sort("score")
		3: sort("difficulty")
		4: sort("total")
		5: sort("times_played")
		6: sort("combo")
