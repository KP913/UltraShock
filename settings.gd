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
		#scroll.position = Vector2(192,104)
		var c = VBoxContainer.new()
		c.custom_minimum_size = Vector2(320,0)
		c.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		for u in i[1]:
			match u.type:
				"bool":
					var j = CheckBox.new()
					j.text = u.title
					j.set_meta("setting",u.setting)
					c.add_child(j)
				"float":
					var j = LineEdit.new()
					var k = Label.new()
					k.position = Vector2(80,0)
					j.add_child(k)
					j.set_meta("setting",u.setting)
					c.add_child(j)
				"slider":
					var j = HSlider.new()
					var k = Label.new()
					k.position = Vector2(80,0)
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
		i.visible =  i.name == ref.name

func start():
	$Master.value = GL.settings.master
	$Song.value = GL.settings.song
	$SFX.value = GL.settings.sfx
	$Sync.text = str(GL.settings.sync)
	$Vibration.value = GL.settings.vibration
	$Brightness.value = GL.settings.brightness
	$jp.button_pressed = GL.settings.subs_jp
	$ro.button_pressed = GL.settings.subs_ro
	$en.button_pressed = GL.settings.subs_en
	$fps.button_pressed = GL.settings.fps
	$Pitch.text = str(GL.settings.pitch)
	$Funny.selected = GL.settings.gamemode
	$thumbs.button_pressed = GL.settings.thumbs

func save():
	GL.settings.master = $Master.value
	GL.settings.song = $Song.value
	GL.settings.sfx = $SFX.value
	GL.settings.sync = float($Sync.text)
	GL.settings.vibration = $Vibration.value
	GL.settings.brightness = $Brightness.value
	GL.settings.subs_jp = $jp.button_pressed
	GL.settings.subs_ro = $ro.button_pressed
	GL.settings.subs_en = $en.button_pressed
	GL.settings.fps = $fps.button_pressed
	GL.settings.pitch = float($Pitch.text)
	GL.settings.gamemode = $Funny.selected
	GL.settings.thumbs = $thumbs.button_pressed

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
