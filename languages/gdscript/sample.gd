#!/usr/bin/env -S godot --headless --script
# GDScript (Godot 4.5) — syntax showcase
@tool
@icon("res://icons/player.svg")
@static_unload
class_name Player extends CharacterBody2D
## Godot 4 player showcase: documentation comment with BBCode.
## [b]Bold[/b], [i]italic[/i], [code]code[/code], [param speed], [member lives],
## [method take_damage], [signal died], [enum State], [constant MAX_LIVES].
## @tutorial(Docs): https://example.com/docs
## @experimental
# Regular comment. TODO: split into components. FIXME: coyote time.

# ── Signals ──
signal died(cause: String)
signal item_picked(sku: String, qty: int)
signal ready_to_ship

# ── Enums and constants ──
enum State { IDLE, RUNNING = 5, JUMPING, FALLING }
enum Named { A = 1, B = 1 << 1, C = 1 << 2 }
const MAX_LIVES := 3
const GRAVITY_SCALE: float = 1.5
const NAMES = ["widget", "gadget"]
const LOOKUP = {"a": 1, "b": 2}
const PI_ISH = PI / 2.0 + TAU - INF + NAN

# ── Exports and annotations ──
@export var speed: float = 220.0
@export_range(0, 100, 0.5, "or_greater") var health: float = 100.0
@export_enum("Small", "Medium", "Large") var size: int = 1
@export_file("*.json") var config_path: String
@export_dir var data_dir: String
@export_multiline var notes: String = ""
@export_color_no_alpha var tint: Color = Color.WHITE
@export_flags("Fire", "Water", "Earth") var element_flags: int = 0
@export_group("Movement")
@export var jump_velocity: float = -420.0
@export_subgroup("Advanced")
@export var air_control: float = 0.5
@export_category("Inventory")
@export var items: Array[String] = []
@export var node_ref: NodePath
@export_node_path("Sprite2D") var sprite_path: NodePath
@export_custom(PROPERTY_HINT_NONE, "") var custom_value
@onready var sprite: AnimatedSprite2D = $Sprite
@onready var timer: Timer = $"Path/To/Timer"
@onready var unique: Label = %UniqueLabel
@onready var parent_label := get_node("../Label") as Label
@warning_ignore("unused_variable", "shadowed_variable")

# ── Variables ──
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var _lives := 3
var untyped
var state: State = State.IDLE
var velocity_hist: PackedVector2Array = PackedVector2Array()
var matrix: Array[Array] = []
var lookup: Dictionary[String, int] = {}
static var instance_count: int = 0
var health_prop: int:
	set(value):
		health_prop = clampi(value, 0, 100)
	get:
		return health_prop
var legacy_prop: int = 0 : set = set_legacy, get = get_legacy

# ── Literals ──
var integer := 42
var negative := -17
var hex := 0xFF_EE
var binary := 0b1010_0101
var big := 1_000_000
var floating := 3.14
var exponent := 6.02e23
var leading_dot := .5
var trailing_dot := 5.
var truth := true
var falsity := false
var nothing = null
var simple_str := "double \"quoted\" \\ \n\t \u00e9 \U01F600 \x41"
var single_str := 'single \'quoted\''
var raw_str := r"C:\warehouse\bin"
var triple_str := """multi
line "string" here"""
var triple_single := '''another
multi-line'''
var string_name := &"idle"
var node_path := ^"Player/Sprite"
var unique_path := ^"%Unique"
var formatted := "%d lives, %s, %5.2f, %x" % [3, "name", 2.5, 255]
var format_dict := "{a} and {b}".format({"a": 1, "b": 2})
var arr := [1, 2.5, "three", [4], {"k": "v"}, null, true]
var dict := {"name": "widget", "qty": 3, nested = {x = 1}, 42: "answer", Vector2(1, 2): "pos"}
var vec := Vector2(1.0, 2.0)
var vec3 := Vector3.ZERO + Vector3(1, 2, 3)
var color := Color(1, 0.5, 0, 1) + Color("#ff8800") + Color8(255, 128, 0)
var rect := Rect2(0, 0, 10, 20)
var typed_array: Array[int] = [1, 2, 3]
var callable_ref := Callable(self, "take_damage")
var lambda_var := func(a, b): return a + b

