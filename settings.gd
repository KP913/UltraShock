extends Panel

@onready var m = $".."

func _ready():
	if OS.get_name() == "Android": $Vibration.show()
	
	for i in settings:
		var a = Button.new()
		a.custom_minimum_size = Vector2(0,50)
		a.text = i[0]
		a.name = i[0]
		a.toggle_mode = true
		$Tabs/C.add_child(a)
		a.pressed.connect(open_tab.bind(a))
		
		var scroll = ScrollContainer.new()
		scroll.size = Vector2(320,280)
		scroll.name = i[0]
		#scroll.position = Vector2(192,104)
		var c = VBoxContainer.new()
		c.name = "C"
		c.custom_minimum_size = Vector2(320,0)
		#c.size_flags_horizontal = Control.SIZE_FILL
		for u in i[1]:
			var k = Label.new()
			k.position = Vector2(320-160+20,0)
			k.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			k.text = u.title
			k.layout_direction = Control.LAYOUT_DIRECTION_RTL
			var j : Control
			match u.type:
				"bool":
					j = CheckBox.new()
				"float":
					j = LineEdit.new()
				"slider":
					j = HSlider.new()
			if j != null:
				j.custom_minimum_size = Vector2(160,0)
				j.size_flags_horizontal = Control.SIZE_SHRINK_END
				j.add_child(k)
				j.set_meta("setting",u.setting)
				c.add_child(j)
		scroll.hide()
		scroll.add_child(c)
		$Settings.add_child(scroll)
		
	
func open_tab(ref):
	for i in $Tabs/C.get_children():
		if i != ref:
			i.button_pressed = false
	
	for i in $Settings.get_children():
		#print(i.name,",",ref.name)
		i.visible = i.name == ref.name

func start():
	for i in $Settings.get_children():
		for u in i.get_node("C").get_children():
			if GL.settings.has(u.get_meta("setting")):
				var s = GL.settings[u.get_meta("setting")]
				if u is CheckBox:
					u.button_pressed = s
				if u is LineEdit:
					u.text = str(s)
				if u is HSlider:
					u.value = s
	
	#$Master.value = GL.settings.master
	#$Song.value = GL.settings.song
	#$SFX.value = GL.settings.sfx
	#$Sync.text = str(GL.settings.sync)
	#$Vibration.value = GL.settings.vibration
	#$Brightness.value = GL.settings.brightness
	#$jp.button_pressed = GL.settings.subs_jp
	#$ro.button_pressed = GL.settings.subs_ro
	#$en.button_pressed = GL.settings.subs_en
	#$fps.button_pressed = GL.settings.fps
	#$Pitch.text = str(GL.settings.pitch)
	#$Funny.selected = GL.settings.gamemode
	#$thumbs.button_pressed = GL.settings.thumbs

func save():
	for i in $Settings.get_children():
		for u in i.get_node("C").get_children():
			print(u)
			var s = u.get_meta("setting")
			if u is CheckBox:
				GL.settings[s] = u.button_pressed
			if u is LineEdit:
				GL.settings[s] = float(u.text)
			if u is HSlider:
				GL.settings[s] = u.value
			print(s,",",GL.settings.s)
	print(GL.settings)
	#GL.settings.master = $Master.value
	#GL.settings.song = $Song.value
	#GL.settings.sfx = $SFX.value
	#GL.settings.sync = float($Sync.text)
	#GL.settings.vibration = $Vibration.value
	#GL.settings.brightness = $Brightness.value
	#GL.settings.subs_jp = $jp.button_pressed
	#GL.settings.subs_ro = $ro.button_pressed
	#GL.settings.subs_en = $en.button_pressed
	#GL.settings.fps = $fps.button_pressed
	#GL.settings.pitch = float($Pitch.text)
	#GL.settings.gamemode = $Funny.selected
	#GL.settings.thumbs = $thumbs.button_pressed

func _on_button_pressed():
	save()
	get_tree().current_scene.update_settings()
	GL.save()
	hide()
	if get_tree().current_scene.is_in_group("level"): $"../pause".show()
	else:
		get_tree().paused = false
		#get_tree().current_scene.settings_open = false

#func _input(event: InputEvent) -> void:
	#if event.is_action_pressed("pause"):
		#_on_button_pressed()

const settings = [
	[
		"Menu",
		[
			{
				"title":"Song Thumbnails",
				"setting":"thumbs",
				"type":"bool",
			},
		]
	],
	[
		"Gameplay",
		[
			{
				"title":"Song Offset",
				"setting":"sync",
				"type":"float",
			},
			{
				"title":"Speed/Pitch",
				"setting":"pitch",
				"type":"float",
			},
			{
				"title":"Gamemode",
				"setting":"gamemode",
				"type":"option:gamemode",
			},
			{
				"title":"Vibration",
				"setting":"vibration",
				"type":"slider",
			},
		]
	],
	[
		"Sound",
		[
			{
				"title":"Master Volume",
				"setting":"master",
				"type":"slider",
			},
			{
				"title":"Song Volume",
				"setting":"song",
				"type":"slider",
			},
			{
				"title":"SFX Volume",
				"setting":"sfx",
				"type":"slider",
			},
			{
				"title":"Chance Volume",
				"setting":"chance_sfx",
				"type":"slider",
			},
		]
	],
	[
		"Display",
		[
			{
				"title":"Brightness",
				"setting":"brightness",
				"type":"slider",
			},
			{
				"title":"Japanese Subtitles",
				"setting":"subs_jp",
				"type":"bool",
			},
			{
				"title":"Romaji Subtitles",
				"setting":"subs_ro",
				"type":"bool",
			},
			{
				"title":"English Subtitles",
				"setting":"subs_en",
				"type":"bool",
			},
			{
				"title":"FPS Counter",
				"setting":"fps",
				"type":"bool",
			},
		]
	],
]
