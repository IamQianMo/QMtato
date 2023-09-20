extends Node2D


signal particle_end(body)


export (Resource) var shader

var _parent = null
var _original_shader = null
var _sprite = null
var _progress: = 0.0


func _ready():
	_parent = get_parent()
	
	_sprite = _parent.get("sprite")
	
	if _sprite:
		_parent._move_locked = true
		_parent._current_movement = Vector2.ZERO
		
		_original_shader = _sprite.material.shader
		_sprite.material.call_deferred("set_shader", shader)
	else:
		emit_signal("particle_end", _parent)
	
		queue_free()


func change_shader_progress(progress:float)->void :
	_sprite.material.set_shader_param("color", Color8(0, 260, 306, 255))
	_sprite.material.set_shader_param("beam_size", 0.05)
	_sprite.material.set_shader_param("progress", progress)


func _physics_process(delta):
	_progress += delta * 1.5
	change_shader_progress(_progress)
	
	if _progress >= 1.0:
		_sprite.material.call_deferred("set_shader", _original_shader)
		_parent._move_locked = false
	
		emit_signal("particle_end", _parent)
	
		queue_free()
