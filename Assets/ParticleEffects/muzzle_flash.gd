@tool
extends Node3D

func muzzleFlash():
	$Flame.restart()
	$Smoke.restart()
	#var wasPrevEmitting = $Flame.emitting
	#$Flame.emitting = false;
	#$Smoke.emitting = false;
	#await  get_tree().process_frame
	$Flame.emitting = true;
	$Smoke.emitting = true;
	#if not wasPrevEmitting :
	await get_tree().create_timer(4.0).timeout
	queue_free()
	#$Flame.emitting = false;
	#$Smoke.emitting = false;
