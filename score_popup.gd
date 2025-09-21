extends Label

var alpha = 1.0
var second_voice = false

func _ready():
	for i in $"..".get_children():
		if second_voice == i.second_voice && i != self:
			i.queue_free()
	if text.begins_with("COOL"):
		modulate = Color.YELLOW
	if text.begins_with("GOOD"):
		modulate = Color.SILVER
	if text.begins_with("SAFE"):
		modulate = Color.GREEN
	if text.begins_with("BAD"):
		modulate = Color.BLUE_VIOLET
	if text.begins_with("MISS"):
		modulate = Color.PURPLE

func _process(delta):
	modulate.a = alpha

func _on_Timer_timeout():
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_SINE)
	alpha = 1.0
	tween.tween_property(self,"alpha",0.0,0.6)
	tween.finished.connect(_on_Tween_tween_all_completed)
#	$Tween.interpolate_property(self,"alpha",1,0,0.6,Tween.TRANS_SINE,Tween.EASE_OUT)
#	$Tween.start()


func _on_Tween_tween_all_completed():
	queue_free()
