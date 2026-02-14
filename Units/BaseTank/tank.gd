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
		var allChilds : Array[Node] = $Driver.find_children("*","MeshInstance3D",true)
		for mesher : MeshInstance3D in allChilds :
			#print(mesher)
			mesher.material_override = occlusive
	else :
		var allChilds : Array[Node] = $Driver.find_children("*","MeshInstance3D",true)
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
	var turret : Node3D = $Driver/Base/Turret
	var gunPivot : Node3D = $Driver/Base/Turret/GunPivot
	
	var relativePos : Vector3 = turret.get_parent().to_local(lookAt.global_position)
	
	var goalRadians : float = (atan2(relativePos.x,relativePos.z)) + PI/2.0
	var selfRadians : float = turret.rotation.y
	var diffRadians : float = angle_difference(selfRadians,goalRadians)
	
	var diffSign : float = sign(diffRadians)
	var difference = abs(diffRadians)
	if difference > traverseSpeed * delta :
		turret.rotation.y += diffSign * traverseSpeed * delta
	else :
		turret.rotation.y = goalRadians
		
	
	relativePos -= gunPivot.position
	
	goalRadians = (atan2(Vector2(relativePos.x,relativePos.z).length(),relativePos.y)) + PI/2.0
	selfRadians = gunPivot.rotation.z
	diffRadians = angle_difference(selfRadians,goalRadians)
	
	diffSign = sign(diffRadians)
	difference = abs(diffRadians)
	
	gunPivot.rotation.z = goalRadians
	
	# Visualization logic
	var origin : Vector3 = gunPivot.global_position
	var direction : Vector3 = -gunPivot.global_basis.x.normalized()
	var shellDistance : float = currentTerrain.traceRay(origin,direction * maxRange)
	
	#print(shellDistance)
	
	#visualize
	$Trail.global_position = (origin + direction * (shellDistance/2))
	$Trail.look_at(origin)
	$Trail.mesh.size = Vector3(0.25,0.25,shellDistance)

#testing only
func periodicalyFire() -> void:
	while (is_inside_tree()) :
		await get_tree().create_timer(1.0).timeout
		fire()

func fire() -> void :
	if not currentTerrain or not lookAt or not is_inside_tree():
		return
	
	var muzzleFlash = $Driver/Base/Turret/GunPivot/Tube/muzzleFlash.duplicate()
	$Driver/Base/Turret/GunPivot/Tube.add_child(muzzleFlash)
	muzzleFlash.muzzleFlash()
	
	var gunPivot := $Driver/Base/Turret/GunPivot
	
	var origin : Vector3 = gunPivot.global_position
	var direction : Vector3 = -gunPivot.global_basis.x.normalized()
	var shellDistance : float = currentTerrain.traceRay(origin,direction * maxRange)
	
	#print(shellDistance)
	
	var shellInstance = shellExplosion.instantiate()
	$"..".add_child(shellInstance)
	shellInstance.global_position = origin + direction * shellDistance
	shellInstance.explode()
