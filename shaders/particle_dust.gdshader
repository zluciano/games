shader_type particles;

// Floating Dust Particles - Adds atmosphere and life to scenes

uniform float spread : hint_range(1.0, 50.0) = 20.0;
uniform float height : hint_range(1.0, 20.0) = 8.0;
uniform float speed : hint_range(0.1, 2.0) = 0.3;
uniform float size_min : hint_range(0.01, 0.2) = 0.02;
uniform float size_max : hint_range(0.05, 0.5) = 0.08;

float rand(vec2 co) {
	return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}

void start() {
	// Random position in volume
	float r1 = rand(vec2(float(INDEX), 0.0));
	float r2 = rand(vec2(float(INDEX), 1.0));
	float r3 = rand(vec2(float(INDEX), 2.0));

	TRANSFORM[3].x = (r1 - 0.5) * spread * 2.0;
	TRANSFORM[3].y = r2 * height;
	TRANSFORM[3].z = (r3 - 0.5) * spread * 2.0;

	// Random size
	float size = mix(size_min, size_max, rand(vec2(float(INDEX), 3.0)));
	TRANSFORM[0].x = size;
	TRANSFORM[1].y = size;
	TRANSFORM[2].z = size;

	// Random velocity
	VELOCITY.x = (rand(vec2(float(INDEX), 4.0)) - 0.5) * speed;
	VELOCITY.y = (rand(vec2(float(INDEX), 5.0)) - 0.3) * speed * 0.5;
	VELOCITY.z = (rand(vec2(float(INDEX), 6.0)) - 0.5) * speed;

	// Color variation
	COLOR.a = mix(0.3, 0.7, rand(vec2(float(INDEX), 7.0)));
}

void process() {
	// Gentle floating motion
	VELOCITY.y += sin(TIME * 2.0 + float(INDEX)) * 0.01;
	VELOCITY.x += cos(TIME * 1.5 + float(INDEX) * 0.5) * 0.005;

	// Wrap around when out of bounds
	if (TRANSFORM[3].y < 0.0) {
		TRANSFORM[3].y = height;
	}
	if (TRANSFORM[3].y > height) {
		TRANSFORM[3].y = 0.0;
	}

	// Fade based on height
	COLOR.a = smoothstep(0.0, 2.0, TRANSFORM[3].y) * smoothstep(height, height - 2.0, TRANSFORM[3].y) * 0.6;
}
