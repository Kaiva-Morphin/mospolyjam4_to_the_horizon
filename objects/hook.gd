extends Node3D

@onready var target = $MeshInstance3D
@onready var body = $CharacterBody3D

var t = 0.0

var spring_strength = 80.0
var damping = 8.0

func _physics_process(dt: float) -> void:
	t += dt
	
	target.position.x = sin(t * 0.7) * 25.0
	target.position.z = cos(t * 0.7) * 25.0
	target.position.y = sin(t * 5.0) * 3.0 + 10.0
	
	body.velocity.y -= 100.0 * dt
	
	var diff = target.global_position - body.global_position
	
	var force = diff * spring_strength
	
	force -= body.velocity * damping
	
	body.velocity += force * dt
	
	body.move_and_slide()
