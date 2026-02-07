shader_type spatial;
global uniform sampler2D heightMap;
render_mode cull_front , unshaded;

const float heightmapWidth = 4096.0;

varying vec3 position;

float random(vec3 p) {
    return fract(sin(dot(p, vec3(12.9898, 78.233, 54.53))) * 43758.5453);
}

void vertex() {
	// Called for every vertex the material is visible on.
	position = VERTEX;
}

void fragment() {
	// Called for every pixel the material is visible on.
	//const float steps = 16.0;
	//vec3 currentPosition = floor(position * steps)/steps;
	//ALBEDO = vec3(0.890, 0.733, 0.169) * (random(currentPosition)*0.5+0.25);
	ALBEDO = vec3(0.016, 0.569, 0.035) * (textureLod(heightMap,UV * 3.0/1.0,0.0).r + 0.1);
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
