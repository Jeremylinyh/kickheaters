@tool
extends Node3D

func explode():
	$Sparks.emitting = true;
	$Flame.emitting = true;
	$Smoke.emitting = true;
	$ExplosionSound.play()
	await get_tree().create_timer(8.0).timeout
	queue_free()
