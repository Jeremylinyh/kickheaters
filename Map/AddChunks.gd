@tool

extends Node3D
@export var terrainViewer : PackedScene
@export var heightmapImage : Texture2D
var tilesNeededEachDir : int = 6
const tileSize : float = 128.0;

func _ready() -> void:
	if Engine.is_editor_hint() :
		tilesNeededEachDir = 32
	
	for x in range(tilesNeededEachDir) :
		for y in range(tilesNeededEachDir) :
			var newTerrain : MeshInstance3D = terrainViewer.instantiate()
			self.add_child(newTerrain)
			newTerrain.position = Vector3((x) * tileSize,0,(y+1)*tileSize)
			newTerrain.name = str(x) + "," + str(y)
			newTerrain.owner = null

func _process(delta: float) -> void:
	if Engine.is_editor_hint() :
		return
	var current_camera3d : Vector3 = get_viewport().get_camera_3d().global_position
	var offset : float = tilesNeededEachDir * tileSize/2.0
	var griddedPosition : Vector2 = Vector2(current_camera3d.x,current_camera3d.z)
	griddedPosition = griddedPosition.round()
	griddedPosition -= Vector2(offset,offset)
	position = Vector3(griddedPosition.x,0,griddedPosition.y)
