@tool
extends Node3D

func muzzleFlash():
	$Flame.emitting = false;
	$Smoke.emitting = false;
	#var wasPrevEmitting = $Flame.emitting
	$Flame.emitting = true;
	$Smoke.emitting = true;
	#if not wasPrevEmitting :
		#await get_tree().create_timer(4.0).timeout
		#$Flame.emitting = false;
		#$Smoke.emitting = false;
