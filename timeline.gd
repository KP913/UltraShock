extends Node2D

var bpm = 120
var wait_time = 0
var beats = 4
var division = 2

var fulls = 0.0
var ninths = 0.0
var second_voice = false

var playing_pos = 0
var playing_timer = 0
var playing_interval = 4.5

var overlap : Area2D
var overlap_hold : Area2D

var playing = false

var note_times = {}
var note_array = []

var sfx_volume

var bpm_list = []

var subs = []
var subs_ro = []

var hear_hold1 #dictionaries
var hear_hold2
var hear_hold1_mid
var hear_hold2_mid

var level = {}

var song_length

func _ready():
	bpm_list = [[bpm,0]]
	create_bars()
	if FileAccess.file_exists(GL.systemdir+"songs/"+GL.song+"/subs_ro.txt"):
		var w = FileAccess.open(GL.systemdir+"songs/"+GL.song+"/subs_ro.txt",FileAccess.READ)
		var z = w.get_as_text().split("\n")
		while z.find("") != -1:
			z.remove_at(z.find(""))
		subs_ro = z

var asd_counting = 0


func _process(delta):
	if $"..".on_menu:
		return
	
	if playing: ninths = snappedf(playing_pos,playing_interval)
	#print(playing_interval)
	#print(playing_pos,",",fulls)
	$"../Label5".text = "Ninths:"+str(ninths)
	if song_length != null: $"../Label6".text = str(snappedi(100 * b2s2(playing_pos/9) / song_length,1)) + "%"
	if asd_counting == 0:
		playing_interval = float($"../LineEdit".text)
		#$"../Label".text = str(playing_pos)
		#$"../Label2".text = str(overlap_hold)
		if !playing:
			playing_pos = ninths
			$cursor.position.x = fposmod(playing_pos,72.0)/9*64
			$cursor.position.y = floor(playing_pos/72) * 128
		else:
			$cursor.position.y = floor((playing_pos/72)) * 128
		$cursor.position.y += int(second_voice)*32
		position.y = -snapped($cursor.position.y,128) + 192
		if !subs_ro.is_empty():
			var c = -1
			var clear = false
			for i in subs:
				if i.ninths <= playing_pos:
					clear = i.clear
					if !i.clear: c += 1
				else: break
			if c == -1 or clear: $"../subs".text = ""
			else: if subs_ro.size() > c: $"../subs".text = subs_ro[c]
	asd_counting = wrapi(asd_counting,0,4)
	
	if playing:
		playing_pos = s2b2($"../AudioStreamPlayer".get_playback_position())*9
		playing_timer += s2b(delta)
		$cursor.position.x = fposmod(64*playing_pos/9,512.0)
		#position.x = (fulls+ninths/9.0)*-64
	#else:
		#position.x = -(s2b($"../AudioStreamPlayer".get_playback_position()-wait_time)*64)-256
	#$cursor.position.x = -position.x
	
	#$"../Label2".text = str(level)
	if playing:
		#print(playing_timer,",",playing_interval)
		if playing_timer >= playing_interval/9:
			playing_timer = 0
			draw_playing()
		if note_times.size() != 0:
			#if !is_instance_valid(note_times[-1]):
				#if note_times.size() > 1: note_times.resize(note_times.size() - 1)
				#else: note_times = []
			if hear_hold1 != null:
				#print(hear_hold1.end_time)
				#print(playing_pos)
				#print(hear_hold1_mid)
				if hear_hold1.end_ninths < playing_pos:
					hear_hold1_mid.queue_free()
					hear_hold1_mid = null
					if hear_hold1.final: hit_sound("final")
					elif hear_hold1.double: hit_sound("double")
					elif hear_hold1.flick: hit_sound("flick")
					else: hit_sound("hold_end")
					hear_hold1 = null
			if hear_hold2 != null:
				if hear_hold2.end_ninths < playing_pos:
					hear_hold2_mid.queue_free()
					hear_hold2_mid = null
					if hear_hold2.final: hit_sound("final")
					elif hear_hold2.double: hit_sound("double")
					elif hear_hold2.flick: hit_sound("flick")
					else: hit_sound("hold_end")
					hear_hold2 = null
			#var arr = note_times.keys()
			#arr.sort_custom(sort_key)
			#arr.reverse()
			var last = note_times[note_array[-1]]
			$"../Label".text = str(note_array[-1])
			while last.ninths <= playing_pos:
				if last.chance: hit_sound("chance",5)
				elif !last.hold:
					if last.final: hit_sound("final")
					elif last.double: hit_sound("double")
					elif last.flick: hit_sound("flick")
					else: hit_sound("hit")
				else:
					hit_sound("hold_start")
					var a = hit_sound("hold_mid")
					if last.second_voice:
						if hear_hold2_mid != null:
							hear_hold2_mid.queue_free()
							hear_hold2_mid = null
						hear_hold2 = last
						hear_hold2_mid = a
					else:
						if hear_hold1_mid != null:
							hear_hold1_mid.queue_free()
							hear_hold1_mid = null
						hear_hold1 = last
						hear_hold1_mid = a
				
				print("last ",note_array[-1],", ",note_array.size())
				#print("before ",note_times)
				note_times.erase(note_array[-1])
				note_array.remove_at(note_array.size()-1)
				#arr = note_times.keys()
				if note_array == []: break
				#arr.sort_custom(sort_key)
				last = note_times[note_array[-1]]
				#print("after ",note_times)
				
				#print(note_times.size(),",",note_times[-1])
				#if note_times.size() > 1: note_times.resize(note_times.size() - 1)
				#else: note_times = []
				#if note_times.size() > 0:
					#while !is_instance_valid(note_times[-1]):
						#if note_times.size() > 1: note_times.resize(note_times.size() - 1)
						#else: note_times = []
				#print(typeof(note_times))
				#note_times.clear()
				if note_times.size() == 0: break
	
	