# ── Inner class, inheritance ──
class Inventory extends RefCounted:
	var count: int = 0
	func _init(initial: int = 0) -> void:
		count = initial
	func add(n: int) -> void:
		count += n

class Item:
	extends Resource
	@export var sku: String
	@export var qty: int

# ── Lifecycle and virtual functions ──
func _init() -> void:
	instance_count += 1

func _ready() -> void:
	print("ready: ", name, " ", get_path())
	timer.timeout.connect(_on_timer_timeout)
	died.connect(func(cause): print("died: %s" % cause), CONNECT_ONE_SHOT)
	item_picked.emit("A-1", 2)
	sprite.animation_finished.connect(_on_anim_done.bind("idle"))
	if Engine.is_editor_hint():
		return

func _enter_tree() -> void: pass
func _exit_tree() -> void: pass
func _process(delta: float) -> void: pass

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity
	var direction := Input.get_axis("move_left", "move_right")
	velocity.x = direction * speed if direction else move_toward(velocity.x, 0, speed)
	sprite.flip_h = velocity.x < 0
	move_and_slide()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton:
		pass

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"): get_tree().quit()

# ── Functions: defaults, typed, variadic-ish, static, await, coroutines ──
func take_damage(amount: int = 1) -> void:
	_lives -= amount
	match _lives:
		0:
			died.emit("out of lives")
			queue_free()
		1, 2:
			print("careful")
		1.5:
			pass
		"text":
			pass
		[1, 2, ..]:
			pass
		{"key": var v, ..}:
			print(v)
		var other when other < 0:
			print("negative")
		State.IDLE:
			pass
		_:
			print("%d lives left" % _lives)

static func clamp_health(h: float, lo: float = 0.0, hi: float = 100.0) -> float:
	return clampf(h, lo, hi)

func compute(a: int, b: int) -> int:
	return a + b * 2 - (a % b) / 3 if b != 0 else a

func generic_array() -> Array[Item]:
	return []

func wait_then_log() -> void:
	await get_tree().create_timer(1.0).timeout
	var result = await some_signal
	print("waited ", result)

func _on_timer_timeout() -> void: pass
func _on_anim_done(anim: StringName) -> void: pass
func set_legacy(v: int) -> void: legacy_prop = v
func get_legacy() -> int: return legacy_prop

# ── Operators ──
func operators() -> void:
	var a := 10
	var b := 3
	var r := a + b - a * b / a % b
	r += 1
	r -= 1
	r *= 2
	r /= 2
	r %= 5
	r **= 2
	r &= 0xF
	r |= 0x1
	r ^= 0x3
	r <<= 1
	r >>= 1
	var p := a ** b
	var bits := (a & b) | (a ^ b) | ~a | (a << 2) | (a >> 1)
	var logic := (a > b and b < a) or not (a == b) or (a != b && a >= b || a <= b)
	var contained := 2 in [1, 2, 3]
	var not_contained := 5 not in [1, 2, 3]
	var is_check := self is Node
	var cast := self as Node2D
	var ternary := "big" if a > 5 else "small"
	var tcall := Callable(self, "x").call()
	var idx := arr[0]
	var neg_idx := arr[-1]
	var slice := arr.slice(1, 3)
	var dotted := get_node("Sprite").position.x
	var coalesce := dict.get("missing", 0)
	var preloaded = preload("res://scenes/item.tscn")
	var loaded = load("res://scenes/item.tscn")
	var instanced = preloaded.instantiate()
	var range_arr := range(0, 10, 2)

# ── Control flow ──
func control_flow() -> void:
	if _lives > 0 and not is_queued_for_deletion():
		pass
	elif _lives == 0:
		pass
	else:
		pass
	for i in range(10):
		if i == 3: continue
		if i == 8: break
	for item in items:
		print(item)
	for i: int in 5:
		print(i)
	for key in dict:
		print(key, dict[key])
	var n := 0
	while n < 3:
		n += 1
	pass
	assert(n == 3, "n should be 3")
	breakpoint

