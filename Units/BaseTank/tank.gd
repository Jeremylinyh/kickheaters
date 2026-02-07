@tool
extends Node3D
class_name Tank

@export var fieldOfView : float
@export var maxSpeed : float
@export var currentTerrain : TankTerrain

@export var hasPlayerView : bool = true
@export var shouldHideWhenNotView : bool = false : set = toggleHider # toggle to false when firing on player
@export var lookAt : Node3D

const occlusive : ShaderMaterial = preload("res://VisibilityHighlighter/VisibilityReciever/ShowFov.tres")

func toggleHider(newStatus) :
	#print(newStatus)
	if newStatus :
		var allChilds : Array[Node] = self.find_children("*","MeshInstance3D",true)
		for mesher : MeshInstance3D in allChilds :
			#print(mesher)
			mesher.material_override = occlusive
	else :
		var allChilds : Array[Node] = self.find_children("*","MeshInstance3D",true)
		for mesher : MeshInstance3D in allChilds :
			#print(mesher)
			mesher.material_override = null
	shouldHideWhenNotView = newStatus

func _ready() -> void:
	if not hasPlayerView :
		$Driver/Base/Turret/Viewer.remove_from_group("Viewers")
	else :
		$Driver/Base/Turret/Viewer.add_to_group("Viewers")
	toggleHider(shouldHideWhenNotView)

func _process(_delta: float) -> void:
	if not lookAt :
		return
	var relativePos : Vector3 = (lookAt.global_position - $Driver/Base/Turret.global_position)
	$Driver/Base/Turret.rotation.y = (atan2(relativePos.x,relativePos.z)) + PI/2.0

func fire() -> void :
	$Driver/Base/Turret/muzzleFlash.muzzleFlash()
