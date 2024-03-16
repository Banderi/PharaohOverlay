tool
extends Control

export var text : String = "Resource" setget set_resource_name
export var short : bool = false setget set_short_label
export var no_text : bool = false setget set_no_text

onready var font = $Count.get("custom_fonts/font")
func set_short_label(b):
	short = b
	if short:
		$Label.hide()
		$Count.rect_position.x = 20
		$Count.align = HALIGN_LEFT
#		$Count.rect_min_size.x = font.get_string_size()
	else:
		$Label.show()
		$Count.rect_position.x = 115
		$Count.align = HALIGN_CENTER
func set_resource_name(t):
	text = t
	$Label.text = t
func set_count(c):
	$Count.text = str(c)
func set_no_text(b):
	no_text = b
	$Count.visible = !no_text
