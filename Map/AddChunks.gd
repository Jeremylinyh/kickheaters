@tool

extends Node3D
@export var terrainViewer : PackedScene

const tilesNeededEachDir : int = 32
const tileSize : float = 128.0;
var leadMaterial : ShaderMaterial

func _ready() -> void:
	for x in range(tilesNeededEachDir) :
		for y in range(tilesNeededEachDir) :
			var newTerrain : MeshInstance3D = terrainViewer.instantiate()
			self.add_child(newTerrain)
			newTerrain.position = Vector3((x) * tileSize,0,(y+1)*tileSize)
			newTerrain.name = str(x) + "," + str(y)
			newTerrain.owner = null
			
			newTerrain.set_layer_mask_value(2, true)
			
			leadMaterial = newTerrain.mesh.material

func _process(_delta: float) -> void:
	var counter : int = 0
	for depthCharge in get_tree().get_nodes_in_group("CustomLights") :
		if not depthCharge.depth_tex :
			continue
		#print(leadMaterial)
		leadMaterial.set_shader_parameter("depthTexture" + str(counter),depthCharge.depth_tex)
		counter += 1
