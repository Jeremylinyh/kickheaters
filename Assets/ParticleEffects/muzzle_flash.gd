@tool
extends Node3D

func muzzleFlash():
	$Flame.emitting = true;
	$Smoke.emitting = true;
	$ExplosionSound.play()
	await get_tree().create_timer(4.0).timeout
	$Flame.emitting = false;
	$Smoke.emitting = false;
