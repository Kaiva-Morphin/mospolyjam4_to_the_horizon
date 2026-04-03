extends Node3D

@export var attention_distance := 30.0
@export var rest_length := 4.0
@export var stiffness := 20.0
@export var damping = 4.0
@export var max_force = 150.0
@export var focus_col : Color = Color("#9fdeff")

func dist(v):
	var m : ShaderMaterial = $OutOfRangeRing.material_override
	var max_dist = attention_distance * 2.0;
	var f = clamp(pow((1 - (v - attention_distance) / max_dist), 5.0), 0.0, 3.0)
	var d = f * 1.5 + 1.0
	m.set_shader_parameter("uv_scale_factor", d)
	var c = Color.from_rgba8(255,255,255,int(255*f))
	if d >= 2.5:
		c = focus_col
		$OutOfRange.material_override.set_shader_parameter("albedo", c)
	else:
		$OutOfRange.material_override.set_shader_parameter("albedo", Color.WHITE)
	m.set_shader_parameter("albedo", c)
	

func _ready() -> void:
	$OutOfRange.material_override = $OutOfRange.material_override.duplicate()
	$OutOfRangeRing.material_override = $OutOfRangeRing.material_override.duplicate()
	unfocus()
	$AnimationPlayer.play('unfocused')
	$OutOfRangeRing.hide()
	$OutOfRange.hide()
	$Ready.hide()
	$InRange.hide()

func focus():
	#$OutOfRange.hide()
	#$OutOfRangeRing.hide()
	$Ready.show()
	#$InRange.hide()
	pass

func in_range():
	#$OutOfRangeRing.hide()
	#$OutOfRange.hide()
	$Ready.hide()
	#$InRange.show()
	pass

func unfocus():
	$OutOfRangeRing.show()
	$OutOfRange.show()
	$Ready.hide()
	$InRange.hide()