func generator() -> void:
	var values := []
	for i in 3: values.append(i * i)
	var squares := values.map(func(v): return v * v)
	var evens := values.filter(func(v): return v % 2 == 0)
	var total := values.reduce(func(acc, v): return acc + v, 0)

# ── Rpc and remote ──
@rpc("any_peer", "call_local", "reliable")
func sync_stock(sku: String, qty: int) -> void:
	print("sync %s x%d" % [sku, qty])

@rpc("authority")
func notify() -> void: pass

# ── Setgetter lambdas and signals with type hints ──
func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	if speed <= 0.0:
		warnings.append("Speed must be positive.")
	return warnings

func _to_string() -> String:
	return "Player<%s, lives=%d>" % [name, _lives]

# Non-ASCII: ¡Hola! 你好 こんにちは

# ── Regions and line continuation ──
#region Extra annotations
@export_exp_easing("attenuation") var easing: float = 1.0
@export_global_file("*.png") var texture_path: String
@export_global_dir var global_dir: String
@export_placeholder("Type here") var placeholder_text: String
@export_file_path("*.tscn") var scene_path: String
@export_storage var hidden_storage: int
@export_tool_button("Rebuild") var rebuild_button = _rebuild
@export_flags_2d_physics var collision_layers: int
@export_flags_2d_render var render_layers: int
@export_flags_2d_navigation var nav_layers: int
@export_flags_3d_physics var collision_layers_3d: int
@export_flags_3d_render var render_layers_3d: int
@export_flags_3d_navigation var nav_layers_3d: int
@export_flags_avoidance var avoidance_layers: int
@export_range(0.0, 1.0, 0.01, "or_less", "hide_slider", "suffix:px") var ratio: float = 0.5
@export_enum("A:1", "B:2", "C:4") var tagged_enum: int = 1
@export_enum("alpha", "beta") var string_enum: String = "alpha"
@export_node_path("Node2D", "Control") var multi_path: NodePath
@export var typed_dict: Dictionary[String, int] = {}
@export var packed: PackedScene
@export var resource: Resource
@export var curve: Curve
@export var colors: PackedColorArray = PackedColorArray()
@warning_ignore_start("unused_parameter")
func ignores_warnings(unused: int) -> void: pass
@warning_ignore_restore("unused_parameter")
#endregion

# ── More literals ──
var lit_exp := 1e10
var lit_exp_neg := 1E-5
var lit_hex_big := 0xDEAD_BEEF
var lit_bin_big := 0b1111_0000
var lit_underscore := 1_000.5
var lit_string_unicode := "\u00e9 \U01F600 \x41 \101 \a \b \f \r \v \0 \\ \' \""
var lit_string_name_esc := &"with \"escape\""
var lit_node_path_dollar := $Sprite/Child
var lit_node_path_quoted := $"Sprite/Child With Space"
var lit_unique_quoted := %"Unique Name"
var lit_continued := 1 + \
	2 + \
	3
var lit_multi_line_array := [
	1,
	2,
	3,
]
var lit_multi_line_dict := {
	"a": 1,
	"b": 2,
}
var lit_all_vectors := [Vector2i(1, 2), Vector3i(1, 2, 3), Vector4(1, 2, 3, 4), Vector4i.ZERO, Quaternion.IDENTITY, Basis.IDENTITY, Transform2D.IDENTITY, Transform3D.IDENTITY, Plane.PLANE_XY, AABB(), Rect2i(), RID(), Projection.IDENTITY]
var lit_packed := [PackedByteArray(), PackedInt32Array(), PackedInt64Array(), PackedFloat32Array(), PackedFloat64Array(), PackedStringArray(), PackedVector2Array(), PackedVector3Array(), PackedVector4Array()]
var lit_consts := [PI, TAU, INF, NAN, true, false, null]

