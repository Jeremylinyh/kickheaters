## Builds a line, used for things like path or tracers.
@tool
extends MeshInstance3D

func _ready() -> void:
	mesh.custom_aabb = AABB(Vector3(-10000, -10000, -10000), Vector3(20000, 20000, 20000))

func updateMesh(originGlobal : Vector3,waypoints : Array[Vector3]) -> void:
	print(waypoints.size())
	if waypoints.size() < 1:
		visible = false
		return
	visible = true
	
	var vertices = PackedVector3Array()
	var nextVertices = PackedVector4Array()
	var uvs = PackedVector2Array()
	
	vertices.push_back(originGlobal)
	vertices.push_back(originGlobal)
	uvs.push_back(Vector2(0, 1.0))
	uvs.push_back(Vector2(0, -1.0))
	for pos : Vector3 in waypoints :
		vertices.push_back(pos)
		vertices.push_back(pos)
		nextVertices.push_back(Vector4(pos.x,pos.y,pos.z,1.0))
		nextVertices.push_back(Vector4(pos.x,pos.y,pos.z,1.0))
		uvs.push_back(Vector2(1, 1.0))
		uvs.push_back(Vector2(1, -1.0))
	
	var finalDelta : Vector3 = waypoints[waypoints.size()-1]
	var prevFinalDelta : Vector3 = originGlobal
	if waypoints.size() > 1:
		prevFinalDelta = waypoints[waypoints.size()-2]
	var projectedPos : Vector3 = finalDelta + (finalDelta - prevFinalDelta)
	nextVertices.push_back(Vector4(projectedPos.x,projectedPos.y,projectedPos.z,1.0))
	nextVertices.push_back(Vector4(projectedPos.x,projectedPos.y,projectedPos.z,1.0))
	
	var surface_array = []
	surface_array.resize(Mesh.ARRAY_MAX)
	surface_array[Mesh.ARRAY_VERTEX] = vertices
	surface_array[Mesh.ARRAY_CUSTOM0] = nextVertices.to_byte_array().to_float32_array()
	surface_array[Mesh.ARRAY_TEX_UV] = uvs
	
	var format_flags = (Mesh.ARRAY_CUSTOM_RGBA_FLOAT << Mesh.ARRAY_FORMAT_CUSTOM0_SHIFT)
	
	var selfMesh : ArrayMesh = mesh
	selfMesh.clear_surfaces()
	#selfMesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLE_STRIP,surface_array)
	selfMesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLE_STRIP,surface_array, [], {}, format_flags)
	#mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLE_STRIP,surface_array)
