class_name TransformationData
extends Resource
## A transformation by tag (docs/07-items.md#sinergias-por-etiqueta-tipo-isaac):
## owning `required` observables with `tag` grants its effects once, like the
## transformations of Isaac. Name and description: TRANSFORMATION_<ID>_NAME/_DESC.

const NAME_KEY_FORMAT: String = "TRANSFORMATION_%s_NAME"
const DESCRIPTION_KEY_FORMAT: String = "TRANSFORMATION_%s_DESC"

@export var id: StringName = &""
@export var tag: StringName = &""
@export_range(1, 10) var required: int = 3
@export var icon: Texture2D = null
@export var effects: Array[ItemEffect] = []


func get_name_key() -> String:
	return NAME_KEY_FORMAT % String(id).to_upper()


func get_description_key() -> String:
	return DESCRIPTION_KEY_FORMAT % String(id).to_upper()
