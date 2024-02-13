extends Node2D


export (float) var rotation_speed: = 1.57
export (float) var rotation_distance: = 200

onready var sprite: Sprite = $Sprite
onready var hitbox = $Hitbox

var _elements: Array = []
var _angle: float = 0.0
var _parent: Node2D
var _start_angle: float = 0.0


func init(start_angle: float = 0.0)->void :
	_start_angle = start_angle


func set_damage(damage: int)->void :
	hitbox.damage = damage


func set_texture(texture: Texture)->void :
	sprite.texture = texture


func set_distance(distance: float)->void :
	rotation_distance = distance


func set_rotation_speed(speed: float)->void :
	rotation_speed = speed


func _ready()->void :
	_angle += _start_angle
	
	_parent = get_parent().get_parent().get_parent()


func _physics_process(delta: float)->void :
	_angle += delta * rotation_speed
	var s: float = sin(_angle)
	var c: float = cos(_angle)
	global_position = Vector2(_parent.global_position.x + c * rotation_distance, _parent.global_position.y + s * rotation_distance)
