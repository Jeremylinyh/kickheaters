@tool

extends Node3D
@export var terrainViewer : PackedScene
var heightmapImage : Texture2D
var tilesNeededEachDir : int = 6
const tileSize : float = 128.0;

func _ready() -> void:
	heightmapImage = await $ComputeSimplex.generate_noise_texture(4096,4096)
	$BakeHorizonMap._initialize_gpu()
	$BakeHorizonMap._update_input_texture(heightmapImage.get_image())
	$GetHorizons.heightmapImage = heightmapImage.get_image()
	
	if Engine.is_editor_hint() :
		tilesNeededEachDir = 32
	RenderingServer.global_shader_parameter_set("heightMap", heightmapImage)
	
	for x in range(tilesNeededEachDir) :
		for y in range(tilesNeededEachDir) :
			var newTerrain : MeshInstance3D = terrainViewer.instantiate()
			self.add_child(newTerrain)
			newTerrain.position = Vector3((x-3) * tileSize,0,(y+1-3)*tileSize)
			newTerrain.name = str(x) + "," + str(y)
			newTerrain.owner = null

func _process(delta: float) -> void:
	if Engine.is_editor_hint() :
		return
	if not get_viewport().get_camera_3d():
		return
	var current_camera3d : Vector3 = get_viewport().get_camera_3d().global_position
	var offset : float = 0.0 #tilesNeededEachDir * tileSize/2.0
	var griddedPosition : Vector2 = Vector2(current_camera3d.x,current_camera3d.z)
	const gridSize : float = 1.0
	griddedPosition = griddedPosition.round()
	griddedPosition -= Vector2(offset,offset)
	global_position = Vector3(griddedPosition.x,0,griddedPosition.y)
