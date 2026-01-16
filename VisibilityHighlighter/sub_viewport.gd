@tool
extends Node3D

var depth_tex : Texture2D
var currentPosition : Transform3D = Transform3D()
var positionPrevFrame : Transform3D = currentPosition

@onready var shadow_cam = $PointOfView/Camera3D

var view_matrix# = shadow_cam.get_global_transform().inverse()
var proj_matrix# = shadow_cam.get_camera_projection()
var full_shadow_matrix# = proj_matrix * view_matrix

func _ready():
	#if Engine.is_editor_hint() :
		#$PointOfView/Camera3D/Depth.visible = true#false
	#else :
		#$PointOfView/Camera3D/Depth.visible = true
	pass#$PointOfView.world_3d = get_viewport().find_world_3d()
	

func _process(_delta: float) -> void:
	currentPosition = global_transform
	$PointOfView/Camera3D.global_transform = currentPosition
	if positionPrevFrame != currentPosition :
		shadow_cam = $PointOfView/Camera3D
		view_matrix = shadow_cam.get_global_transform().inverse()
		proj_matrix = shadow_cam.get_camera_projection()
		full_shadow_matrix = proj_matrix * Projection(view_matrix)
		
		#print(self.name+" moved")
		positionPrevFrame = currentPosition
		#$PointOfView/Camera3D/Depth.visible = true
		$PointOfView.render_target_update_mode = $PointOfView.UPDATE_DISABLED
		$PointOfView.render_target_update_mode = $PointOfView.UPDATE_ONCE
		
		## Force the rendering server to draw the current frame
		#RenderingServer.frame_post_draw.connect(func(): pass) # Await the signal to ensure it draws
		#await RenderingServer.frame_post_draw
		
		depth_tex = $PointOfView.get_texture()
		#$PointOfView/Camera3D/Depth.visible = false
		#print(depth_tex)
