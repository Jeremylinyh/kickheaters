@tool

extends Node3D
@export var terrainViewer : PackedScene
@export var Heightmap: Texture2D

const tilesNeededEachDir : int = 32
const tileSize : float = 128.0;
@onready var heigtmapExample : StaticBody3D = $StaticBody3D

func setCollider(colliderPos : Vector3) :
	var heightmap := heigtmapExample.duplicate()
	heightmap.position = colliderPos
	var shape : CollisionShape3D = heigtmapExample.get_child(0)
	
	var map_data = PackedFloat32Array()
	map_data.resize(pow(tileSize,2.0)) 
	for x in range(tileSize):
		for y in range(tileSize):
			map_data.push_back(0.0)
			
	shape.shape.map_data = map_data
	return heightmap

func _ready() -> void:
	for x in range(tilesNeededEachDir) :
		for y in range(tilesNeededEachDir) :
			var newTerrain : MeshInstance3D = terrainViewer.instantiate()
			self.add_child(newTerrain)
			newTerrain.position = Vector3((x) * tileSize,0,(y+1)*tileSize)
			newTerrain.name = str(x) + "," + str(y)
			newTerrain.owner = null
			newTerrain.add_child(setCollider(newTerrain.position))
