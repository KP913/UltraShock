extends Node2D

var time = 0.0
var end_time = 0.0

var button = 0
var flick = 0 #none up down
var double = false
var hold = 0 #none normal spin
var duration = 0.0
var final = false
var chance = false
var tech = false
var second_voice = false
var hold_changes = [] #{"time":32,"button":0}

var start_time = 4
var stopped = false

var fail_time_before = 0.09 #TAVA A 0.11
var fail_time_after = 0.11 #TAVA A 0.11

var flick_timing = 110.3
var flick_threshold = 5
var flick_start_pos = 0.0
var flick_frame = false # A primeira frame onde começou a fzr flick

@onready var main = $"../.."

var holding = false
var holding_second = false

var flicking = 0
var flicking_second = false
var flick_hold = 0

var timing = 0 #tempo que falta até o melhor timing possível (0 é o melhor)
var timing_hold = 0 #tempo q falta até o melhor timing possível do hold
var start_beat = 0 #tempo que a nota spawnou
var unhold_time = 0
var target_beat = 0 #beat onde a nota existe (time/64)

var starting_position_x = 0

var note_tween : Tween
var hold_tween : Tween

func _ready():
	# O tween q faz a nota mover
	var tween = get_tree().create_tween()
	tween.tween_property(self,"position:y",160-512,b2s(8/main.speed_mult))
	note_tween = tween
	
	# Escolher o sprite certo
	$note.frame_coords.x = 2*flick+int(double)
	$note.frame_coords.y = button
	$note2.frame_coords.x = 2*flick+int(double)
	$note2.frame_coords.y = button
	
	#if !hold: start_time = 4
	if hold: start_time += duration
	
	# Tirar nodes específicos do hold quando n há hold
	if !hold:
		$note2.queue_free()
		$Line2D.queue_free()
		#tween.stop()

	# Shader do chance
	if chance:
		$note.material = ShaderMaterial.new()
		$note.material.shader = main.rainbow_shader
		#$note/Sprite2D.scale = Vector2(1.3,1.3)
	
	start_beat = main.beat
	target_beat = time/64
	
	starting_position_x = position.x

# Pode se correr a qualquer altura e vai corretamente pôr a nota a andar
func restart_tweens():
	# Pôr a nota base a mover
	if note_tween != null && note_tween.is_valid():
		note_tween.kill()
		var tween = get_tree().create_tween()
		
		tween.tween_property(self,"position:y",160-128,b2s(target_beat-main.beat+1/main.speed_mult))
		
		note_tween = tween
	# Pôr a nota hold a mover
	if hold_tween != null && hold_tween.is_valid():
		hold_tween.kill()
		var tween2 = get_tree().create_tween()
		
		tween2.tween_property($note2,"position:y",0,b2s(duration-(main.beat-unhold_time)))
		
		tween2.bind_node($note2)
		hold_tween = tween2

func extra_time():
	var tween = get_tree().create_tween()
	tween.tween_property(self,"position:y",160-512,b2s(time/64+4-main.beat))
	note_tween = tween

