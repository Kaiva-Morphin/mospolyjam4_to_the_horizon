extends CharacterBody3D
#region DEBUG
var DEBUG_UPDATE = false
var SHOW_DEBUG = false
var DEBUG_STRING = ""

func init_debug():
	$DEBUG.show()

var debug = {}

func dbg(key, value):
	debug[key] = value

func update_debug():
	var dbg = []
	var keys = debug.keys()
	keys.sort()
	for key in keys:
		dbg.append(key+" "+str(debug[key]))
	
	DEBUG_STRING = \
	"DEBUG\n" + \
	"STATE: " + GLOBAL.ENTITY_STATE.keys()[state] + "\n" + \
	"DIR: " + str(input_dir)
	$DEBUG2.text = "\n".join(dbg)

#endregion

#region CONSTS
var INAIR_SPEED := 10.0
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
var GRAVITY : float = ProjectSettings.get_setting("physics/3d/default_gravity") 
var MAX_SLOPE_ANGLE := deg_to_rad(45.0)
var MAX_COYOT_TIME = 0.1
var JUMP_STRENGTH = 5.0

func _process(_dt: float) -> void:
	update_debug()
	if Input.is_action_just_pressed("ESC"):
		if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		else:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if state == GLOBAL.ENTITY_STATE.SLIDING:
		camera.position.y = lerp(camera.position.y, crunch_camera_target.position.y, _dt * CAMERA_INTERPOLATION_SPEED)
	else:
		camera.position.y = lerp(camera.position.y, stand_camera_target.position.y, _dt * CAMERA_INTERPOLATION_SPEED)
	#INAIR_SPEED = 2.0
	#ACC_SPEED = 50.0
	#DEC_SPEED = 0.08
	#RUN_SPEED = 20.0
	#SLIDE_SPEED = ACC_SPEED * 1.3
	#JUMP_VELOCITY = 30
	#MAX_WALLJUMPS = 3
	#MAX_AIRJUMPS = 1
	#CAMERA_INTERPOLATION_SPEED = 20.0
	#MAX_ENERGY = 300
	#MAX_SLOPE_ANGLE = deg_to_rad(45.0)

func _notification(what):
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if what == NOTIFICATION_WM_WINDOW_FOCUS_IN:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	
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
const states = GLOBAL.ENTITY_STATE

var origin
func _ready() -> void:
	init_debug()
	origin = global_position


var coyot_time = 0.0
func _physics_process(_dt: float) -> void:
	if is_on_floor():
		coyot_time = 0.0
	else:
		coyot_time += _dt
	
	input_dir = Input.get_vector("A", "D", "W", "S")

	var direction = (transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()

	var floor_normal := Vector3.UP
	if is_on_floor():
		floor_normal = get_floor_normal()
	
	if is_on_floor():
		inair_jumps = MAX_AIRJUMPS

	if direction != Vector3.ZERO:
		direction = direction.slide(floor_normal).normalized()

	dbg("STATE: ", states.keys()[state])
	dbg("NORMAL: ", floor_normal)
	dbg("DIRECTION: ", direction)
	dbg("VELOCITY: ", velocity)
	
	handle_jump()

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
				# todo: use a dot product
				velocity = velocity.move_toward(direction * RUN_SPEED, _dt * ACC_SPEED)
			else:
				state = states.STAND
		states.INAIR:
			velocity.y -= GRAVITY * _dt
			if direction:
				var d = 1.0 - Vector2(direction.x, direction.z).normalized().dot(Vector2(velocity.x, velocity.z).normalized()) * 0.5 - 0.30
				dbg("DOT: ", d)
				velocity += _dt * INAIR_SPEED * direction
			if velocity.y < 0.0:
				state = states.FALLING
			if is_on_floor():
				state = states.STAND
		states.FALLING:
			velocity.y -= GRAVITY * _dt
			if direction:
				var d = 1.0 - Vector2(direction.x, direction.z).normalized().dot(Vector2(velocity.x, velocity.z).normalized()) * 0.5 - 0.30
				dbg("DOT: ", d)
				velocity += _dt * INAIR_SPEED * direction
			if velocity.y > 0.0:
				state = states.INAIR
			if is_on_floor():
				state = states.STAND
		states.SLIDING: pass
		states.HOOKED: pass
		states.DASH: pass
		states.ONWALL: pass
	move_and_slide()



func handle_jump():
	if Input.is_action_pressed("SPACE"):
		if coyot_time < MAX_COYOT_TIME:
			velocity.y = JUMP_STRENGTH
			return
	if Input.is_action_just_pressed("SPACE") && inair_jumps > 0 && !is_on_floor():
			print("inair")
			inair_jumps -= 1
			velocity.y = JUMP_STRENGTH


func _unhandled_input(event):
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * 0.005)
		var target = -event.relative.y * 0.005
		if target > 0:
			if camera.global_rotation.x + target < 1.53:
				camera.rotate_x(-event.relative.y * 0.005)
		else:
			if camera.global_rotation.x + target > -1.53:
				camera.rotate_x(-event.relative.y * 0.005)
	if event is InputEventMouseButton:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
