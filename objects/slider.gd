extends Node3D

@onready var origin_path : Path3D = $Path3D
@onready var area : Area3D = $Area3D

@export var max_stick_len : float = 2.0
@export var OFFSET : Vector3 = Vector3(0, -2.2, 0)
@onready var papa = $Papa
@export var papa_speed = 10.0
@export var segment_len: float = 2.0

func _ready() -> void:
	var dot = $Mesh;
	var points = origin_path.curve.get_baked_points()
	
	var phys : PhysicsDirectSpaceState3D
	if max_stick_len > 0.0:
		phys = PhysicsServer3D.space_get_direct_state(get_world_3d().space)
	
	for i in range(len(points) - 1):
		var i2 = i + 1
		var p1 = points[i]
		var p2 = points[i2]
		var c = (p1+p2) * 0.5
		
		if max_stick_len > 0.0:
			var ray = PhysicsRayQueryParameters3D.create(
				c, 
				c - Vector3(0, max_stick_len, 0), 1)
			var ray_coll = phys.intersect_ray(ray)
			if 'collider' in ray_coll.keys():
				var de = dot.duplicate()
				de.mesh = de.mesh.duplicate()
				var le = (c - ray_coll.position).length()
				add_child(de)
				de.position = (c + ray_coll.position) * 0.5 + OFFSET
				de.mesh.height = le
				de.show()
		var s = CollisionShape3D.new()
		var b : BoxShape3D = BoxShape3D.new()
		b.size = Vector3.ONE * 1.75
		var l = (p1-p2).length()
		b.size.z = l + 0.3
		s.shape = b
		area.add_child(s)
		s.look_at_from_position(p1, p2)
		s.position = c
	var curve = origin_path.curve
	var total_len = curve.get_baked_length()

	var t = 0.0
	while t < total_len:
		var t2 = min(t + segment_len, total_len)
		
		var p1 = curve.sample_baked(t, true)
		var p2 = curve.sample_baked(t2, true)
		var c = (p1 + p2) * 0.5
		var l = (p1 - p2).length()
		
		if max_stick_len > 0.0:
			var ray = PhysicsRayQueryParameters3D.create(
				c,
				c - Vector3(0, max_stick_len, 0), 1)
			var ray_coll = phys.intersect_ray(ray)
			if 'collider' in ray_coll:
				var de = dot.duplicate()
				de.mesh = de.mesh.duplicate()
				var le = (c - ray_coll.position + OFFSET).length()
				add_child(de)
				de.position = (c + ray_coll.position + OFFSET) * 0.5
				de.mesh.height = le
				de.show()
		
		var m = MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3.ONE * 0.35
		box.size.y *= 0.75
		box.size.x *= 1.5
		box.size.z = segment_len + 0.2
		m.mesh = box
		add_child(m)
		m.look_at_from_position(p1, p2)
		m.position = c + OFFSET
		
		t = t2

var tracked = null
func _on_area_3d_body_entered(body: Node3D) -> void:
	if !body.is_in_group("Player"): return
	if body.slider != null: return
	print("BEG")
	tracked = body
	running = false
	

var followed = null

var running = false
var progress = 0.0
var run_dir = 0.0

signal track_end(dir: Vector3)
signal trigger_ride(Node3D)

var last_point = Vector3.ZERO
var last_dir = Vector3.ZERO
func _process(delta: float) -> void:
	if !running:
		if !tracked: return
		if tracked.velocity.y >= 0.0: return
		running = false
		var offset_from = origin_path.curve.get_closest_offset(tracked.position)
		var v = tracked.velocity
		var vd = tracked.velocity.length_squared()
		if vd < 350.0:
			v = -tracked.transform.basis.z
		var offset_to = origin_path.curve.get_closest_offset(tracked.position - v.normalized())
		run_dir = 1.0 if (offset_from - offset_to) > 0.0 else -1.0;
		var tr = origin_path.curve.sample_baked_with_rotation(offset_from, true)
		var tangent = -tr.basis.z.normalized()
		# var run_dir_vec = origin_path.curve.get_closest_point(tracked.position) - origin_path.curve.get_closest_point(tracked.position + tracked.transform.basis.z)
		var run_dir_vec = tangent
		progress = offset_from
		running = true
		trigger_ride.emit(self)
		
		papa_speed = Vector2(tracked.velocity.x, tracked.velocity.z).project(Vector2(run_dir_vec.x, run_dir_vec.z).normalized()).length() + 7.0
		
		tracked = null
		if offset_from == offset_to:
			var l = origin_path.curve.get_baked_length()
			if offset_from < 0.1:
				progress = 0.2
				run_dir = 1.0
				#papa_speed = 0.0
			elif offset_from > l - 0.1:
				progress = l - 0.2
				run_dir = -1.0
				#papa_speed = 0.0
			else:
				run_dir = 1.0
				progress = l - 0.1
				#papa_speed = 0.0
		return
	progress += run_dir * delta * papa_speed
	papa.position = origin_path.curve.sample_baked(progress, true)
	if papa_speed < 15.0:
		papa_speed = move_toward(papa_speed, 15.0, delta * 5.0)
	if progress >= origin_path.curve.get_baked_length() - 0.1 || progress <= 0.1:
		var p = origin_path.curve.sample_baked(progress - run_dir * 0.1, true)
		var v = (papa.position - p).normalized()
		track_end.emit(v * papa_speed)
		running = false
	last_dir = papa.position - last_point
	last_point = papa.position

func _on_area_3d_body_exited(body: Node3D) -> void:
	if !body.is_in_group("Player"): return
	print("END")
	tracked = null
