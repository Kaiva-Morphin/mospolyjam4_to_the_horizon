extends HBoxContainer

const cnv_mul = 100

@onready var slider = $VBoxContainer/HSlider
@onready var line_edit = $LineEdit
@onready var label = $VBoxContainer/Label

var sensitivity := 0.0025

func _ready() -> void:
	var value = sensitivity * cnv_mul
	slider.value = value
	line_edit.text = str(value)
	get_tree().call_group("Player", "set_mouse_sensitivity", sensitivity)


func _on_line_edit_text_changed(new_text: String) -> void:
	var sanitized = ""
	for c in new_text:
		if c >= "0" and c <= "9":
			sanitized += c
	if sanitized == "":
		return
	var value = float(sanitized)
	value = clamp(value, 0.1,  0.9) * cnv_mul
	slider.value = value
	line_edit.text = str(value)
	set_sensitivity(value)


func _on_line_edit_text_submitted(new_text: String) -> void:
	_on_line_edit_text_changed(new_text)


func _on_h_slider_value_changed(value: float) -> void:
	line_edit.text = str(value)
	set_sensitivity(value)


func set_sensitivity(value: float) -> void:
	sensitivity = value / cnv_mul
	get_tree().call_group("Player", "set_mouse_sensitivity", sensitivity)