var c = 0
func _process(delta):
	c += 1
	if c == 15:
		#Regularmente resincroniza o movimento da nota
		restart_tweens()
		c = 0
	
	#Define o timing, o tempo q falta até acertar na nota
	timing = b2s(target_beat-main.beat)
	timing_hold = b2s(target_beat-main.beat + duration)
	
	#Se godmode tiver ligado, acerta automaticamente na nota no melhor tempo possível
	if GL.godmode:
		if !hold && timing <= 0:
			#print("Start time: ",start_time)
			print("Speed mult: ",main.speed_mult)
			print("Beat: ",main.beat)
			print("Start beat: ",start_beat)
			print("BPM: ",main.bpm)
			print("Position: ",position.y)
			print()
			print()
			main.hit_sound("hit")
			hit()
		if hold:
			if !holding && timing <= 0:
				hit(false,true)
				holding = true
				stopped = true
				unhold_time = main.beat
				if note_tween != null:
					note_tween.kill()
					var tween2 = get_tree().create_tween()
					tween2.tween_property($note2,"position:y",0,b2s(duration))
					tween2.bind_node($note2)
					hold_tween = tween2
			if holding && timing_hold <= 0:
				main.hit_sound("hit")
				hit(false,false,true)
	
	#mete uma cor random todas as framesse for final (tenho q mudar isto)
	if final:
		modulate = Color(randf(),randf(),randf(),1)
	else:
		modulate = Color.WHITE
	
	#Dá update à linha do hold
	if hold:
		$Line2D.points[0] = $note.position
		$Line2D.points[1] = $note2.position
	
	# Se n tiver holding e timing for bueda tarde, falha automaticamnte
	if timing <= -fail_time_after && !holding:
		hit(true)
	# Mesma cena mas para holding
	if holding && timing_hold <= -fail_time_after:
		hit(true)
	
	var a = ["cross","circle","square","triangle"]
	# Se n estiver holding nem flicking, se for a próxima nota e tiver dentro do hit range
	if !holding && !flicking && (get_value(main.note_array1,0) == self or get_value(main.note_array2,0) == self) && timing <= fail_time_before:
		
		var press1 = Input.is_action_just_pressed(a[button]) && !main.key_locks[button]
		var press2 = Input.is_action_just_pressed(a[button]+"2") && !main.key_locks[button+4]
		var held1 = Input.is_action_pressed(a[button])
		var held2 = Input.is_action_pressed(a[button]+"2")
		if (double && ((held1 && press2) or (press1 && held2))) or (!double && (press1 or press2)) && !((second_voice && main.frame_hit2) or (!second_voice && main.frame_hit1)):
			# Tranca os botões para n haver double presses
			if press1 && press2:
				if double:
					main.key_locks[button] = true
					main.key_locks[button+4] = true
				else:
					if main.key_locks[button] == true: main.key_locks[button+4] = true
					main.key_locks[button] = true
			else:
				if press1: main.key_locks[button] = true
				if press2: main.key_locks[button+4] = true
			# Se for hold, acerta a primeira nota e prepara-se prá segunda
			if hold:
				var q = hit(false, true)
				if q != "womp womp":
					holding = true
					holding_second = press2
					stopped = true
					unhold_time = main.beat
					if note_tween != null:
						note_tween.kill()
						var tween2 = get_tree().create_tween()
						tween2.tween_property($note2,"position:y",0,b2s(duration))
						tween2.bind_node($note2)
						hold_tween = tween2
					if OS.get_name() == "Android" && !main.controller: flick_hold = flick
			# Se for flick, começa a acertar na nota e prepara-se
			elif flick:
				if OS.get_name() == "Android" && !main.controller:
					#debug("fgh")
					flicking = flick
					flicking_second = Input.is_action_just_pressed(a[button]+"2")
					flick_frame = true
				else:
					hit()
			else:
				hit()
	
	# Se já tiver a fazer hold:
	if holding:
		# Se for a primeira nota e tiver dentro do hit range:
		if (get_value(main.note_array1,0) == self or get_value(main.note_array2,0) == self) && timing_hold <= fail_time_before:
			if !flick_hold:
				if double && (Input.is_action_just_released(a[button]) or Input.is_action_just_released(a[button]+"2")):
					hit(false,false,true)
				if !double && ((Input.is_action_just_released(a[button]) && !holding_second) or (Input.is_action_just_released(a[button]+"2") && holding_second)):
					hit(false,false,true)
			elif flicking == 0:
				flicking = flick
				flicking_second = holding_second
				flick_frame = true
				debug("Started flicking!")
				$Timer2.start()
		else:
			if ((Input.is_action_just_released(a[button]) && !holding_second) or (Input.is_action_just_released(a[button]+"2") && holding_second)):
				hit(true,false,true)

func _input(event: InputEvent) -> void:
	# Se acabou de começar o flick, regista a pos inicial
	if flick_frame && (event is InputEventScreenTouch or event is InputEventScreenDrag):
		if (event.position.x < 480 && !flicking_second) or (event.position.x > 480 && flicking_second):
			flick_start_pos = event.position.y
			flick_frame = false
	
	# Se o flick chegar, resolve o flick
	if flicking && !flick_frame && (event is InputEventScreenTouch or event is InputEventScreenDrag):
		if !double:
			if (event.position.x < 480 && !flicking_second) or (event.position.x > 480 && flicking_second):
				if (flicking == 1 && event.position.y-flick_start_pos <= -flick_threshold) or (flicking == 2 && event.position.y-flick_start_pos >= flick_threshold):
					hit(false,false,hold)
		else:
			if (flicking == 1 && event.position.y-flick_start_pos <= -flick_threshold) or (flicking == 2 && event.position.y-flick_start_pos >= flick_threshold):
				hit(false,false,hold)

# Mete texto no ecrã, quando a label tá visível
func debug(text):
	$"../../Label7".text += text+"\n"

func hit(miss = false, start_hold = false, holded = false):
	if ((second_voice && main.frame_hit2) or (!second_voice && main.frame_hit1)):
		return "womp womp"
	
	main.frame_hit = true
	if second_voice: main.frame_hit2 = true
	else: main.frame_hit1 = true
	
	if holding:
		if second_voice && $"../..".hold2_sfx != null:
			$"../..".hold2_sfx.stop()
			$"../..".hold2_sfx = null
		if !second_voice && $"../..".hold1_sfx != null:
			$"../..".hold1_sfx.stop()
			$"../..".hold1_sfx = null
	
	var offset = abs(timing)
	if holding:
		offset = abs(timing_hold)
	
	var score = ""
	
	var hitted = false
	if offset <= 0.05:
		score = "COOL"
		hitted = true
	elif offset <= 0.08:
		score = "GOOD"
		hitted = true
	elif offset <= 0.11:
		score = "SAFE"
	elif offset <= 0.14 :
		score = "BAD"
	else:
		score = "MISS"
	
	if miss:
		score = "MISS"
	
	main.note_hit(self, score, hitted, miss, start_hold, chance, holded)
	if !start_hold:
		queue_free()


func s2b(s):
	return GL.bpm*s/60

func b2s(b):
	return 60*b/GL.bpm


func _on_Tween_tween_all_completed():
	hit()

func get_value(arr:Array,n:int):
	if arr.size() > n:
		return arr[n]
