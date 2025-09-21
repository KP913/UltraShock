extends Sprite2D

var time = 0
var chance = false
var ninths = 0

func _process(delta):
	frame = int(chance)