func update_subs():
	await get_tree().create_timer(0.1).timeout
	subs = []
	for i in $subtitles.get_children():
		if !i.is_queued_for_deletion():
			if !i.has_meta("ninths"):
				i.set_meta("ninths",i.get_meta("time")*9/64)
			subs.append({"time":i.get_meta("time"),"clear":i.get_meta("clear"),"ninths":i.get_meta("ninths")})
	subs.sort_custom(sort_time)

func sort_time(a,b):
	if a.time < b.time:
		return true
	return false

func sort_key(a:String,b:String):
	return int(a.split("p")[0]) < int(b.split("p")[0])

func get_key():
	#print(playing_interval,"hdsjai")
	if !playing: return str(ninths).replace(".","p")+("a" if !second_voice else "b")
	else: return str(snappedf(playing_pos,playing_interval)).replace(".","p")+("a" if !second_voice else "b")

var bpm_counting = 0
func _input(event):
	if $"..".on_menu:
		return
	if bpm_counting == 0:
		update_bpm()
	bpm_counting = wrapi(bpm_counting,0,10)
	if event.is_action_pressed("e_right") or event.is_action_pressed("e_left"):
		#var c = 0
		var n = 0
		if log(division)/log(2) == int(log(division)/log(2)): n = 9/float(division)
		#print(c)
		if division == 3: n = 3
		if Input.is_action_pressed("e_shift"):
			#c /= 2.0
			n /= 2.0
		if Input.is_action_pressed("e_ctrl"):
			n /= 3
			#c = 0
		if event.is_action_pressed("e_left"):
			#c *= -1
			n *= -1
		#fulls += c
		ninths += n
		#while ninths >= 9:
			#ninths -= 9
			#fulls += 1
		#if ninths == 4.5:
			#ninths -= 4.5
			#fulls += 0.5
		#if division == 3: c = c | 1
		#if Input.is_action_pressed("e_shift"): c = c | 2
		#if Input.is_action_pressed("e_ctrl"): c = c | 4
		#var a = [[0.5,0],[0,3],[0.25,0],[0,1.5],[0,3],[0,1],[0,1.5],[0,0.5]]
		#if event.is_action_pressed("e_right"):
			#if Input.is_action_pressed("e_speed"):
				#fulls += a[c][0]*4
				#ninths += a[c][1]*4
			#else:
				#fulls += a[c][0]
				#ninths += a[c][1]
		#if event.is_action_pressed("e_left"):
			#if Input.is_action_pressed("e_speed"):
				#fulls -= a[c][0]*4
				#ninths -= a[c][1]*4
			#else:
				#fulls -= a[c][0]
				#ninths -= a[c][1]
	if event.is_action_pressed("e_up"):
		ninths -= 72
	if event.is_action_pressed("e_down"):
		ninths += 72
	if event.is_action_pressed("e_voice"):
		second_voice = !second_voice
	
	if !playing:
		var note = level[get_key()] if level.has(get_key()) else null
		if note != null:
			if (event.is_action_pressed("e_movel") or event.is_action_pressed("e_mover") or event.is_action_pressed("e_movels") or event.is_action_pressed("e_movers")):
				var relative = 0
				if event.is_action_pressed("e_movel"): relative -= 4.5
				if event.is_action_pressed("e_mover"): relative += 4.5
				if event.is_action_pressed("e_movels"): relative -= 2.25
				if event.is_action_pressed("e_movers"): relative += 2.25
				if has_node("notes/"+str(ninths+relative).replace(".","p")+("a" if !second_voice else "b")):
					return
				note.ninths += relative
				if has_node("notes/"+str(ninths+relative).replace(".","p")+("a" if !second_voice else "b")):
					get_node("notes/"+str(ninths+relative).replace(".","p")+("a" if !second_voice else "b")).queue_free()
				update_note(get_key(),null,true)
				#str(ninths).replace(".","p")+("a" if !second_voice else "b")
				var new_key = get_key()
				new_key = str(note.ninths).replace(".","p")+("a" if !second_voice else "b")
				level[new_key] = note
				level.erase(get_key())
				#update_note(str(ninths+relative).replace(".","p")+("a" if !second_voice else "b"))
				#get_key() = new_key
		
		if event.is_action_pressed("e_cross") || event.is_action_pressed("e_circle") || event.is_action_pressed("e_square") || event.is_action_pressed("e_triangle"):
			var button = 0 if event.is_action_pressed("e_cross") else (1 if event.is_action_pressed("e_circle") else (2 if event.is_action_pressed("e_square") else 3))
			if !level.has(get_key()): create_note(button)
			else:
				if level[get_key()].button == button:
					$notes.get_node(get_key()).queue_free()
					level.erase(get_key())
				else:
					level[get_key()].button = button
					update_note(get_key())
			#print(level)
		note = level[get_key()] if level.has(get_key()) else null
		var hold_key = get_hold()
		if note == null && hold_key != null: note = level[hold_key]
		if note:
			if event.is_action_pressed("e_double"):
				note.double = !note.double
			if event.is_action_pressed("e_holdr"):
				if note.hold == 0: note.hold = 1
				note.duration += 0.5 * 1/(float(Input.is_action_pressed("e_shift"))+1) * 1/(float(Input.is_action_pressed("e_ctrl"))*2+1)
				note.end_time = note.time + note.duration*64
				note.end_ninths = note.ninths + note.duration*9
				#print(note.duration)
			if event.is_action_pressed("e_holdl"):
				if note.duration > 0.5:
					note.duration -= 0.5 * 1/(float(Input.is_action_pressed("e_shift"))+1) * 1/(float(Input.is_action_pressed("e_ctrl"))*2+1)
					note.end_time = note.time + note.duration*64
					note.end_ninths = note.ninths + note.duration*9
				else:
					note.hold = 0
					note.duration = 0
				
			if event.is_action_pressed("e_flickup"):
				if note.flick != 1: note.flick = 1
				else: note.flick = 0
			if event.is_action_pressed("e_flickdown"):
				if note.flick != 2: note.flick = 2
				else: note.flick = 0
			if event.is_action_pressed("e_final"):
				note.final = !note.final
			if event.is_action_pressed("e_spin"):
				if note.hold == 1: note.hold = 2
				else: note.hold = 1
			if event.is_action_pressed("e_tech"):
				note.tech = !note.tech
			if event.is_action_pressed("e_chance"):
				note.chance = !note.chance
				var note_node = $notes.get_node(get_key()) if level.has(get_key()) else $notes.get_node(hold_key)
				if note.chance:
					note_node.material = ShaderMaterial.new()
					note_node.material.shader = $"..".rainbow_shader
				else:
					note_node.material = null
			if level.has(get_key()): update_note(get_key())
			else: update_note(hold_key)
		else:
			if event.is_action_pressed("e_tech"):
				var sub_pos = $cursor.position + Vector2(0,32) if second_voice else $cursor.position + Vector2(0,64)
				var a = null
				for i in $special.get_children(): if i.ninths == playing_pos: a = i
				if a == null:
					var b = preload("res://special.tscn").instantiate()
					b.ninths = playing_pos
					b.position = sub_pos
					$special.add_child(b)
				else:
					if a.chance: a.chance = false
					else: a.queue_free()
			if event.is_action_pressed("e_chance"):
				var sub_pos = $cursor.position + Vector2(0,32) if second_voice else $cursor.position + Vector2(0,64)
				var a = null
				for i in $special.get_children(): if i.ninths == playing_pos: a = i
				if a == null:
					var b = preload("res://special.tscn").instantiate()
					b.chance = true
					b.ninths = playing_pos
					b.position = sub_pos
					$special.add_child(b)
				else:
					if !a.chance: a.chance = true
					else: a.queue_free()
		if event.is_action_pressed("e_delete"):
			for i in $notes.get_children():
				var n = level[i.name]
				if snapped(n.ninths+18,36) == snapped(playing_pos+18,36):
					i.queue_free()
					level.erase(i.name)
			#print(level)
		if event.is_action_pressed("e_invert"):
			var note_list = []
			for i in $notes.get_children():
				var n = level[i.name]
				if snapped(n.ninths+18,36) == snapped(playing_pos+18,36):
					n.second_voice = !n.second_voice
					var new_key = i.name
					var old_key = i.name
					if n.second_voice:
						new_key = new_key.replacen("a","b")
					else:
						new_key = new_key.replacen("b","a")
					note_list.append([new_key,n])
					i.free()#update_note(str(i.name),null,true)
					level.erase(old_key)
					#i.name = new_key
					#print(i.name,",",n.second_voice,",",new_key)
			for i in note_list:
				level[i[0]] = i[1]
				spawn_note(i[0],true)
		var sub = int(event.is_action_pressed("e_subtitle")) + 2*int(event.is_action_pressed("e_subclear"))
		if sub:
			var sub_pos = $cursor.position + Vector2(0,32) if second_voice else $cursor.position + Vector2(0,64)
			var node = null
			for i in $subtitles.get_children():
				if i.position == sub_pos:
					if node != null: node.queue_free()
					else: node = i
			if node == null:
				var a = Sprite2D.new()
				a.position = sub_pos
				a.scale = Vector2(2,2)
				a.centered = false
				a.texture = preload("res://gfx/subtitle.png")
				a.set_meta("time",playing_pos*64/9)
				if sub&1:a.set_meta("clear",false)
				if sub&2:a.set_meta("clear",true)
				a.set_meta("ninths",playing_pos)
				$subtitles.add_child(a)
			else:
				node.queue_free()
			update_subs()
		if event.is_action_pressed("e_checkpoint"):
			var sub_pos = $cursor.position + Vector2(0,32) if second_voice else $cursor.position + Vector2(0,64)
			if has_node("checkpoint"):
				if $checkpoint.position == sub_pos:
					$checkpoint.queue_free()
				else:
					$checkpoint.position = sub_pos
					$checkpoint.set_meta("time",playing_pos*64/9)
					$checkpoint.set_meta("ninths",playing_pos)
			
			else:
				var a = Sprite2D.new()
				a.position = sub_pos
				a.scale = Vector2(0.125,0.125)
				a.centered = false
				a.texture = preload("res://gfx/receiver.png")
				a.set_meta("time",playing_pos*64/9)
				a.set_meta("ninths",playing_pos)
				add_child(a)
		if event.is_action_pressed("e_bpmchange"):
			var sub_pos = $cursor.position - Vector2(0,64) if second_voice else $cursor.position - Vector2(0,32)
			var node = null
			for i in $time_changes.get_children():
				if i.position == sub_pos:
					if node != null: queue_free()
					else: node = i
			if node == null:
				var a = LineEdit.new()
				a.position = sub_pos
				a.scale = Vector2(0.75,0.75)
				a.modulate = Color.RED
				a.set_meta("time",playing_pos*64/9)
				a.set_meta("ninths",playing_pos)
				$time_changes.add_child(a)
			else:
				node.queue_free()
		if event.is_action_pressed("e_speedchange"):
			var sub_pos = $cursor.position - Vector2(0,64) if second_voice else $cursor.position - Vector2(0,32)
			var node = null
			for i in $speed_changes.get_children():
				if i.position == sub_pos:
					if node != null: queue_free()
					else: node = i
			if node == null:
				var a = LineEdit.new()
				a.position = sub_pos
				a.scale = Vector2(0.75,0.75)
				a.modulate = Color.BLUE
				a.set_meta("time",playing_pos*64/9)
				a.set_meta("ninths",playing_pos)
				$speed_changes.add_child(a)
			else:
				node.queue_free()
	
	else:
		var note = level[get_key()] if level.has(get_key()) else null
		#print(get_key())
		ninths = snappedf(playing_pos,playing_interval)
		var arr = ["cross","circle","square","triangle"]
		for i in 4:
			if (Input.is_action_pressed(arr[i]) and event.is_action_pressed(arr[i]+"2")) or (event.is_action_pressed(arr[i]) and Input.is_action_pressed(arr[i]+"2")):
				#if !note: 
					create_note(i,true)
			elif event.is_action_pressed(arr[i]) or event.is_action_pressed(arr[i]+"2"):
				if !note or note.button != i: create_note(i)
				elif note.button == i: create_note(i,false,playing_interval/9*64)
			if event.is_action_released(arr[i]) or event.is_action_released(arr[i]+"2"):
				if holding1 != null: if holding1.button == i:
					holding1 = null
					ishold1 = false
				if holding2 != null: if holding2.button == i:
					holding2 = null
					ishold2 = false
	if event.is_action_pressed("e_play"):
		ishold1 = false
		ishold2 = false
		if !playing:
			#print(playing_pos,",",s2b2(0)*64)
			playing_pos = max(playing_pos,s2b2(0)*9)
			$"../AudioStreamPlayer".play(b2s2(playing_pos/9))
			playing = true
			note_times = {}
			for u in level:
				var i = level[u]
				if i.ninths >= ninths:
					note_times[u] = i
			print("keys ",note_times.keys())
			note_array = note_times.keys()
			note_array.sort_custom(sort_key)
			note_array.reverse()
			#note_times.sort_custom(sort_time)
			#note_times.reverse()
			
			if get_hold(false):
				var a = hit_sound("hold_mid")
				hear_hold1 = level[get_hold(false)]
				hear_hold1_mid = a
			if get_hold(true):
				var a = hit_sound("hold_mid")
				hear_hold2 = level[get_hold(true)]
				hear_hold2_mid = a
				
		else:
			$"../AudioStreamPlayer".stop()
			playing = false
			ninths = snappedf(playing_pos,9)
			#fulls = (snapped(playing_pos,64)/64)
			if hear_hold1_mid != null:
				hear_hold1_mid.queue_free()
				hear_hold1_mid = null
			if hear_hold2_mid != null:
				hear_hold2_mid.queue_free()
				hear_hold2_mid = null
			hear_hold1 = null
			hear_hold2 = null

