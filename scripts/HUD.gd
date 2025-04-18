extends CanvasLayer
class_name PlayerHUD

@export var weapons_manager: WeaponsManager

@onready var current_weapon_label = $debug_hud/HBoxContainer/CurrentWeapon
@onready var current_ammo_label = $debug_hud/HBoxContainer2/CurrentAmmo
@onready var current_weapon_stack = $debug_hud/HBoxContainer3/WeaponStack
@onready var hit_sight = $HitSight
@onready var overlay = $Overlay

@onready var sync = $MultiplayerSynchronizer

# TODO: Is this the best place for these?
#signal weapon_changed
#signal update_ammo
#signal update_weapon_stack
#signal hit_signal
#signal add_signal_to_hud

var hit_sight_timer = Timer.new()

func _ready():
	#DebugMenu.style = DebugMenu.Style.VISIBLE_DETAILED

	if !weapons_manager:
		push_warning("Player's HUD has no weapon manager.")
		return

	# NOTE: Hide this node if it's on a client & it's not owned by that client.
	if not multiplayer.is_server():
		if str(multiplayer.get_unique_id()) != get_parent().name:
			hide()
			set_process(false)
	
	Lodash.sync_property(sync, current_ammo_label, ['text'])
	Lodash.sync_property(sync, hit_sight, ['visible'])
	Lodash.sync_property(sync, current_weapon_label, ['text'])

	# Hit Sight
	add_child(hit_sight_timer)
	hit_sight_timer.wait_time = 0.05
	hit_sight_timer.one_shot = true
	hit_sight_timer.timeout.connect(_on_hit_sight_timer_timeout)


func _on_weapons_manager_update_weapon_stack(WeaponStack):
	current_weapon_stack.text = ""
	for i in WeaponStack:
		current_weapon_stack.text += "\n"+i.weapon.weapon_name

func update_ammo(ammo: Array[int]):
	current_ammo_label.set_text(str(ammo[0])+" / "+str(ammo[1]))

func update_weapon(weapon_name: String):
	current_weapon_label.set_text(weapon_name)

func _on_weapons_manager_weapon_changed(WeaponName):
	current_weapon_label.set_text(WeaponName)

func _on_weapons_manager_hit_signal():
	hit_sight.set_visible(true)
	hit_sight_timer.start()

func _on_hit_sight_timer_timeout():
	hit_sight.set_visible(false)

func load_over_lay_texture(Active:bool, txtr: Texture2D = null):
		overlay.set_texture(txtr)
		overlay.set_visible(Active)

func _on_weapons_manager_connect_weapon_to_hud(_weapon_resouce: WeaponResource):
	_weapon_resouce.update_overlay.connect(load_over_lay_texture)
