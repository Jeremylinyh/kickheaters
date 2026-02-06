extends Node3D


func muzzleFlash():
	$Flame.emitting = true;
	$Smoke.emitting = true;
	await get_tree().create_timer(4.0).timeout
	queue_free()
