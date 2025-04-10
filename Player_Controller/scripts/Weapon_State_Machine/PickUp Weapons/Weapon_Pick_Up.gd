extends RigidBody3D
class_name WeaponPickUp

@export var weapon: WeaponSlot
@export_enum("Weapon","Ammo") var TYPE = "Weapon"

var Pick_Up_Ready: bool = false

func _ready():
	await get_tree().create_timer(2.0).timeout
	Pick_Up_Ready = true

func _process(delta: float) -> void:
	if Hub.world.castle_speed != 0.0:
		translate(Vector3(0.0,0.0,0.0125))
