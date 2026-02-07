@tool
extends Node3D
class_name Tank

@export var fieldOfView : float
@export var maxSpeed : float
@export var currentTerrain : TankTerrain

@export var hasPlayerView : bool = true
@export var shouldHideWhenNotView : bool = false : set = toggleHider # toggle to false when firing on player
@export var lookAt : Node3D

@export var traverseSpeed : float = PI*2.0/12.0 ## Radians per second
@export var turretLerpFactor : float = 0.1
#var selfAzimuth : float = 0.0

const occlusive : ShaderMaterial = preload("res://VisibilityHighlighter/VisibilityReciever/ShowFov.tres")
const camouflage : ShaderMaterial = preload("res://Units/BaseTank/camoflage.tres")

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
			mesher.material_override = camouflage
	shouldHideWhenNotView = newStatus

func _ready() -> void:
	if not hasPlayerView :
		$Driver/Base/Turret/Viewer.remove_from_group("Viewers")
	else :
		$Driver/Base/Turret/Viewer.add_to_group("Viewers")
	toggleHider(shouldHideWhenNotView)

func _process(delta: float) -> void:
	if not lookAt :
		return
	var relativePos : Vector3 = (lookAt.global_position - $Driver/Base/Turret.global_position)
	
	var goalRadians : float = (atan2(relativePos.x,relativePos.z)) + PI/2.0
	var selfRadians : float = $Driver/Base/Turret.rotation.y
	var diffRadians : float = angle_difference(selfRadians,goalRadians)
	
	var diffSign : float = sign(diffRadians)
	var difference = abs(diffRadians)
	if difference > traverseSpeed * delta :
		$Driver/Base/Turret.rotation.y += diffSign * traverseSpeed * delta
	else :
		#$Driver/Base/Turret.rotation.y += diffSign * (difference/2.0) * delta
		$Driver/Base/Turret.rotation.y = goalRadians

func fire() -> void :
	$Driver/Base/Turret/muzzleFlash.muzzleFlash()
