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
	
	# Keep your existing setup...
	var selfForward : Vector3 = global_transform.basis.x 
	var selfRight : Vector3 = global_transform.basis.z
	var selfPosition : Vector3 = global_position
	
	var selfPos : Vector2 = Vector2(selfPosition.x,selfPosition.z)
	var selfR : Vector2 = Vector2(selfRight.x,selfRight.z).normalized()
	var selfF : Vector2 = Vector2(selfForward.x,selfForward.z).normalized()
	var half_width = trackSpacing / 2.0
	
	# 1. USE ABSOLUTE HEIGHTS (Revert to just getHeightAt)
	var leftHeights : PackedFloat32Array = PackedFloat32Array()
	leftHeights.resize(3)
	for i in range(-1,2,1) : 
		var samplerPos : Vector2 = selfPos - selfR * half_width + selfF * i
		leftHeights[i+1] = currentTerrain.getHeightAt(samplerPos)
		
	var rightHeights : PackedFloat32Array = PackedFloat32Array()
	rightHeights.resize(3)
	for i in range(-1,2,1) :
		var samplerPos : Vector2 = selfPos + selfR * half_width + selfF * i
		rightHeights[i+1] = currentTerrain.getHeightAt(samplerPos)
	
	# 2. GET THE ALIGNMENT (This returns a transform facing North/-Z)
	var align_t = get_track_alignment_transform(leftHeights, rightHeights)
	
	# 3. APPLY YAW (Rotate the alignment to match where the tank is actually facing)
	# We extract the Y rotation (Yaw) from the tank's current global transform
	var current_yaw = Basis(Vector3.UP, global_rotation.y)
	align_t.basis = current_yaw * align_t.basis
	
	# 4. FIX POSITION (Apply Global X/Z)
	# The function gives us the correct Average Y height in .origin.y
	# We just need to overwrite X and Z with the tank's actual world position
	align_t.origin.x = selfPosition.x
	align_t.origin.z = selfPosition.z
	
	# 5. APPLY GLOBAL
	$"../Base".global_transform = align_t
	
func get_track_alignment_transform(
	left_heights: PackedFloat32Array, 
	right_heights: PackedFloat32Array, 
) -> Transform3D:
	
	# --- Configuration ---
	# We assume the 3 points are: Front, Mid, Back.
	# Godot standard: Forward is -Z, Right is +X, Up is +Y.
	var half_len = trackLength / 2.0
	var half_width = trackSpacing / 2.0

	# Z offsets for the 3 points (Front, Mid, Back)
	# Assuming the array is ordered [Front, Mid, Back]. 
	# If [Back, Mid, Front], flip the signs.
	var z_offsets = [-half_len, 0.0, half_len] 

	# --- 1. Construct 3D Points ---
	var left_points: Array[Vector3] = []
	var right_points: Array[Vector3] = []

	for i in range(3):
		# Left track is at -X, Right track is at +X
		left_points.append(Vector3(-half_width, left_heights[i], z_offsets[i]))
		right_points.append(Vector3(half_width, right_heights[i], z_offsets[i]))

	# --- 2. Calculate Average Position (Centroid) ---
	var sum_pos = Vector3.ZERO
	for p in left_points: sum_pos += p
	for p in right_points: sum_pos += p

	# This is the origin of our new Transform
	var origin = sum_pos / 6.0 

	# --- 3. Calculate Basis Vectors (The "Correction") ---

	# A. Forward Vector (Z axis)
	# Average the slope of the left track and the right track.
	# (Front - Back) gives a vector pointing Forward (negative Z in Godot).
	var left_fwd = left_points[0] - left_points[2]
	var right_fwd = right_points[0] - right_points[2]
	var forward_vector = (left_fwd + right_fwd).normalized()

	# B. Right Vector (X axis)
	# Vector from the average center of the left track to the average center of the right track.
	# We can approximate this by comparing corresponding points or track averages.
	var left_track_avg = (left_points[0] + left_points[1] + left_points[2]) / 3.0
	var right_track_avg = (right_points[0] + right_points[1] + right_points[2]) / 3.0
	var right_vector = (right_track_avg - left_track_avg).normalized()

	# --- 4. Cross Product for Normal (Y axis) ---
	# Cross product of Right and Forward gives Up (or Down depending on order).
	# In Godot (Right Hand Rule): Cross(Right, Forward) -> Up (if Forward is -Z)
	# But wait: Forward vector calculated above points -Z.
	# X (Right) cross -Z (Forward) = +Y (Up).
	var up_vector = right_vector.cross(forward_vector).normalized()

	# --- 5. Re-orthogonalize (Gram-Schmidt) ---
	# The terrain might warp such that Right and Forward aren't perfectly 90 degrees.
	# We usually prioritize the Up vector (to match terrain normal) and the Forward vector (heading).

	# Recalculate true Right to ensure the basis is orthogonal
	var true_right = forward_vector.cross(up_vector).normalized()

	# Construct the Basis
	# Godot Basis takes (x_axis, y_axis, z_axis)
	# Since our 'forward_vector' points towards -Z, the Z-axis of the basis (which points Back) is -forward_vector.
	var basis = Basis(true_right, up_vector, -forward_vector)

	# --- 6. Output Transform ---
	return Transform3D(basis, origin)
