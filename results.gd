extends Node2D

func _ready():
	save_score()
	
	$Panel/Node2D2/Label.text = str(GL.note_scores[0])
	$Panel/Node2D2/Label2.text = str(GL.note_scores[1])
	$Panel/Node2D2/Label3.text = str(GL.note_scores[2])
	$Panel/Node2D2/Label4.text = str(GL.note_scores[3])
	$Panel/Node2D2/Label5.text = str(GL.note_scores[4])
	$Panel/Node2D2/Label6.text = str(GL.tech[0])+"/"+str(GL.tech[1])
	$Panel/Node2D2/Label7.text = str(GL.chance[0])+"/"+str(GL.chance[1])
	$Panel/Node2D2/Label10.text = str(GL.final[0])+"/"+str(GL.final[1])
	$Panel/Node2D2/Label8.text = str(GL.combo)
	$Panel/Node2D2/Label9.text = str(GL.total_notes)
	
	var txt = ""
	for i in [0]:
		if GL.score >= 80:
			if GL.score >= 90:
				if GL.score >= 95:
					if GL.score >= 98:
						if GL.score == 100:
							txt = "HELL YEAH"
							break
						txt = "LMAO"
						break
					txt = "AVERAGE"
					break
				txt = "A VIDA É UMA LIFE"
				break
			txt = "SKILL ISSUE"
			break
		txt = "RIP BOZO"
	
	$Label.text = txt
	$Label2.text = str(snapped(GL.score,0.01)) + "%"
	$Label3.text = GL.song_name

func _input(event):
	if event.is_action_pressed("m_back"):
		_on_Button_pressed()
	if event.is_action_pressed("retry"):
		_on_Button2_pressed()


func save_score():
	var dict = {"name":GL.song_name,"song":GL.song,"score":GL.score,"combo":GL.combo,"total":GL.total_notes,"times_played":1}
	
	if FileAccess.file_exists(GL.systemdir+"scores.save"):
		var a = FileAccess.open(GL.systemdir+"scores.save",1)
		var test_json_conv = JSON.new()
		test_json_conv.parse(a.get_as_text())
		var b = test_json_conv.get_data()
		var d = false
		for i in b:
			if i.song == GL.song:
				d = true
				if i.has("times_played"): i.times_played += 1
				else: i.times_played = 1
				if i.score < GL.score:
					$Label4.show()
					$Label4.text = "New best! Previous: "+str(snapped(i.score,0.01))+"%"
					if i.has("progresses"): i.progresses.append(GL.score)
					else: i.progresses = [GL.score]
					i.score = GL.score
				i.total = GL.total_notes
				if i.combo < GL.combo:
					i.combo = GL.combo
		if !d:
			b.append(dict)
		a.close()
		a = FileAccess.open(GL.systemdir+"scores.save",2)
		#print(b)
		#print(JSON.stringify(b))
		var stringged_json = JSON.stringify(b)
		a.store_string(stringged_json)
		a.close()
	else:
		var a = FileAccess.open(GL.systemdir+"scores.save",2)
		var b = [dict]
		a.store_string(JSON.stringify(b))
		a.close()



func _on_Button2_pressed():
	get_tree().change_scene_to_file("res://level.tscn")


func _on_Button_pressed():
	get_tree().change_scene_to_file("res://menu.tscn")
