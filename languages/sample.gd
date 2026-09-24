# Godot 4: a player that moves, jumps and reports its state.
extends CharacterBody2D
class_name Player

signal died(cause: String)

@export var speed: float = 220.0
@export var jump_velocity: float = -420.0
@onready var sprite: AnimatedSprite2D = $Sprite

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var _lives := 3

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity
	var direction := Input.get_axis("move_left", "move_right")
	velocity.x = direction * speed if direction else move_toward(velocity.x, 0, speed)
	sprite.flip_h = velocity.x < 0
	move_and_slide()

func take_damage(amount: int = 1) -> void:
	_lives -= amount
	match _lives:
		0:
			died.emit("out of lives")
			queue_free()
		1:
			print("last life!")
		_:
			print("%d lives left" % _lives)
