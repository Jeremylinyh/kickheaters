global uniform vec2 tankPos0;
global uniform sampler2D Horizon0 : filter_linear;
global uniform sampler2D Cupola0;

const float shadowDarkness = 0.25;

float sampleTexheight(float theta,float dist,sampler2D tex)
{
	return textureLod(tex,vec2(theta,dist/1024.0),0.0).r;
}

// returns how visible one is; 0.0 --> nothing; 0.5 --> can see cupola; 1.0 --> can see hull;
float isUnderground(vec3 fragWorldPos) {
	vec2 relativePos = fragWorldPos.xz - tankPos0;
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
	if (fragWorldPos.y > sampleTexheight(theta,dist,Horizon0))
	{
		return 1.0;
	}
	//else if (fragWorldPos.y > sampleTexheight(theta,dist,Cupola0))
	//{
		//return 0.75;
	//}
	return shadowDarkness;
}
