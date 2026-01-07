shader_type spatial;
render_mode world_vertex_coords;
uniform sampler2D heightMap;
uniform sampler2D mapTexture;
const float maxHeight = 60.0;
const vec2 mapSize = vec2(4096.0,4096.0);
const float mapScale = 6.0;

void vertex() {
	// Called for every vertex the material is visible on.
	vec2 effectivePosition = mapScale * (VERTEX.xz/mapSize);
	float height = texture(heightMap, effectivePosition).r;
	VERTEX.y = height * maxHeight;
}

void fragment() {
	// Called for every pixel the material is visible on.
	ALBEDO = texture(mapTexture,UV).rgb;
}

void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
}
