# TODO: This entire part of the code-base needs a complete refactor.

extends Node3D
class_name Projectile

signal hit_signal

## Can Be Either A Hit Scan or Rigid Body Projectile. If Rigid body is select a Rigid body must be provided.
@export_enum ("Hitscan","Rigidbody_Projectile","over_ride") var Projectile_Type: String = "Hitscan"

# TODO: Better decals (flat).
@export var Display_Debug_Decal: bool = false

@export var Projectile_Velocity: int = 20
@export var Expirey_Time: int = 5
@export var Rigid_Body_Projectile: PackedScene
@export var pass_through: bool = false

@onready var world = get_tree().get_first_node_in_group("EnvironmentContainer")
var debug_bullet

var damage: float = 0
var Projectiles_Spawned = []
var hit_objects: Array = []

# TODO: un hardcode viewport -AD
# TODO: Needs to be set by the player, since all players  could have different viewports
var _Camera: Camera3D
var _Viewport = Vector2i(1152, 648)

func _ready() -> void:
	pass

func _Set_Projectile(_damage: int = 0,_spread:Vector2 = Vector2.ZERO, _Range: int = 1000, origin_point: Vector3 = Vector3.ZERO):
	damage = _damage
	Fire_Projectile(_spread, _Range, Rigid_Body_Projectile, origin_point, )

func Fire_Projectile(_spread: Vector2 ,_range: int, _proj:PackedScene, origin_point: Vector3):
	var Camera_Collision = Camera_Ray_Cast(_spread,_range)
	
	match Projectile_Type:
		"Hitscan":
			Hit_Scan_Collision(Camera_Collision, damage, origin_point)
		"Rigidbody_Projectile":
			Launch_Rigid_Body_Projectile(Camera_Collision, Rigid_Body_Projectile, origin_point)
		"over_ride":
			_over_ride_collision(Camera_Collision, damage)

func _over_ride_collision(_camera_collision:Array, _damage: float) -> void:
	pass

func Camera_Ray_Cast(_spread: Vector2 = Vector2.ZERO, _range: float = 1000):
	var Ray_Origin = _Camera.project_ray_origin(_Viewport/2)
	var Ray_End = (Ray_Origin + _Camera.project_ray_normal((_Viewport/2)+Vector2i(_spread)) * _range)
	var New_Intersection:PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(Ray_Origin,Ray_End)
	New_Intersection.set_collision_mask(0b11101111) # 15? 
	New_Intersection.set_hit_from_inside(false) # In Jolt this is set to true by defualt
	
	var Intersection = get_world_3d().direct_space_state.intersect_ray(New_Intersection)
	
	if Intersection.is_empty():
		return [null, Ray_End, null]	
	
	if Intersection.position.distance_to(Ray_Origin) < 4.0:
		return [null, Ray_End, null]
	
	return [Intersection.collider,Intersection.position,Intersection.normal]


func Hit_Scan_Collision(Collision: Array,_damage: float, origin_point: Vector3):
	var Point = Collision[1]
	if Collision[0]:
		Load_Decal(Point, Collision[2])
		
		if Collision[0].is_in_group("targets"):
			var Bullet = get_world_3d().direct_space_state

			var Bullet_Direction = (Point - origin_point).normalized()
			var New_Intersection = PhysicsRayQueryParameters3D.create(origin_point,Point+Bullet_Direction*2)
			New_Intersection.set_collision_mask(0b11101111)
			New_Intersection.set_hit_from_inside(false)
			New_Intersection.set_exclude(hit_objects)
			var Bullet_Collision = Bullet.intersect_ray(New_Intersection)
	
			if Bullet_Collision:
				Hit_Scan_damage(Bullet_Collision.collider, Bullet_Direction,Bullet_Collision.position,_damage)
				if pass_through and check_pass_through(Bullet_Collision.collider, Bullet_Collision.rid):
					var pass_through_collision : Array = [Bullet_Collision.collider, Bullet_Collision.position, Bullet_Collision.normal]
					var pass_through_damage: float = damage/2
					Hit_Scan_Collision(pass_through_collision,pass_through_damage,Bullet_Collision.position)
					return
			queue_free()

func check_pass_through(collider: Node3D, rid: RID)-> bool:
	var valid_pass_though: bool = false
	if collider.is_in_group("Pass Through"):
		hit_objects.append(rid)
		valid_pass_though = true
	return valid_pass_though

func Hit_Scan_damage(collision, _direction, _position, _damage):
	if collision.is_in_group("targets") and collision.has_method("hit"):
		hit_signal.emit()
		collision.hit(_damage)

# This can create an error sometimes in headless mode (mmesh_get_surface_count).
# Upgrade to 4.4 to fix.
func Load_Decal(pos, normal):
	if Display_Debug_Decal:
		var rd = debug_bullet.instantiate()
		if world:
			world.add_child(rd, true)
			rd.global_translate(pos+(normal*.01))

func Launch_Rigid_Body_Projectile(collision_data, projectile, origin_point):
	var point = collision_data[1]
	var norm = collision_data[2]

	var _proj = projectile.instantiate()

	_proj.position = origin_point

	world.add_child(_proj, true)
	
	_proj.look_at(point)	
	Projectiles_Spawned.push_back(_proj)

	_proj.body_entered.connect(_on_body_entered.bind(_proj, norm))
	
	var _direction = (point - origin_point).normalized()
	_proj.set_linear_velocity( _direction * Projectile_Velocity)
	
	# NOTE: Added, because in the previous implementation timer wasn't started, so...  - AD
	await get_tree().create_timer(Expirey_Time).timeout
	_proj.queue_free()
	Projectiles_Spawned.erase(_proj)
	
	if Projectiles_Spawned.is_empty():
		queue_free()

# TODO: Add static typing. What is _norm?  It's sometimes missing.
# NOTE: "invalid operands 'Nil' and 'float' in operator * caused at this call site - AD
func _on_body_entered(body, proj, norm):
	#print('DEBUG: BODY:', body, '_proj: ', proj, 'norm: ', norm)
	
	if body.is_in_group("targets") && body.has_method("hit"):
		body.hit(damage)
		hit_signal.emit()
		
	if body.is_in_group("players") && body.has_method("hit"):
		body.hit(damage)
		hit_signal.emit()

	if norm:
		Load_Decal(proj.get_position(),norm)
		proj.queue_free()
		Projectiles_Spawned.erase(proj)
		if Projectiles_Spawned.is_empty():
			queue_free()
