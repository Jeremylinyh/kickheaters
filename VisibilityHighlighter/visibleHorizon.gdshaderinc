// as you have probably guessed, this thing handles horizon maps. Up to 4 viewers at once.

global uniform vec2 tankPos0;
global uniform vec2 tankPos1;
global uniform vec2 tankPos2;
global uniform vec2 tankPos3;

global uniform float tankFacing0;
global uniform float tankFacing1;
global uniform float tankFacing2;
global uniform float tankFacing3;

global uniform sampler2DArray Horizon : filter_linear;
global uniform float horizonLayerCount;

const float defaultLitness = 0.0;
const float brightness = 1.16;
const float fovSide = 0.99; // a dot product comparison
//vec4 sampleTexheight(float theta, float dist,float index)
//{
    //float coord_y = (dist - 0.5) / 1024.0;
    //coord_y = min(coord_y, (1024.0 - 0.5) / 1024.0);
//
    //return textureLod(Horizon, vec3(theta, coord_y,index), 0.0);
//}

vec4 sampleTexheight(float theta, float dist,float index)
{
    // 1. Calculate the base coordinates (original logic)
    float coord_y = (dist - 0.5) / 1024.0;
    coord_y = min(coord_y, (1024.0 - 0.5) / 1024.0);

    // 2. Determine Texel Size
    // Fetch the resolution of 'Horizon' to calculate the size of one texel.
    // We cast to float to use in UV calculations.
    ivec3 texSize = textureSize(Horizon, 0);
    vec2 texelSize = vec2(1.0) / vec2(texSize.xy);

    vec4 total = vec4(0.0);
    float samples = 0.0;

    // 3. PCF Loop (3x3 Kernel)
    // Runs from -1 to 1 in both X and Y directions
    for (int x = -1; x <= 1; x++)
    {
        for (int y = -1; y <= 1; y++)
        {
            // Calculate offset based on texel size
            vec2 offset = vec2(float(x), float(y)) * texelSize;

            // Sample the texture with the offset
            // We use the same 'index' for the array layer
            total += textureLod(Horizon, vec3(theta + offset.x, coord_y + offset.y, index), 0.0);
            samples += 1.0;
        }
    }

    // 4. Return the average
    return total / samples;
}

vec2 isUndergroundHelper(vec3 fragWorldPos,float currIndex) {
	vec2 tankPositions[4] = vec2[](tankPos0,tankPos1,tankPos2,tankPos3);
	float tankFacings[4] = float[](tankFacing0,tankFacing1,tankFacing2,tankFacing3);

	vec2 relativePos = fragWorldPos.xz - tankPositions[int(currIndex)];
	float dist = length(relativePos);
	if (dist > 1024.0)
	{
		return vec2(0.0);
	}
	float angle_rad = atan(relativePos.y,relativePos.x);
	if (angle_rad < 0.0) {
	    angle_rad += 6.28318530718; // 2 * PI
	}
	float theta = angle_rad / 6.28318530718;
	//return sampleTexheight(theta,dist,Horizon0);
	if (fragWorldPos.y > sampleTexheight(theta,dist,currIndex).g - 1.0)
	{
		return vec2(1.0,0.0);
	}
	else if (fragWorldPos.y > sampleTexheight(theta,dist,currIndex).r - 1.0)
	{
		return vec2(0.0,1.0);
	}

	return vec2(0.0);
}

// returns how visible one is; 0.0 --> nothing; 0.5 --> can see cupola; 1.0 --> can see hull;
vec3 isUndergroundQ(vec3 fragWorldPos) {
	//float determinationX = 0.0;
	//float determinationY = 0.0;
	vec3 determination = vec3(0.0);
	for (int i = 0; i < 4; i++)
	{
		if (float(i) >= horizonLayerCount)
		{
			return determination;
		}
		vec2 shadowTestResult = isUndergroundHelper(fragWorldPos,float(i));
		determination.x = max(determination.x,shadowTestResult.x);
		determination.y = max(determination.y,shadowTestResult.y);
	}
	return determination;
}

vec3 isUnderground(vec3 fragWorldPos)
{
	vec3 result = isUndergroundQ(fragWorldPos);
	vec2 tankPositions[4] = vec2[](tankPos0,tankPos1,tankPos2,tankPos3);
	float tankFacings[4] = float[](tankFacing0,tankFacing1,tankFacing2,tankFacing3);
	//return result;
	for (int i= 0; i < 4; i++)
	{
		if (float(i) >= horizonLayerCount)
		{
			break;
		}
		vec2 relativePos = fragWorldPos.xz-tankPositions[i];
		vec2 relevantFacing = vec2(cos(tankFacings[i]),sin(tankFacings[i]));
		if ((result.r > 0.0 || result.g > 0.0) && (dot(normalize(relativePos),relevantFacing)) > fovSide)
		{
			return vec3(brightness * 1.0);
		}
	}

	if (result.r > 0.0)
	{
		return vec3(brightness + defaultLitness,vec2(defaultLitness))/vec3(0.016, 0.569, 0.035);
	}
	if (result.g > 0.0)
	{
		return vec3(0.0, 1.0, 1.0)/vec3(0.016, 0.569, 0.035);// //vec3(defaultLitness,brightness*0.75 + defaultLitness,defaultLitness);
	}

	return vec3(defaultLitness/1.0);
}
