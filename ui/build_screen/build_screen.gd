class_name BuildScreen
extends CanvasLayer
## Build screen (docs/11-ui.md#pantalla-de-build-tab--pausa): every statistic
## with its breakdown (base + the modifiers of each source), the observables,
## the operator and the transformations with their descriptions, and the seed
## with a copy button. It shows while show_build (Tab / Select) is held and
## while the game is paused (set_pinned()). It is rebuilt when it appears and
## when the build or the stats change while it is shown, never every frame.

const SHOW_ACTION: StringName = &"show_build"
## Translation key of each stat name: STAT_ + the stat id in capitals.
const STAT_KEY_PREFIX: String = "STAT_"
## Name keys tried for a modifier source, in order.
const SOURCE_KEY_FORMATS: Array[String] = [
	ItemData.NAME_KEY_FORMAT, TransformationData.NAME_KEY_FORMAT, "SOURCE_%s"
]
const NAME_FONT_SIZE: int = 16
const VALUE_FONT_SIZE: int = 18
const DETAIL_FONT_SIZE: int = 13
const ICON_SIZE: float = 36.0
## Width of the breakdown column (it wraps).
const BREAKDOWN_WIDTH: float = 250.0

var run: RunState = null
var _pinned: bool = false
var _dirty: bool = true

@onready var _stats_grid: GridContainer = %StatsGrid
@onready var _items_list: VBoxContainer = %ItemsList
@onready var _seed_label: Label = %SeedLabel
@onready var _copy_seed_button: Button = %CopySeedButton


## Formats a stat value for display.
static func format_stat(stat: StringName, value: float) -> String:
	match stat:
		Stats.MAX_JUMPS:
			return str(roundi(value))
		Stats.LUCK:
			return "%.0f" % value
		Stats.DEFENSE:
			return "%.0f %%" % (value * 100.0)
		Stats.SIZE, Stats.ATTACK_RATE:
			return "%.2f" % value
		_:
			return "%.0f" % value


## Visible name of a modifier source (an item, a transformation, a rest…).
static func source_name(source: StringName) -> String:
	for key_format: String in SOURCE_KEY_FORMATS:
		var key: String = key_format % String(source).to_upper()
		var translated: String = TranslationServer.translate(key)
		if translated != key:
			return translated
	return String(source)


## "base 300 · +40 Momento lineal · ×1.05 Constante de Planck"
static func breakdown_text(stats: Stats, stat: StringName) -> String:
	var parts: PackedStringArray = [
		"%s %s" % [TranslationServer.translate("BUILD_BASE"), _number(stats.get_base(stat))]
	]
	for modifier: StatModifier in stats.get_modifiers(stat):
		var amount: String
		if modifier.type == StatModifier.Type.ADD:
			amount = ("+" if modifier.value >= 0.0 else "") + _number(modifier.value)
		else:
			amount = "×" + _number(1.0 + modifier.value)
		parts.append("%s %s" % [amount, source_name(modifier.source)])
	return " · ".join(parts)


static func _number(value: float) -> String:
	var text: String = "%.2f" % value
	return text.rstrip("0").rstrip(".")


func _ready() -> void:
	visible = false
	_copy_seed_button.pressed.connect(_on_copy_seed_button_pressed)


func _process(_delta: float) -> void:
	var wanted: bool = _pinned or Input.is_action_pressed(SHOW_ACTION)
	if wanted and (_dirty or not visible):
		refresh()
	visible = wanted


func bind_run(new_run: RunState) -> void:
	if run != null:
		run.stats.stat_changed.disconnect(_on_changed)
		run.build.items_changed.disconnect(_on_build_changed)
		run.build.active_charge_changed.disconnect(_on_charge_changed)
	run = new_run
	run.stats.stat_changed.connect(_on_changed)
	run.build.items_changed.connect(_on_build_changed)
	run.build.active_charge_changed.connect(_on_charge_changed)
	_dirty = true


