class_name CameraInput extends Node3D

@export var camera_mount : Node3D
@export var camera_rot : Node3D
@export var camera_3D : Camera3D
@export var holder: Marker3D

var camera_basis : Basis = Basis.IDENTITY
var camera_look : float = 0.0

@onready var camera_spring: SpringArm3D = $CameraMount/CameraRot/SpringArm3D

const CAMERA_SETTINGS_DEFAULT = {
	height = 1.6,
	length = 1.7,
	offset_x = 0.8,
}

const CAMERA_SETTINGS_AIM = {
	height = 1.5,
	length =  0.9,
	offset_x = 0.8,
}

const CAMERA_MOUSE_ROTATION_SPEED := 0.001
const CAMERA_X_ROT_MIN := deg_to_rad(-89.9)
const CAMERA_X_ROT_MAX := deg_to_rad(70)
const CAMERA_UP_DOWN_MOVEMENT = -1

func _ready():
	NetworkTime.before_tick_loop.connect(_gather)
	_set_camera(CAMERA_SETTINGS_DEFAULT)
	
	if multiplayer.get_unique_id() == str(get_parent().name).to_int():
		camera_3D.current = true
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	else:
		camera_3D.current = false

func _gather():
	if camera_mount.is_inside_tree():
		camera_basis = get_camera_rotation_basis()
		camera_look = get_camera_vertical_look()

func _input(event):
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return 
		
	if event is InputEventMouseMotion:
		rotate_camera(event.relative * CAMERA_MOUSE_ROTATION_SPEED)
	
	if event.is_action_pressed("aim"):
		_set_camera(CAMERA_SETTINGS_AIM)

	if event.is_action_released("aim"):
		_set_camera(CAMERA_SETTINGS_DEFAULT)

func _set_camera(_new_settings):
	camera_mount.position.y = _new_settings.height
	camera_spring.spring_length = _new_settings.length
	camera_spring.position.x = _new_settings.offset_x

func rotate_camera(move):
	# Horizontal camera movement
	# Currently, we only care to synch horizontal rotation, vertical camera changes are only for local client.
	camera_mount.rotate_y(-move.x)
	camera_mount.orthonormalize()
	# Vertical camera movement
	camera_rot.rotation.x = clamp(camera_rot.rotation.x + (CAMERA_UP_DOWN_MOVEMENT * move.y), CAMERA_X_ROT_MIN, CAMERA_X_ROT_MAX)

func get_camera_rotation_basis() -> Basis:
	# Use camera_mount here so we don't have to worry about correcting for lean
	# TODO: E 0:00:14:842   camera_input.gd:71 @ get_camera_rotation_basis(): Condition "!is_inside_tree()" is true. Returning: Transform3D()
	#if !is_inside_tree() == true:
		#return Basis.IDENTITY
	return camera_mount.global_transform.basis

func get_camera_vertical_look() -> float:
	return camera_rot.rotation.x
	
func _exit_tree():
	NetworkTime.before_tick_loop.disconnect(_gather)
