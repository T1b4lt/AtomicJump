class_name CoinBurstEffect
extends ItemEffect
## Every `coins_per_burst` photons collected, the player fires a burst of
## projectiles in every direction (Efecto fotoeléctrico).

@export var coins_per_burst: int = 10
@export var projectiles: int = 8

## Photons collected towards the next burst.
var progress: int = 0


func coins_collected(build: Build, amount: int) -> void:
	progress += amount
	while progress >= coins_per_burst:
		progress -= coins_per_burst
		if build.player != null:
			build.player.shoot_burst(projectiles)