var holding1
var holding2
var holding1_key
var holding2_key
var ishold1 = false
var ishold2 = false

func draw_playing():
	if holding1 != null:
		if playing_pos-holding1.ninths >= 2*playing_interval:
			ishold1 = true
			holding1.hold = 1
			holding1.duration = (snapped(playing_pos+2.25,playing_interval)-holding1.ninths)/9.0
			holding1.end_ninths = holding1.ninths + holding1.duration*9
			update_note(holding1_key)
	if holding2 != null:
		if playing_pos-holding2.ninths >= 2*playing_interval:
			ishold2 = true
			holding2.hold = 1
			holding2.duration = (snapped(playing_pos+2.25,playing_interval)-holding2.ninths)/9.0
			holding2.end_ninths = holding2.ninths + holding2.duration*9
			update_note(holding2_key)
	#if p_pressed[0]: create_note(0,true)


func s2b(s,bpm_temp = bpm):
	return bpm_temp*s/60.0

func b2s(b,bpm_temp = bpm):
	return 60*b/float(bpm_temp)
	
func s2b2(s2):
	var s = s2 - wait_time
	var a = bpm_list.duplicate()
	var b = 0
	var seconds = 0
	for i in a.size():
		var temp = 0
		if a.size()-1 >= i+1:
			temp = 60*(a[i+1][1]-a[i][1])/a[i][0]
		else:
			temp = 999999999999
		if s > seconds + temp:
			seconds += temp
		else:
			b = a[i][1] + a[i][0]/60*(s-seconds)
			break
	return b
	#return bpm/60*s

