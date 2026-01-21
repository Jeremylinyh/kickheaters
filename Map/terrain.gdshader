shader_type spatial;
render_mode world_vertex_coords;
global uniform sampler2D heightMap;

uniform sampler2D DEPTH_TEXTURE : hint_depth_texture;

uniform sampler2D mapTexture;
const float maxHeight = 60.0;
const vec2 mapSize = vec2(4096.0,4096.0);
const float mapScale = 1.0;

#include "res://VisibilityHighlighter/visibleHorizon.gdshaderinc"

varying vec2 v_world_pos;
varying float heightSampled;

void vertex() {
	// Called for every vertex the material is visible on.
	v_world_pos = VERTEX.xz;

	vec2 effectivePosition = mapScale * (VERTEX.xz/mapSize);
	float height = texture(heightMap, effectivePosition).r;
	VERTEX.y = height * maxHeight;
	heightSampled = VERTEX.y;
}

vec3 getWorldPos(vec2 uvLight, mat4 invProj, mat4 invView)
{
    // 1. Get Screen UV (normalized 0-1) and Depth
    vec2 screen_uv = uvLight;
    float depth = texture(DEPTH_TEXTURE, screen_uv).r;

    // 2. Convert to Normalized Device Coordinates (NDC)
    vec2 xy_ndc = (screen_uv * 2.0) - 1.0;

    // IMPORTANT CHECK: Depth Range
    // OpenGL NDC Z is usually -1.0 to 1.0. The depth buffer is 0.0 to 1.0.
    // If you are using standard OpenGL, you must map depth to -1..1.
    // If you are using Vulkan or DX11 (or OpenGL with glClipControl), 0..1 is correct.
    float z_ndc = depth * 2.0 - 1.0; // Use this for standard OpenGL
    // float z_ndc = depth;          // Use this for Vulkan/DX

    vec4 ndc_pos = vec4(xy_ndc, z_ndc, 1.0);

    // 3. Reconstruct View Space Position
    vec4 view_pos_h = invProj * ndc_pos;

    // --- THE FIX: Perspective Division ---
    // You must divide by .w to convert from Homogeneous to Cartesian coords
    vec3 view_pos = view_pos_h.xyz / view_pos_h.w;

    // 4. Convert to World Space Position
    // We use vec4(view_pos, 1.0) because position vectors need w=1.0 for translation to work
    vec4 world_pos = invView * vec4(view_pos, 1.0);

    return world_pos.xyz;
}

void fragment() {
	// Called for every pixel the material is visible on.
	vec2 pixelPos = v_world_pos/mapSize;
	vec3 worldPos = getWorldPos(SCREEN_UV,INV_PROJECTION_MATRIX,INV_VIEW_MATRIX);
	ALBEDO = texture(mapTexture,pixelPos * mapScale).rgb * isUnderground(worldPos);
	//ALBEDO = worldPos;
	//ALBEDO = vec3(isUnderground(worldPos));
}

//void light() {
	//// Called for every pixel for every light affecting the material.
	//// Uncomment to replace the default light processing function with this one.
	//vec3 litColor = LIGHT_COLOR; //vec3(0.5);
	//bool shouldOverrideLight = length(DIFFUSE_LIGHT) <= 0.;
	//shouldOverrideLight = shouldOverrideLight || (litColor.x == litColor.y); // or if self is white
	//shouldOverrideLight = shouldOverrideLight && ATTENUATION > 0.0;
	//if (shouldOverrideLight)
	//{
		//DIFFUSE_LIGHT = max(litColor * ATTENUATION,DIFFUSE_LIGHT);
	//}
//}
