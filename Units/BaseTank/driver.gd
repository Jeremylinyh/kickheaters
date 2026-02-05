@tool
extends Node3D

@export var trackSpacing : float = 1.6
@onready var currentTerrain = $"..".currentTerrain
@export var trackLength : float = 3.0

func _ready() -> void:
	# do not keep visuals in final product
	if not Engine.is_editor_hint() :
		var children = get_children()
		for child in children:
			child.queue_free()
	else :
		$Left.mesh.size = Vector3(trackLength,0.1,trackSpacing)

func _process(delta: float) -> void:
	currentTerrain = $"..".currentTerrain
	if Engine.is_editor_hint() :
		$Left.mesh.size = Vector3(trackLength,0.1,trackSpacing)
	if not currentTerrain :
		return
	
	var selfForward : Vector3 = global_transform.basis.x 
	var selfRight : Vector3 = global_transform.basis.z
	var selfPosition : Vector3 = global_position
	
	var selfPos : Vector2 = Vector2(selfPosition.x,selfPosition.z)
	var selfR : Vector2 = Vector2(selfRight.x,selfRight.z).normalized()
	var selfF : Vector2 = Vector2(selfForward.x,selfForward.z).normalized()
	var half_width = trackSpacing / 2.0
	
	var leftHeights : Array[Vector3] = []
	leftHeights.resize(3)
	for i in range(-1,2,1) : 
		var samplerPos : Vector2 = selfPos - selfR * half_width + selfF * i
		leftHeights[i+1] = Vector3(samplerPos.x,currentTerrain.getHeightBilinear(samplerPos),samplerPos.y)# + selfPosition
		
	var rightHeights : Array[Vector3] = []
	rightHeights.resize(3)
	for i in range(-1,2,1) :
		var samplerPos : Vector2 = selfPos + selfR * half_width + selfF * i
		rightHeights[i+1] = Vector3(samplerPos.x,currentTerrain.getHeightBilinear(samplerPos),samplerPos.y)# + selfPosition
	
	var avgPos : Vector3 = Vector3()
	var totalArr : Array[Vector3] = leftHeights
	totalArr.append_array(rightHeights)
	for pos : Vector3 in totalArr :
		avgPos += pos
	$"../Base".global_position = avgPos/6.0
