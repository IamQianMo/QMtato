extends Node2D


onready var animation = $Animation
onready var p0 = $Animation/P0

onready var _children_protections: Array = [p0]

var _angle: float = 0.0
var _shrink_speed: float = 1.04
var _rotation_distance: float = 0.0
var _damage: int = 1


func set_damage(damage: int)->void :
	_damage = damage


func _ready()->void :
	get_parent().connect("died", self, "_on_parent_died")


func _on_parent_died(_enemy)->void :
	queue_free()


func init(count: int = 1, start_angle: float = 0.0, extra_distance: float = 0.0)->void :
	_rotation_distance = p0.rotation_distance
	p0.set_damage(_damage)
	if count > 1:
		var angle_step: float = 2 * PI / count
		var base_angle: = angle_step
		count -= 1
		for i in count:
			var child: Node2D = p0.duplicate()
			child.init(base_angle + angle_step * i)
			animation.add_child(child)
			child.set_damage(_damage)
			_children_protections.append(child)


func _physics_process(delta: float)->void :
	_angle += delta * _shrink_speed
	for child in _children_protections:
		child.set_distance(_rotation_distance * abs(sin(_angle)))