# ── Docstring-style multiline string and print forms ──
func printing() -> void:
	print("simple")
	print("a", "b", 3)
	prints("space", "separated")
	printt("tab", "separated")
	printerr("to stderr")
	print_rich("[b]bold[/b] [color=red]red[/color] [url=https://example.com]link[/url]")
	print_debug("with stack")
	print_stack()
	push_warning("careful")
	push_error("broken")
	printraw("raw")
	print("%s %d %f %x %o %e %c %v %%" % ["s", 1, 2.5, 255, 8, 1.0, 65, Vector2.ONE])
	print("%5d|%-5d|%05d|%+d|%.3f|%10.2f|%*d" % [1, 2, 3, 4, 5.0, 6.0, 4, 7])

# ── Remaining control flow and operators ──
func rest() -> void:
	var a = 1
	var b = 2
	if a == 1: print("inline if")
	elif a == 2: print("inline elif")
	else: print("inline else")
	while a < 3: a += 1
	for i in 3: pass
	for c in "chars": print(c)
	for v in [Vector2.ZERO, Vector2.ONE]: print(v)
	var x = a if a > b else b
	var y = (a > b) and (b > 0) or not (a == b)
	var z = a != b && a >= b || a <= b
	var w = (1 + 2) * 3 - 4 / 2 % 3 ** 2
	w += 1; w -= 1; w *= 2; w /= 2; w %= 3; w **= 2
	w <<= 1; w >>= 1; w &= 7; w |= 1; w ^= 2
	var bits = ~w & 3 | 4 ^ 5 << 1 >> 1
	var membership = 1 in [1, 2] and "k" in {"k": 1} and "s" in "string"
	var typed_check = a is int and self is Node and not (self is Control)
	var cast = self as Node
	var neg = -a + +b
	var chained = get_node(".").get_parent().get_child(0).name.to_upper().length()
	var cb = func(): return 1
	var cb2 = func(p: int) -> int: return p + 1
	var cb3 = func(p):
		var q = p * 2
		return q
	var called = cb.call() + cb2.call(1) + cb3.callv([2])
	var bound = cb2.bind(1).call()
	var await_it = await get_tree().process_frame
	var static_call = Player.clamp_health(50.0)
	var enum_val = State.RUNNING
	var enum_keys = State.keys()
	var super_name = super._to_string() if false else ""
	assert(a > 0)
	assert(a > 0, "a must be positive")
	return

# ── Abstract and static inner types ──
@abstract class AbstractThing:
	@abstract func do_it() -> void
	@abstract func get_value() -> int

class Concrete extends AbstractThing:
	func do_it() -> void: pass
	func get_value() -> int: return 1


# ── Godot 4.5 additions: variadic functions, super, is_instance_valid, typed collections ──
func variadic_sum(...numbers: Array) -> int:
	var total := 0
	for n in numbers:
		total += n
	return total

func variadic_with_fixed(label: String, ...rest: Array) -> String:
	return label + str(rest.size())

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_READY:
			pass
		NOTIFICATION_PREDELETE:
			pass

class Child extends Inventory:
	func _init(initial: int = 1) -> void:
		super(initial)
	func add(n: int) -> void:
		super.add(n * 2)
		super(n)

var typed_in_loop := func() -> void:
	for i: int in [1, 2, 3]:
		print(i)
	for key: String in {"a": 1}:
		print(key)

var typed_dict_literal: Dictionary[StringName, Array] = {&"a": [1]}
var typed_array_of_arrays: Array[Array] = [[1], [2]]
var ternary_chain := "a" if _lives > 2 else "b" if _lives > 1 else "c"

func pattern_matching_extras(value: Variant) -> String:
	match value:
		null: return "null"
		true, false: return "bool"
		0: return "zero"
		-1: return "minus one"
		0x10: return "hex"
		"str": return "string"
		&"name": return "string name"
		[]: return "empty array"
		[var first, var second]: return "pair %s %s" % [first, second]
		[1, ..]: return "starts with one"
		{}: return "empty dict"
		{"a": 1}: return "has a"
		{"k": var kv, ..}: return str(kv)
		State.IDLE, State.RUNNING: return "enum"
		var x when x is int and x > 100: return "big"
		var y: return "other %s" % y
