extends Node3D

@export var initial_sun : Color = Color.BLACK
@export var initial_cloud : Color = Color.BLACK
@export var initial_energy: float = 0.25

@export var default : bool = true

@export var default_energy: float = 4.1
@export var default_sun : Color = Color.WHITE
@export var default_cloud : Color = Color("#6d757d") # Color.from_rgba8(75, 103, 133)



var mat : ShaderMaterial
func _ready():
	$DirectionalLight3D.hide()
	var e: Environment = $WorldEnvironment.environment
	var sky: Sky = e.sky
	e.ambient_light_energy = initial_energy
	mat = sky.sky_material
	mat.set_shader_parameter("cloud_color", initial_cloud)
	mat.set_shader_parameter("sun_color", initial_sun)
	if default:
		show_env()

func _on_activator_body_entered(body: Node3D) -> void:
	if !body.is_in_group("Player"): return
	show_env()

func show_env():
	$DirectionalLight3D.show()
	for node in get_tree().get_nodes_in_group("InitialLights"):
		node.queue_free()
	mat.set_shader_parameter("cloud_color", default_cloud)
	mat.set_shader_parameter("sun_color", default_sun)
	var e: Environment = $WorldEnvironment.environment
	e.ambient_light_energy = default_energy
	#"shader_parameter/cloud_color"
