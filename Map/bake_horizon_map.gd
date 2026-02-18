@tool
class_name HorizonComputer
extends Node

# --- Public Settings ---
@export var shader_file: RDShaderFile
@export var output_size := Vector2i(4096, 1024)
@export var layer_count := 4 # How many slices in your array

# --- Private Internals ---
var _rd: RenderingDevice
var _pipeline: RID
var _shader: RID
var _output_tex_rid: RID
var _params_buffer: RID
var _texture_wrapper: Texture2DArrayRD # Changed to Array wrapper
var _cached_input_rid: RID
var _initialized := false

func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		_cleanup_gpu()

# Added 'index' parameter
func run_compute(input_img : Image,settings: Dictionary, target_global: String, index: int,distance : float) -> void:
	if not _initialized:
		_initialize_gpu()
		_update_input_texture(input_img)

	# 1. Update Inputs (Now includes index)
	_update_params(
		settings.get("origin", Vector2.ZERO), 
		settings.get("scale", 10.0), 
		settings.get("stride", 1.0),
		index,
		distance
	)
	#_update_input_texture(input_img)

	# 2. Assign the Array Texture to Global Uniform
	RenderingServer.global_shader_parameter_set(target_global, _texture_wrapper)

	# 3. Run
	_dispatch()

func _initialize_gpu():
	if _initialized :
		return
	_rd = RenderingServer.get_rendering_device()
	
	var spirv = shader_file.get_spirv()
	_shader = _rd.shader_create_from_spirv(spirv)
	_pipeline = _rd.compute_pipeline_create(_shader)
	
	# Create Output Texture Array
	var fmt = RDTextureFormat.new()
	fmt.width = output_size.x
	fmt.height = output_size.y
	fmt.texture_type = RenderingDevice.TEXTURE_TYPE_2D_ARRAY # Set type to Array
	fmt.array_layers = layer_count # Set number of layers
	fmt.format = RenderingDevice.DATA_FORMAT_R16G16_SFLOAT
	fmt.usage_bits = RenderingDevice.TEXTURE_USAGE_STORAGE_BIT | RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT | RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT | RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT
	
	_output_tex_rid = _rd.texture_create(fmt, RDTextureView.new())
	
	# Create Wrapper for 2D Array
	_texture_wrapper = Texture2DArrayRD.new()
	_texture_wrapper.texture_rd_rid = _output_tex_rid
	
	# Create Param Buffer (Increased to 32 bytes to hold the int index)
	_params_buffer = _rd.storage_buffer_create(32)
	
	_initialized = true

func _update_params(origin: Vector2, h_scale: float, stride: float, index: int,distance : float):
	var data = PackedByteArray()
	data.resize(32)
	data.encode_float(0, origin.x)
	data.encode_float(4, origin.y)
	data.encode_float(8, float(output_size.x))
	data.encode_float(12, float(output_size.y))
	data.encode_float(16, h_scale)
	data.encode_float(20, stride)
	data.encode_s32(24, index)
	data.encode_float(28, distance) # distance
	_rd.buffer_update(_params_buffer, 0, 32, data)

func _update_input_texture(img: Image):
	if _cached_input_rid.is_valid():
		_rd.free_rid(_cached_input_rid)
	if not img :
		return
	img.convert(Image.FORMAT_RF)
	var fmt = RDTextureFormat.new()
	fmt.width = img.get_width()
	fmt.height = img.get_height()
	fmt.format = RenderingDevice.DATA_FORMAT_R32_SFLOAT
	fmt.usage_bits = RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT | RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT | RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT
	_cached_input_rid = _rd.texture_create(fmt, RDTextureView.new(), [img.get_data()])

func _dispatch():
	if not _cached_input_rid :
		return
	
	var u_param = RDUniform.new()
	u_param.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	u_param.binding = 0
	u_param.add_id(_params_buffer)
	
	var u_in = RDUniform.new()
	u_in.uniform_type = RenderingDevice.UNIFORM_TYPE_SAMPLER_WITH_TEXTURE
	u_in.binding = 1
	var sampler = _rd.sampler_create(RDSamplerState.new())
	u_in.add_id(sampler)
	u_in.add_id(_cached_input_rid)
	
	var u_out = RDUniform.new()
	u_out.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	u_out.binding = 2
	u_out.add_id(_output_tex_rid)
	
	var setUni = _rd.uniform_set_create([u_param, u_in, u_out], _shader, 0)
	
	var list = _rd.compute_list_begin()
	_rd.compute_list_bind_compute_pipeline(list, _pipeline)
	_rd.compute_list_bind_uniform_set(list, setUni, 0)
	_rd.compute_list_dispatch(list, int(ceil(output_size.x / 64.0)), 1, 1)
	_rd.compute_list_end()
	
	_rd.free_rid(setUni)
	_rd.free_rid(sampler)

func _cleanup_gpu():
	if _rd:
		if _output_tex_rid.is_valid(): _rd.free_rid(_output_tex_rid)
		if _params_buffer.is_valid(): _rd.free_rid(_params_buffer)
		if _pipeline.is_valid(): _rd.free_rid(_pipeline)
		if _shader.is_valid(): _rd.free_rid(_shader)
		if _cached_input_rid.is_valid(): _rd.free_rid(_cached_input_rid)