## Shows it until unpinned (the pause menu pins it).
func set_pinned(value: bool) -> void:
	_pinned = value
	if value:
		refresh()
		visible = true


## Rebuilds the stats and the items lists from the run.
func refresh() -> void:
	_dirty = false
	for child: Node in _stats_grid.get_children() + _items_list.get_children():
		# Freed at once (not queued): the rows are rebuilt right away
		child.free()
	if run == null:
		return
	_seed_label.text = run.get_seed_label()
	for stat: StringName in Stats.ALL:
		_stats_grid.add_child(
			_label(tr(STAT_KEY_PREFIX + String(stat).to_upper()), NAME_FONT_SIZE, Palette.INK)
		)
		_stats_grid.add_child(
			_label(format_stat(stat, run.stats.get_value(stat)), VALUE_FONT_SIZE, Palette.PLAYER)
		)
		var breakdown: Label = _label(
			breakdown_text(run.stats, stat), DETAIL_FONT_SIZE, Palette.INK_DIM
		)
		breakdown.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		breakdown.custom_minimum_size.x = BREAKDOWN_WIDTH
		_stats_grid.add_child(breakdown)
	var build: Build = run.build
	if build.active_item != null:
		var charge: String = tr("BUILD_CHARGE") % [build.active_charge, build.get_max_charge()]
		_add_item_row(
			build.active_item.icon,
			build.active_item.rarity,
			"%s · %s" % [tr(build.active_item.get_name_key()), charge],
			tr(build.active_item.get_description_key())
		)
	for transformation: TransformationData in build.transformations:
		_add_item_row(
			transformation.icon,
			-1,
			tr(transformation.get_name_key()),
			tr(transformation.get_description_key())
		)
	for item: ItemData in build.passive_items:
		_add_item_row(
			item.icon, item.rarity, tr(item.get_name_key()), tr(item.get_description_key())
		)
	if build.active_item == null and build.passive_items.is_empty():
		_items_list.add_child(_label(tr("BUILD_NO_ITEMS"), DETAIL_FONT_SIZE, Palette.INK_DIM))


## Text of a stat's row: "name|value|breakdown" (for tests and debugging).
func get_stat_row(stat: StringName) -> PackedStringArray:
	var index: int = Stats.ALL.find(stat) * 3
	var cells: PackedStringArray = []
	for offset: int in 3:
		var label: Label = _stats_grid.get_child(index + offset) as Label
		cells.append(label.text if label != null else "")
	return cells


func get_item_count() -> int:
	return _items_list.get_child_count()


func _add_item_row(icon: Texture2D, rarity: int, title: String, description: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 10)
	var icon_rect := ItemIconRect.new()
	icon_rect.icon_size = ICON_SIZE
	icon_rect.set_icon(icon, rarity)
	row.add_child(icon_rect)
	var texts := VBoxContainer.new()
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var color: Color = (
		ItemRarity.get_color(rarity as ItemData.Rarity) if rarity >= 0 else Palette.PLAYER
	)
	texts.add_child(_label(title, NAME_FONT_SIZE, color))
	var detail: Label = _label(description, DETAIL_FONT_SIZE, Palette.INK_DIM)
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	texts.add_child(detail)
	row.add_child(texts)
	_items_list.add_child(row)


func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	label.add_theme_font_size_override(&"font_size", font_size)
	label.add_theme_color_override(&"font_color", color)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return label


func _on_changed(_stat: StringName, _value: float) -> void:
	_mark_dirty()


func _on_build_changed() -> void:
	_mark_dirty()


func _on_charge_changed(_charge: int, _max_charge: int) -> void:
	_mark_dirty()


func _mark_dirty() -> void:
	_dirty = true
	if visible:
		refresh()


func _on_copy_seed_button_pressed() -> void:
	if run != null:
		DisplayServer.clipboard_set(run.seed_code)
