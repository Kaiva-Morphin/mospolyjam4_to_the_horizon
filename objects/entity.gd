extends CharacterBody3D

#region DEBUG
var DEBUG_UPDATE = false
var SHOW_DEBUG = false
var DEBUG_STRING = ""

func init_debug():
	pass

var debug = {}

func dbg(key, value):
	debug[key] = value

func update_debug():
	var dbgs = []
	var keys = debug.keys()
	keys.sort()
	for key in keys:
		dbgs.append(key+" "+str(debug[key]))
	
	DEBUG_STRING = \
	"DEBUG\n" + \
	"STATE: " + GLOBAL.ENTITY_STATE.keys()[state] + "\n" + \
	"DIR: " + str(input_dir)
	$DEBUG2.text = "\n".join(dbgs)

#endregion

#region CONSTS
var ACC_INAIR := 60.0
var INAIR_SPEED := 20.0
var INAIR_DOT_FACTOR := 2.0
var ACC_SPEED := 50.0
var DEC_SPEED := 0.16
var REDIR_AIR := 1.0
var SLIDE_SPEED := ACC_SPEED * 1.3
var JUMP_VELOCITY := 30
var MAX_WALLJUMPS := 3
var MAX_AIRJUMPS := 1
var CAMERA_INTERPOLATION_SPEED := 20.0
var MAX_ENERGY := 300
var RUN_SPEED := 20.0
var GRAVITY : float = ProjectSettings.get_setting("physics/3d/default_gravity")  * 2.5
var MAX_SLOPE_ANGLE := deg_to_rad(45.0)
var MAX_COYOT_TIME = 0.1
var JUMP_STRENGTH = 12.0
var JUMP_BUFFER_TIME = 0.15
@export var TILT_STRENGTH := 0.05
@export var TILT_WALL_STRENGTH := 0.5
@export var tilt_limit := 10.0 

var jump_buffer = 0.0

var processing_return = false
func return_to_checkpoint():
	if locked: return
	if processing_return: return
	processing_return = true
	$"../Control/AnimationPlayer".play("death")

func finish_return():
	processing_return = false
	cleanup_ride()
	$Node/Checkpoint.play()
	#hook_target = null
	velocity = Vector3.ZERO
	state = states.STAND
	self.rotation = c_rot
	global_position = checkpoint
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	await get_tree().process_frame
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_ON


@onready var rope = $"../Rope"
@onready var rope_mesh = $"../Rope/Rope"
var checkpoint
var c_rot
func _ready() -> void:
	#Engine.time_scale = 0.1
	$"../Control/CenterContainer".hide()
	#$"../Control/CenterContainer/VBoxContainer/Sensivity/VBoxContainer/HSlider".value = sensitivity
	#$"../Control/CenterContainer/VBoxContainer/Sensivity/VBoxContainer/HSlider".value_changed.connect(_on_HSlider_value_changed)
	$"../Node3D4/anim1/Camera2".current = true
	camera.current = false
	init_debug()
	checkpoint = global_position
	prev_pos = global_position
	c_rot = self.rotation
	update_hook_joints()
	rope.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	for slider_ in get_tree().get_nodes_in_group("Slider"):
		slider_.trigger_ride.connect(on_slider_ride)
	$CenterContainer.hide()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	#unlock()
	$"../Node3D4/anim1/AnimationPlayer".play("intro/Camera2")
	$"../Node3D4/anim2/AnimationPlayer".play("intro/ArmatureAction")


func lock_end():
	$CenterContainer.hide()
	locked = true
	$"../Control/AnimationPlayer".play("end")
	print("ABO")


func run_end():
	print("ABOBA")
	camera.current = false
	$"../end_anim/end/Camera".current = true
	$"../end_anim/end/AnimationPlayer".play("Camera|CameraAction")
	$"../end_anim/AnimationPlayer".play("intro/PlayerAction")
	$"../end_anim/end2/AnimationPlayer2".play("другAction")
	$"../end_anim/Armature".show()
	get_tree().create_timer(7.5).timeout.connect(continue_sit)

func continue_sit():
	$"../end_anim/AnimationPlayer".play("SitAction")


var min_treshhold = 25.0
var max_treshold = 35.0
var prev_pos = Vector3.ZERO
var min_music_treshold = 10.0
var max_music_treshold = 20.0
var min_db = -40.0
var max_db = -20.0

