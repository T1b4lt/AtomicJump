class_name ChunkSpawnEffect
extends ItemEffect
## A pickup appears next to the player every time it enters a new chunk
## (Energía del vacío).

## Chunk object id of what appears.
@export var object_id: StringName = &"heal_pickup"
## Where it appears, from the player.
@export var offset: Vector2 = Vector2(0.0, -48.0)


func chunk_entered(build: Build, _index: int) -> void:
	if build.player != null:
		build.spawn(object_id, build.player.global_position + offset)
