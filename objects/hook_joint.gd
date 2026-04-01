extends Node3D

func focus():
	$Focused.show()
	$Idle.hide()

func unfocus():
	$Focused.hide()
	$Idle.show()
