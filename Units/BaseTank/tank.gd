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
const ray_length : float = 4096.0
const maxStepSize : int = 1

var selected = false :
	set(value):
		selected = value
		if value :
			dragTank()

#var selfAzimuth : float = 0.0

const shellExplosion := preload("res://Assets/ParticleEffects/explosion.tscn")
const occlusive : ShaderMaterial = preload("res://VisibilityHighlighter/VisibilityReciever/ShowFov.tres")
const camouflage : ShaderMaterial = preload("res://Units/BaseTank/camoflage.tres")

var queuedWaypoints : Array[Vector3] = [] : 
	set(value) :
		$Waypoints.updateMesh(preTransformPosition,value)
		#print(value.size())
		queuedWaypoints = value

@onready var preTransformPosition : Vector3 = self.global_position

func dragTank() -> void:
	var camera : Camera3D = get_viewport().get_camera_3d()
	# print(camera)
	if not camera or not self :
		return
	self.queuedWaypoints = []
	#get_viewport().debug_draw = Viewport.DEBUG_DRAW_WIREFRAME
	preTransformPosition = self.global_position
	while selected :
		if Input.is_action_just_released("Click") :
			if Input.is_action_pressed("shift") :
				continue
			else :
				break
		var mouse_pos = get_viewport().get_mouse_position()
		var from = camera.project_ray_origin(mouse_pos)
		var to = camera.project_ray_normal(mouse_pos).normalized()
		
		var terrDist : float = currentTerrain.traceRay(from,to * ray_length)
		#print(terrDist)
		var proposedWaypoint : Vector3 = from + (to * terrDist)
		
		if self.queuedWaypoints.size() > 0 :
			var prevWaypoint : Vector3 = self.queuedWaypoints.back()
			var vecToProposed : Vector3 = proposedWaypoint - prevWaypoint
			var distToProposed : float = (vecToProposed).length()
			
			var vecToBeAdd : Vector3 = vecToProposed.normalized()
			
			# const minStepSize : int = 1
			for i in range(1,floor(distToProposed/maxStepSize) + 1,1) :
				self.queuedWaypoints.append(prevWaypoint + vecToBeAdd * i * maxStepSize)
				# I am aware this is not raycasted
				# TODO: Fix that if able.
			
			prevWaypoint = self.queuedWaypoints.back()
			#for i in range(minStepSize,int(distToProposed) % maxStepSize + minStepSize,minStepSize) :
				#self.queuedWaypoints.append(prevWaypoint + vecToBeAdd * i * minStepSize)
			#if int(ceil(distToProposed)) % maxStepSize > 0 && distToProposed > minStepSize :
				#self.queuedWaypoints.append(proposedWaypoint)
		else :
			self.queuedWaypoints.append(proposedWaypoint)
		
		$Waypoints.updateMesh(preTransformPosition,queuedWaypoints)
		global_position = proposedWaypoint
		var sceneRoot : SceneRoot = get_tree().current_scene
		sceneRoot.setTankTimeNow(queuedWaypoints.size() * maxStepSize + (queuedWaypoints.back() - proposedWaypoint).length())
		
		await get_tree().process_frame
	global_position = preTransformPosition
	var sceneRoot : SceneRoot = get_tree().current_scene
	sceneRoot.setTankTimeNow(0.0)
	
	#selected = false
	#print("path ends")

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
	if not self or not get_tree() :
		return
	if not hasPlayerView :
		$Driver/Base/Turret/Viewer.remove_from_group("Viewers")
	else :
		$Driver/Base/Turret/Viewer.add_to_group("Viewers")
	toggleHider(shouldHideWhenNotView)
	var sceneRoot : SceneRoot = get_tree().current_scene
	if sceneRoot :
		sceneRoot.simulationTimeChanged.connect(Callable(self,"_on_simulation_time_changed"))
	periodicalyFire()

func _process(delta: float) -> void:
	if not lookAt or lookAt.position.length() < 0.01:
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
	if shellDistance/2.0 <= 1.0 :
		return
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

func _on_simulation_time_changed(newTime: float) -> void:
	if shouldHideWhenNotView :
		if newTime <= 0.01 :
			visible = false
		else :
			visible = true
		return
	
	if selected :
		return
	
	if newTime <= 0.01 :
		self.global_position = preTransformPosition
		return
	if queuedWaypoints.size() <= 0 :
		return
	
	var low : int = clamp(floor(newTime),0,max(queuedWaypoints.size() - 1,0))
	var high : int = clamp(ceil(newTime),0,max(queuedWaypoints.size() - 1,0))
	var fract : float = newTime - low
	
	var predictedPosition : Vector3 = lerp(queuedWaypoints[low],queuedWaypoints[high],fract)
	self.global_position = predictedPosition
	if queuedWaypoints.size() <= 1 :
		return
	var lookatPosition = queuedWaypoints[high]
	if fract >= queuedWaypoints.size() - 1:
		# the last
		var relativeForward : Vector3 = (queuedWaypoints[low] - queuedWaypoints[high])
		lookatPosition = predictedPosition + relativeForward
	if (lookatPosition - predictedPosition).length() <= 0.01 :
		return
	self.look_at(lookatPosition)
