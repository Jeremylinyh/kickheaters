shader_type spatial;
render_mode world_vertex_coords;
uniform sampler2D heightMap;
uniform sampler2D mapTexture;
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

void fragment() {
	// Called for every pixel the material is visible on.
	vec2 pixelPos = v_world_pos/mapSize;

	ALBEDO = texture(mapTexture,pixelPos * mapScale).rgb;
	//ALBEDO = vec3(fract(heightSampled * 1.0));

	// 1. LIGHT_VERTEX to World
    vec3 world_pos = (INV_VIEW_MATRIX * vec4(LIGHT_VERTEX, 1.0)).xyz;

    // 2. Round / Snap to Grid
    float grid_size = 1.0;
    vec3 snapped_world_pos = round(world_pos / grid_size) * grid_size;

    // 3. "Write" back by calculating a modified Light Vector
    // Convert snapped world pos back to View Space to interact with LIGHT
    LIGHT_VERTEX = (VIEW_MATRIX * vec4(snapped_world_pos, 1.0)).xyz;
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
