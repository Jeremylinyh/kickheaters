@tool
extends Node3D
var currentPosition : Transform3D = Transform3D()

var positionPrevFrame : Transform3D = currentPosition

func _ready():
	pass#$PointOfView.world_3d = get_viewport().find_world_3d()
	

func _process(_delta: float) -> void:
	currentPosition = global_transform
	$PointOfView/Camera3D.global_transform = currentPosition
	if positionPrevFrame != currentPosition :
		#print(self.name+" moved")
		positionPrevFrame = currentPosition
		$PointOfView.render_target_update_mode = $PointOfView.UPDATE_DISABLED
		$PointOfView.render_target_update_mode = $PointOfView.UPDATE_ONCE
