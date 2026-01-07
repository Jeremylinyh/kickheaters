extends Node3D
@export var terrainViewer : PackedScene

const tilesNeededEachDir : int = 32
const tileSize : float = 128.0;

func _ready() -> void:
	for x in range(tilesNeededEachDir) :
		for y in range(tilesNeededEachDir) :
			var newTerrain : MeshInstance3D = terrainViewer.instantiate()
			self.add_child(newTerrain)
			newTerrain.position = Vector3(x * tileSize,0,y*tileSize)
