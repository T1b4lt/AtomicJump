class_name ScreenStatusEffect
extends ItemEffect
## Operators that act on everything on screen: apply a status effect to every
## enemy (Efecto Zenón freezes them) and, optionally, destroy the enemy
## projectiles (Colapso).

@export var status: StatusEffectData = null
@export var destroy_enemy_projectiles: bool = false


func activate(build: Build) -> bool:
	if build.player == null or not build.player.is_inside_tree():
		return false
	var view: Rect2 = build.get_view_rect()
	var tree: SceneTree = build.player.get_tree()
	if status != null:
		for node: Node in tree.get_nodes_in_group(Enemy.GROUP):
			var enemy: Enemy = node as Enemy
			if enemy != null and not enemy.is_dying() and view.has_point(enemy.global_position):
				enemy.statuses.apply(status)
	if destroy_enemy_projectiles:
		for node: Node in tree.get_nodes_in_group(Projectile.ENEMY_GROUP):
			var projectile: Projectile = node as Projectile
			if projectile != null and view.has_point(projectile.global_position):
				projectile.destroy()
	return true