func b2s2(b):
	var a = bpm_list.duplicate()
	var seconds = 0
	for i in a.size():
		if a.size()-1 >= i+1:
			if a[i+1][1] <= b:
				seconds += 60*(a[i+1][1]-a[i][1])/float(a[i][0])
			else:
				seconds += 60*(b-a[i][1])/float(a[i][0])
				break
		else:
			seconds += 60*(b-a[i][1])/float(a[i][0])
			break
	return seconds + wait_time

func update_bpm():
	bpm_list = [[bpm,0]]
	for i in $time_changes.get_children():
		bpm_list.append([float(i.text),i.get_meta("time")/64])
	bpm_list.sort_custom(sort_bpm)

func sort_bpm(a,b):
	if a[1] < b[1]:
		return true
	return false

func create_note(button,double = false,offset = 0):
	#var a = preload("res://editor_note.tscn").instantiate()
	var overlapping = false
	var old
	print(get_key())
	if level.has(get_key()):
		overlapping = true
		old = level[get_key()]
		#$notes.get_node(get_key()).free()
		#level.erase(get_key())
	var new_note = {
		#"fulls": fulls,
		"ninths": ninths,
		"time": (ninths/9)*64,
		"button": button,
		"flick": 0,
		"double": double,
		"hold": 0,
		"duration": 0.0,
		"end_time": 0.0,
		"end_ninths": 0.0,
		"final": false,
		"chance": false,
		"tech": false,
		"second_voice": second_voice,
		}
	
	if playing && overlapping:
		if old.button == new_note.button:
			if new_note.double && !old.double:
				$notes.get_node(get_key()).free()
				level.erase(get_key())
			else: return
		else:
			if level.has(get_key().replace("a","b") if !second_voice else get_key().replace("b","a")):
				return
			new_note.second_voice = !second_voice
			second_voice = !second_voice
	
	if (ishold1&&!second_voice) or (ishold2&&second_voice):
		new_note.second_voice = !second_voice
		level[get_key().replace("a","b") if !second_voice else get_key().replace("b","a")] = new_note
		spawn_note(get_key().replace("a","b") if !second_voice else get_key().replace("b","a"))
		return
	
	if playing:
		if new_note.second_voice:
			holding2 = new_note
			holding2_key = get_key()
		else:
			holding1 = new_note
			holding1_key = get_key()
	
	level[get_key()] = new_note
	spawn_note(get_key())
	#if snapped:
		#a.time = snapped(playing_pos,64*playing_interval)
	#else:
		#a.time = playing_pos
	#a.time += offset
	#a.double = double
	#a.button = button
	#a.second_voice = second_voice
	#a.fulls = fulls
	#a.ninths = fulls
	#for i in $notes.get_children(): if i.time == a.time && i.second_voice == a.second_voice && playing:
		#if i.button == a.button:
			#if a.double && !i.double: i.queue_free()
			#else: return
		#else:
			#a.second_voice = !second_voice
			##if second_voice: a.position.y -= 32
			##else: a.position.y += 32
			#second_voice = !second_voice
	#if (ishold1&&!second_voice) or (ishold2&&second_voice):
		#a.second_voice = !second_voice
		##if second_voice: a.position.y -= 32
		##else: a.position.y += 32
	#$notes.add_child(a)
	#if snapped:
		#if a.second_voice: holding2 = a
		#else: holding1 = a
	#hit_sound("hit")

