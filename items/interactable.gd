class_name Interactable
extends Area2D
## Something the player uses with the interact action (W / Y): a pedestal, a
## quantum well, a shop stand, a rest choice. It sits on the pickups layer and
## the player's interaction area finds it; the closest enabled one gets the
## focus and shows its prompt ("[W] 5 γ") above it. Its owner listens to
## `interacted` and decides what happens. Give it a CollisionShape2D child.

signal interacted(player: Player)

const ACTION: StringName = &"interact"
const PROMPT_WIDTH: float = 220.0
const PROMPT_FONT_SIZE: int = 15
const PROMPT_OUTLINE: int = 5

## Where the prompt is drawn (its center), from the origin.
@export var prompt_offset: Vector2 = Vector2(0.0, -56.0)

## Whether it can be used now (a sold stand, an opened well cannot).
var enabled: bool = true:
	set(value):
		enabled = value
		_refresh_label()
## Text after the key in the prompt (already translated).
var prompt: String = "":
	set(value):
		prompt = value
		_refresh_label()
var focused: bool = false
var _label: Label = null


func _ready() -> void:
	collision_layer = 0
	collision_mask = 0
	set_collision_layer_value(PhysicsLayers.PICKUPS, true)
	monitoring = false
	monitorable = true
	_label = Label.new()
	_label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.size = Vector2(PROMPT_WIDTH, PROMPT_FONT_SIZE * 2.0)
	_label.position = prompt_offset - _label.size / 2.0
	_label.add_theme_font_size_override(&"font_size", PROMPT_FONT_SIZE)
	_label.add_theme_color_override(&"font_outline_color", Palette.VOID)
	_label.add_theme_constant_override(&"outline_size", PROMPT_OUTLINE)
	_label.z_index = 10
	add_child(_label)
	_refresh_label()


## The player's focus (only the closest interactable has it).
func set_focused(value: bool) -> void:
	focused = value
	_refresh_label()


## The player used it.
func interact(player: Player) -> void:
	if enabled:
		interacted.emit(player)


## Text the prompt shows now ("" while hidden).
func get_prompt_text() -> String:
	if _label == null or not _label.visible:
		return ""
	return _label.text


func _refresh_label() -> void:
	if _label == null:
		return
	_label.visible = focused and enabled
	var key: String = InputHints.key_name(ACTION)
	_label.text = "[%s] %s" % [key, prompt] if not prompt.is_empty() else "[%s]" % key