func _process(_dt: float) -> void:
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		$"../Control/CenterContainer".hide()
	if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
		$"../Control/CenterContainer".show()
	if Input.is_action_just_pressed("F"):
		$Node/MeowSoundCat.play()
	dbg("FPS", Engine.get_frames_per_second())
	var vel = velocity
	if state == states.RIDING:
		vel = (slider.last_dir * slider.papa_speed) * 2.0
		$HOOK.global_position = global_position
	var spd = vel.length()
	var t = clamp(
		(spd - min_music_treshold) / (max_music_treshold - min_music_treshold),
		0.0,
		1.0
	)
	var target_db = lerp(min_db, max_db, t)
	$Node/Music.volume_db = lerp($Node/Music.volume_db, target_db, 5.0 * _dt)
	if vel != Vector3.ZERO:
		var v = clamp(
			clamp(vel.length() - min_treshhold, 0, max_treshold) 
			/ (max_treshold - min_treshhold),
			0,
			1
		)
		$"../GPUParticles3D".material_override.albedo_color = Color8(255, 255, 255, 255 * v)
		$"../GPUParticles3D".look_at(global_position + vel)
		$"../GPUParticles3D".global_position = $StandCamera.global_position
	prev_pos = global_position
	if Input.is_action_just_pressed("ESC"):
		if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			$"../Control/CenterContainer".hide()
		else:
			$"../Control/CenterContainer".show()
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if state == GLOBAL.ENTITY_STATE.SLIDING:
		camera.position.y = lerp(camera.position.y, crunch_camera_target.position.y, _dt * CAMERA_INTERPOLATION_SPEED)
	else:
		camera.position.y = lerp(camera.position.y, stand_camera_target.position.y, _dt * CAMERA_INTERPOLATION_SPEED)
	if locked: return
	if global_position.y < -75.0:
		$Node/MetalPipeFallingSound.play()
		return_to_checkpoint()
	if !velocity.is_finite() || !global_position.is_finite():
		return_to_checkpoint()
	if Input.is_action_just_pressed("R"):
		return_to_checkpoint()
		return
	update_debug()
	if hook_target:
		var l = global_position - hook_target.global_position
		var p = (global_position + hook_target.global_position) / 2.0;
		rope.global_position = p
		rope_mesh.mesh.height = l.length()
		rope.look_at(global_position, Vector3.UP)
		rope.show()
		rope.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_ON
	else:
		rope.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
		rope.hide()
	var speed = velocity.length()
	camera.fov = clamp(lerp(camera.fov, 95.0 + 0.5 * speed, _dt * 20.0), 10, 170)
	if Input.is_action_just_pressed("C") && is_on_floor():
		$Node/BlltShelShellEject02.play()
		checkpoint = global_position
		c_rot = self.rotation
		$"../checkpoint".position = global_position



func _notification(what):
	#if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		#Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		#$"../Control/CenterContainer".show()
	#if what == NOTIFICATION_WM_WINDOW_FOCUS_IN:
		#if !$"../Control/CenterContainer".visible:
			#Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	return

#endregion


#region RIDING
# gc, haha
var prev_ride_tick = false
var slider = null
func on_slider_ride(_slider: Node3D):
	#if state == states.HOOKED:
		#return
	state = states.RIDING
	_slider.track_end.connect(on_ride_end)
	slider = _slider
	prev_ride_tick = true

func on_ride_end(dir):
	state = states.STAND
	velocity.y = JUMP_STRENGTH
	#velocity += dir
	velocity += slider.last_dir.normalized() * slider.papa_speed
	cleanup_ride()

func cleanup_ride():
	if slider:
		inair_jumps = MAX_AIRJUMPS
		if state == states.RIDING:
			state = states.STAND
		slider.track_end.disconnect(on_ride_end)
		slider = null
#endregion


var energy := MAX_ENERGY
var walljumps := MAX_WALLJUMPS
var inair_jumps := MAX_AIRJUMPS
var input_dir := Vector2.ZERO

var prev_camera_rotation := Vector3.INF

@onready var camera : Camera3D = $Camera
@export var crunch_camera_target : Node3D
@export var stand_camera_target : Node3D

var state : GLOBAL.ENTITY_STATE = GLOBAL.ENTITY_STATE.STAND
var states = GLOBAL.ENTITY_STATE

var coyot_time = 0.0

var launched = false

var hook_target: Node3D