func spawn_note(key,loading = false):
	var a = Sprite2D.new()
	a.texture = preload("res://gfx/note_sheet_new.png")
	a.centered = false
	a.offset = Vector2(-128,-128)
	a.hframes = 6
	a.vframes = 4
	a.scale = Vector2(0.125,0.125)
	a.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	a.name = key
	
	#print("XXXX    "+a.name)
	$notes.add_child(a)
	#print("WWWW    "+a.name)
	update_note(key,a)
	#print($notes.get_child_count())
	if !loading: hit_sound("hit")
	
	return a

func update_note(key,a:Sprite2D=null,name_change = false):
	var note = level[key]
	if a == null:
		if $notes.has_node(key): a = $notes.get_node(key)
		else: spawn_note(key)
	
	if note.hold:
		note.end_time = note.time + note.duration*64
		note.end_ninths = note.ninths + note.duration*9
	
	a.position.x = wrapf(note.ninths,0,72)/72*512
	a.position.y = floor(note.ninths/72)*128 + 32*int(note.second_voice)
	if name_change: a.name = str(note.ninths).replace(".","p")+("a" if !note.second_voice else "b")
	
	a.frame_coords.y = note.button
	a.frame_coords.x = 2*note.flick+int(note.double)
	
	if note.final && !a.has_node("final"):
		var special = Sprite2D.new()
		special.scale = Vector2(16,16)
		special.centered = false
		special.hframes = 3
		special.frame = 2
		special.name = "final"
		special.texture = preload("res://gfx/special.png")
		a.add_child(special)
	if note.tech && !a.has_node("tech"):
		var special = Sprite2D.new()
		special.scale = Vector2(16,16)
		special.centered = false
		special.hframes = 3
		special.frame = 0
		special.name = "tech"
		special.texture = preload("res://gfx/special.png")
		a.add_child(special)
	if !note.final && a.has_node("final"): a.get_node("final").queue_free()
	if !note.tech && a.has_node("tech"): a.get_node("tech").queue_free()
	
	if note.hold:
		if !a.has_node("hold"):
			var hold = Sprite2D.new()
			hold.texture = preload("res://gfx/note_sheet_new.png")
			hold.centered = false
			hold.offset = Vector2(-128,-128)
			hold.hframes = 6
			hold.vframes = 4
			#hold.scale = Vector2(0.125,0.125)
			hold.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
			hold.name = "hold"
			a.add_child(hold)
			
			var line = Line2D.new()
			line.points.resize(2)
			line.width = 3
			line.scale = Vector2(8,8)
			line.position = Vector2(128,128)
			line.name = "line"
			#line.z_index = -1
			line.default_color = Color(0.51,0.6,1,1)
			a.add_child(line)
		var hold = a.get_node("hold")
		hold.frame = a.frame
		hold.position.x = fposmod(note.end_ninths,72)/9*64
		hold.position.y = (floor(note.end_ninths/72) * 4)*32 + int(note.second_voice)*32
		print(hold.position.y)
		hold.position -= a.position
		#print(hold.position,",",note.end_time)
		hold.position *= 8
		#hold.position.y *= 32
		#print(hold.position,",",note.end_time)
		var arr = []
		if hold.position.y == 0:
			arr.resize(2)
		else:
			arr.resize(4)
			#print(arr)
			arr[1] = Vector2(512-a.position.x,0)
			arr[2] = Vector2(0-a.position.x,hold.position.y/8)
		arr[0] = Vector2(0,0)
		arr[-1] = hold.position/8
		a.get_node("line").points = arr
	else:
		if a.has_node("hold"):
			a.get_node("hold").queue_free()
			a.get_node("line").queue_free()

func hit_sound(sound,volume_add=0):
	var a = AudioStreamPlayer.new()
	if sound == "chance": a.stream = load("res://sfx/"+sound+".ogg")
	else: a.stream = load("res://sfx/"+sound+".wav")
	a.volume_db = sfx_volume+volume_add
	if sfx_volume == -50: a.volume_db = -99999999999999
	$"../sfx".add_child(a)
	a.play()
	return a

func create_bars():
	var b = preload("res://bars.tscn").instantiate()
	for i in beats-1:
		var c = b.get_node("small").duplicate()
		c.position.x += 64*i
		b.add_child(c)
	$bars.add_child(b)
	for i in 512:
		var a = b.duplicate()
		a.position.x += (256*i) % 512
		a.position.y += floor((256*i/512.0)) * 128
		$bars.add_child(a)

func get_hold(voice = second_voice):
	var arr = level.duplicate()
	var arr2 = []
	for u in arr:
		var i = arr[u]
		if i.hold && i.second_voice == voice:
			arr2.append(u)
	arr = []
	arr2.reverse()
	for u in arr2:
		var i = level[u]
		if i.ninths > playing_pos:
			continue
		#$Label3.text = i.end_time
		if i.end_ninths >= playing_pos:
			print(i)
			return u
