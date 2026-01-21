global uniform vec2 tankPos0;
global uniform sampler2D Horizon0;
global uniform sampler2D Cupola0;

// returns how visible one is; 0.0 --> nothing; 0.5 --> can see cupola; 1.0 --> can see hull;
float isUnderground() {
	return 0.0;
}