var hook_joints = []
func update_hook_joints():
	hook_joints = []
	for node in get_tree().get_nodes_in_group("HookJoint"):
		hook_joints.append(node)


var locked = true


func unlock():
	locked = false
	$"../Node3D4/anim1/Camera2".current = false
	$CenterContainer.show()
	camera.current = true
	$"../Node3D4".hide()
	$CenterContainer.show()


var wall_normal : = Vector3.ZERO
func _physics_process(_dt: float) -> void:
	if locked: return
	if Input.is_action_just_pressed("SPACE"):
		jump_buffer = JUMP_BUFFER_TIME
	else:
		jump_buffer = max(jump_buffer - _dt, 0.0)
	if !prev_ride_tick: cleanup_ride()
	
	if inair_jumps > 0:
		$CenterContainer/Control/DJ.show()
	else:
		$CenterContainer/Control/DJ.hide()
	
	#region JOINTS
	update_hook_joints()
	var nearest_joint = null
	var best_score = -INF
	$CenterContainer/Control/Hook.hide()
	var space_state = get_world_3d().direct_space_state
	for node in hook_joints:
		node.unfocus()
		var to_point = node.global_position - camera.global_position
		var dist = to_point.length()
		node.dist(dist)
		if dist == 0:
			continue
		if dist > node.attention_distance:
			continue
		node.in_range()
		var dir = to_point / dist
		var forward = -camera.global_transform.basis.z
		var dot = dir.dot(forward)
		var near_angle = 0.45
		var far_angle = 0.69
		var t = clamp(dist / node.attention_distance, 0.0, 1.0)
		var threshold = lerp(near_angle, far_angle, t)
		if dot > threshold:
			var query = PhysicsRayQueryParameters3D.create(
				camera.global_position,
				node.global_position
			)
			query.exclude = [camera]
			var result = space_state.intersect_ray(query)
			if result and result.collider != node:
				continue
			var score = dot - (dist / node.attention_distance) * 0.3
			if score > best_score:
				best_score = score
				nearest_joint = node
	if nearest_joint:
		$CenterContainer/Control/Hook.show()
		nearest_joint.focus()
		if Input.is_action_pressed("LMB") && state != states.HOOKED:
			$Node/Button12.play()
			hook_target = nearest_joint
			if state == states.RIDING:
				cleanup_ride()
				inair_jumps = MAX_AIRJUMPS
			state = states.HOOKED
			inair_jumps = MAX_AIRJUMPS

	#endregion
	
	if is_on_floor():
		coyot_time = 0.0
	else:
		coyot_time += _dt
	
	input_dir = Input.get_vector("A", "D", "W", "S")
	var direction = (transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()
	var current_rotation = camera.rotation_degrees
	if wall_normal && !is_on_floor():
		var forward = -camera.global_transform.basis.z
		var normal = wall_normal.normalized()
		var side = forward.cross(normal).y
		var facing = 1.0 - abs(forward.dot(normal))
		var target_tilt = tilt_limit * side * facing
		current_rotation.z = lerp(
			current_rotation.z,
			target_tilt,
			TILT_WALL_STRENGTH
		)
	elif input_dir:
		var target_tilt = tilt_limit * -input_dir.x
		current_rotation.z = lerp(current_rotation.z, target_tilt, TILT_STRENGTH)
	else:
		current_rotation.z = lerp(
			current_rotation.z,
			0.0,
			TILT_STRENGTH
		)
		
	camera.rotation_degrees = current_rotation
	var floor_normal := Vector3.UP
	if is_on_floor():
		floor_normal = get_floor_normal()
		inair_jumps = MAX_AIRJUMPS
	if direction != Vector3.ZERO:
		direction = direction.slide(floor_normal).normalized()
	match state:
		states.STAND:
			if not is_on_floor():
				velocity.y -= GRAVITY * _dt
				state = states.INAIR
				return
			else:
				if velocity.length_squared() > 0.05:
					velocity = velocity.lerp(Vector3.ZERO, DEC_SPEED)
				else:
					velocity = Vector3.ZERO
			if direction.length_squared() > 0.01:
				state = states.MOVING
		states.MOVING:
			if not is_on_floor():
				velocity.y -= GRAVITY * _dt
				state = states.INAIR
				return
			if direction.length_squared() > 0.01:
				velocity = velocity.move_toward(direction * RUN_SPEED, _dt * ACC_SPEED)
			else:
				state = states.STAND
		states.INAIR:
			velocity.y -= GRAVITY * _dt
			if direction:
				var d = 1.0 - Vector2(direction.x, direction.z).normalized().dot(Vector2(velocity.x, velocity.z).normalized()) * 0.5 - 0.45
				d += 1.0 - clamp(velocity.length(), 0.0, 18.0) / 18.0
				d = clamp(d, 0.0, 1.0)
				velocity += _dt * ACC_INAIR * direction * d
			
			if velocity.y < 0.0 && wall_normal:
				velocity.y += GRAVITY * _dt * 0.7
			if is_on_floor():
				state = states.STAND
		states.HOOKED:
			if Input.is_action_just_released("LMB"):
				$Node/Button13.play()
				state = states.STAND
				hook_target = null
				return
			var to_hook = hook_target.global_position - global_position
			var distance = to_hook.length()
			if distance == 0:
				return
			var dir = to_hook / distance
			var displacement = distance - hook_target.rest_length
			if displacement > 0:
				var spring_force = dir * displacement * hook_target.stiffness
				if spring_force.length() > hook_target.max_force:
					spring_force = spring_force.normalized() * hook_target.max_force
				var vel_along_rope = velocity.dot(dir)
				var damp_force = -dir * vel_along_rope * hook_target.damping
				var force = spring_force + damp_force
				velocity += force * _dt
			velocity.y -= GRAVITY * _dt
		states.RIDING:
			prev_ride_tick = true
			var p = global_position.y
			global_position = slider.papa.global_position
			p = lerp(p, slider.papa.global_position.y, _dt * 15.0)
			global_position.y = p
			if slider:
				velocity = Vector3.ZERO
			if Input.is_action_just_pressed("SPACE"):
				$Node/JumpSound1.play()
				prev_ride_tick = false
				state = states.INAIR
				velocity.y = JUMP_STRENGTH
				if slider:
					velocity += slider.last_dir.normalized() * slider.papa_speed
				inair_jumps = MAX_AIRJUMPS
				jump_buffer = -0.1
				cleanup_ride()
				return
			return
		states.SLIDING: pass
		states.DASH: pass
		states.ONWALL: pass
	handle_jump()
	move_and_slide()


func handle_jump():
	wall_normal = Vector3.ZERO
	var target = Vector3.ZERO
	var phys = PhysicsServer3D.space_get_direct_state(get_world_3d().space)
	for i in range(0, 360, 30):
		var ray = PhysicsRayQueryParameters3D.create(
			global_position, 
			global_position + Vector3(1, 0.5, 0).rotated(Vector3(0, 1, 0), deg_to_rad(i)), 1)
		var ray_coll = phys.intersect_ray(ray)
		if 'collider' in ray_coll.keys():
			target += ray_coll['normal']
	
	target = target.normalized()
	wall_normal = target
	if jump_buffer > 0.0:
		if state != states.HOOKED && target && !is_on_floor():
			$Node/JumpSound2.play()
			velocity.y = JUMP_STRENGTH
			velocity += target * 15
			state = states.INAIR
			jump_buffer = 0.0
			inair_jumps = MAX_AIRJUMPS
			return

		# coyote jump
		elif coyot_time < MAX_COYOT_TIME:
			$Node/JumpSound1.play()
			velocity.y = JUMP_STRENGTH
			jump_buffer = 0.0
			return

		# air jump
		elif inair_jumps > 0 and !is_on_floor():
			if state == states.HOOKED:
				return
			$Node/JumpSound2.play()
			inair_jumps -= 1
			velocity.y = JUMP_STRENGTH
			jump_buffer = 0.0


var sensitivity := 0.005
func _unhandled_input(event):
	if locked: return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * sensitivity)
		var target = -event.relative.y * sensitivity
		if target > 0:
			if camera.global_rotation.x + target < 1.53:
				camera.rotate_x(target)
		else:
			if camera.global_rotation.x + target > -1.53:
				camera.rotate_x(target)
	if event is InputEventMouseButton:
		if !$"../Control/CenterContainer".visible:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _on_area_3d_body_entered(body: Node3D) -> void:
	if !body.is_in_group("Player"): return
	lock_end()

func set_mouse_sensitivity(value: float):
	sensitivity = value


func _on_continue_pressed() -> void:
	$"../Control/CenterContainer".hide()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
