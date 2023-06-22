extends Node


var _projectile_stacks:Dictionary = {}


func add_stack(type)->void :
	if not _projectile_stacks.has(type):
		_projectile_stacks[type] = 0
	_projectile_stacks[type] += 1


func remove_stack(type)->void :
	if not _projectile_stacks.has(type):
		_projectile_stacks[type] = 0
		return
	_projectile_stacks[type] = max(_projectile_stacks[type]-1, 0) as int


func get_stack_count(type)->int :
	if _projectile_stacks.has(type):
		return _projectile_stacks[type]
	else:
		return -1
