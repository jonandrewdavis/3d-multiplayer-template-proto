class_name Player extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

@export var _player_input : PlayerInput
@export var _camera_input : CameraInput
@export var _player_model : Node3D
@export var _state_machine: RewindableStateMachine
@export var skeleton: Skeleton3D

@onready var rollback_synchronizer = $RollbackSynchronizer

signal ragdoll 

var _animation_player

func _enter_tree():
	_player_input.set_multiplayer_authority(str(name).to_int())
	_camera_input.set_multiplayer_authority(str(name).to_int())

func _ready():
	# Default state
	_state_machine.state = &"IdleState"
	_animation_player = _player_model.get_node("AnimationPlayer")
	
	print(_animation_player)
	# TODO: can this be moved to movement_state
	_state_machine.on_display_state_changed.connect(_on_display_state_changed)

	# call this after setting authority
	# https://foxssake.github.io/netfox/netfox/tutorials/responsive-player-movement/#ownership
	rollback_synchronizer.process_settings()
	
	ragdoll.connect(_on_ragdoll)
	print(skeleton)
	

func _rollback_tick(delta: float, _tick: int, _is_fresh: bool) -> void:
	_force_update_is_on_floor()
	if not is_on_floor():
		apply_gravity(delta)

# TODO: use statemachine to transition in AnimationStateTre
# TODO: every or just sync: the interpolation
func _on_display_state_changed(old_state, new_state):	
	var animation_name = new_state.animation_name
	if _animation_player && animation_name != "":
		if animation_name == "rifle run" && _player_input.input_dir.y == 0:
			if _player_input.input_dir.x > 0:
				_animation_player.play("strafe")
			else:
				_animation_player.play("strafe (2)")
		else:
			# print("Play animation %s" % animation_name)
			_animation_player.play(animation_name)

func apply_gravity(delta):
	velocity.y -= gravity * delta
				
# https://foxssake.github.io/netfox/netfox/tutorials/rollback-caveats/#characterbody-on-floor
func _force_update_is_on_floor():
	var old_velocity = velocity
	velocity *= 0
	move_and_slide()
	velocity = old_velocity

var is_ragdoll = false

func _on_ragdoll():
	if skeleton && is_ragdoll == false:
		skeleton.physical_bones_start_simulation()