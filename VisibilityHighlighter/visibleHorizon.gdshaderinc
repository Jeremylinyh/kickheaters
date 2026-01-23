// as you have probably guessed, this thing handles horizon maps. Up to 4 viewers at once.

global uniform vec2 tankPos0;
global uniform vec2 tankPos1;
global uniform vec2 tankPos2;
global uniform vec2 tankPos3;

global uniform sampler2DArray Horizon : filter_linear;
global uniform float horizonLayerCount; // WARN: This is only a suggestion, it is not used anywhere, we'll see

const float shadowDarkness = 0.25;
float sampleTexheight(float theta, float dist,float index)
{
    float coord_y = (dist - 0.5) / 1024.0;
    coord_y = min(coord_y, (1024.0 - 0.5) / 1024.0);

    return textureLod(Horizon, vec3(theta, coord_y,index), 0.0).r;
}

float isUndergroundHelper(vec3 fragWorldPos,float currIndex) {
	vec2 tankPositions[4] = vec2[](tankPos0,tankPos1,tankPos2,tankPos3);
	
	vec2 relativePos = fragWorldPos.xz - tankPositions[int(currIndex)];
	float dist = length(relativePos);
	if (dist > 1024.0)
	{
		return shadowDarkness;
	}
	float angle_rad = atan(relativePos.y,relativePos.x);
	if (angle_rad < 0.0) {
	    angle_rad += 6.28318530718; // 2 * PI
	}
	float theta = angle_rad / 6.28318530718;
	//return sampleTexheight(theta,dist,Horizon0);
	if (fragWorldPos.y > sampleTexheight(theta,dist,currIndex) - 1.0)
	{
		return 1.0;
	}
	
	return shadowDarkness;
}

// returns how visible one is; 0.0 --> nothing; 0.5 --> can see cupola; 1.0 --> can see hull;
float isUnderground(vec3 fragWorldPos) {
	float determination = 0.0;
	for (float i = 0.0; i < 4.0; i++)
	{
		determination = max(determination,isUndergroundHelper(fragWorldPos,i));
	}
	return determination;
}
