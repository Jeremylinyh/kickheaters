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
@export var turretElevateSpeed : float = 1.0

const maxRange : float = 1024.0

#var selfAzimuth : float = 0.0

const shellExplosion := preload("res://Assets/ParticleEffects/explosion.tscn")
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
	
	periodicalyFire()

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
		
	goalRadians = (atan2(relativePos.x,relativePos.y)) + PI/2.0
	selfRadians = $Driver/Base/Turret.rotation.z
	diffRadians = angle_difference(selfRadians,goalRadians)
	
	var gunPivot : Node3D = $Driver/Base/Turret/Turret/GunPivot
	
	if difference > turretElevateSpeed * delta :
		gunPivot.rotation.z -= diffSign * turretElevateSpeed * delta
	else :
		#$Driver/Base/Turret.rotation.y += diffSign * (difference/2.0) * delta
		gunPivot.rotation.z = -goalRadians

#testing only
func periodicalyFire() -> void:
	while (is_inside_tree()) :
		await get_tree().create_timer(1.0).timeout
		fire()

func fire() -> void :
	if not currentTerrain or not lookAt or not is_inside_tree():
		return
	
	var muzzleFlash = $Driver/Base/Turret/Turret/GunPivot/Tube/muzzleFlash.duplicate()
	$Driver/Base/Turret/Turret/GunPivot/Tube.add_child(muzzleFlash)
	muzzleFlash.muzzleFlash()
	
	var gunPivot := $Driver/Base/Turret/Turret/GunPivot
	
	var origin : Vector3 = gunPivot.global_position
	var direction : Vector3 = -gunPivot.global_basis.x
	var shellDistance : float = currentTerrain.traceRay(origin,direction * maxRange)
	
	print(shellDistance)
	
	var shellInstance = shellExplosion.instantiate()
	$"..".add_child(shellInstance)
	shellInstance.global_position = origin + direction * shellDistance
	shellInstance.explode()
