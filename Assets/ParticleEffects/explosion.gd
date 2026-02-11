@tool
extends Node3D

func explode():
	$Sparks.emitting = true;
	$Flame.emitting = true;
	$Smoke.emitting = true;
	await get_tree().create_timer(2.0).timeout
	queue_free()
