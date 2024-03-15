tool
extends Control

export var value : int setget set_value

func set_value(v):
	value = v
	if value < 0:
		$Bolts.show()
		$Ankhs.hide()
		for b in range(0,5):
			$Bolts.get_child(b).visible = b < -(value/10)
	else:
		$Bolts.hide()
		$Ankhs.show()
		for a in range(0,5):
			$Ankhs.get_child(a).visible = a < (value/10)
