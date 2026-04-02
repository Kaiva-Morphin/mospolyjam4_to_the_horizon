extends StaticBody3D
var collider
func _ready() -> void:
	var shape = $CSGCombiner3D.bake_collision_shape()
	var s = CollisionShape3D.new()
	s.shape = shape
	add_child(s)
	collider = s

func _notification(what):
	if what == NOTIFICATION_WM_WINDOW_FOCUS_IN:
		collider.shape = $CSGCombiner3D.bake_collision_shape()
		
