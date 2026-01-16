shader_type spatial;
render_mode world_vertex_coords;
uniform sampler2D heightMap;
uniform sampler2D mapTexture;

// snippet insert
uniform sampler2D depthTexture0 : filter_nearest;
uniform mat4 projMatrix0;
// snippet outsert
uniform float numDepthTextures = 1;
const float maxHeight = 60.0;
const vec2 mapSize = vec2(4096.0,4096.0);
const float mapScale = 1.0;

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

// true if in shadow
bool isInShadow(sampler2D depthTexture,vec4 world_pos,mat4 projMatrix) {
	// --- STEP 2: Project to Shadow Camera (The "Camera in Question") ---
    // This transforms World Space -> Shadow Camera Clip Space
    vec4 shadow_coords = projMatrix * world_pos;

    // Perspective Divide (Essential for 3D projection)
    vec3 shadow_uv_depth = shadow_coords.xyz / shadow_coords.w;

    // Coordinate Fixes:
    // 1. Transform (-1 to 1) range to (0 to 1) range for UV texture reading
    vec2 uv = shadow_uv_depth.xy * 0.5 + 0.5;

    // 2. Flip Y (Often needed in Godot/Vulkan because UVs start at top-left)
    // If your shadows are upside down, toggle this line.
    uv.y = 1.0 - uv.y;

	float my_dist = shadow_coords.w; // Often .w holds the linear depth before division!

    // B. Read "Map Distance" (Blocker)
    // Check if we are actually inside the shadow map area
    float shadow = 1.0;
    if (uv.x >= 0.0 && uv.x <= 1.0 && uv.y >= 0.0 && uv.y <= 1.0) {

        vec3 c = texture(depthTexture, uv).rgb * 100.0;

        // DECODE BASE-100
        float r = c.r;
        float g = c.g;
        float b = c.b;
        float map_dist = (r + g*100.0 + b*10000.0) / 10.0;

        // C. The Comparison
        if (my_dist > map_dist) {
            return true;
        }
    }
	else {
		return true;
	}
	return false;
}

void fragment() {
	// Called for every pixel the material is visible on.
	vec2 pixelPos = v_world_pos/mapSize;

	ALBEDO = texture(mapTexture,pixelPos * mapScale).rgb;
	//ALBEDO = vec3(fract(heightSampled * 1.0));
	vec4 world_pos = INV_VIEW_MATRIX * vec4(VERTEX, 1.0);
	if (!isInShadow(depthTexture0,world_pos,projMatrix0))
	{
		ALBEDO *= 6.0;
	}
	//ALBEDO = texture(depthTexture0,pixelPos * mapScale).rgb;
}

void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
	vec3 litColor = LIGHT_COLOR; //vec3(0.5);
	bool shouldOverrideLight = length(DIFFUSE_LIGHT) <= 0.;
	shouldOverrideLight = shouldOverrideLight || (litColor.x == litColor.y); // or if self is white
	shouldOverrideLight = shouldOverrideLight && ATTENUATION > 0.0;
	if (shouldOverrideLight)
	{
		DIFFUSE_LIGHT = max(litColor * ATTENUATION,DIFFUSE_LIGHT);
	}
}
