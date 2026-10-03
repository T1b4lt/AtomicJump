// Orbital background (docs/13-art-style.md#fondos-orbitales): the probability
// density |psi|^2 of the layer's orbital around the screen's center, compressed
// with pow(d, 0.45) and tinted, with "measurements" (dots sampled by the
// density) that twinkle, faint energy-level rings and a vignette. The cloud
// breathes slowly (±12 %). Translation of art/atomic_art/world.py's
// orbital_background(). Layer K: orbital 1s, psi = e^(-r).
shader_type canvas_item;

uniform vec4 void_color : source_color;
uniform vec4 tint : source_color;
uniform vec4 accent : source_color;
// Bohr radii from the center to the top edge of the screen.
uniform float extent = 3.4;
// Height of the reference screen in px: sizes below are in these px.
uniform float reference_height = 720.0;
uniform float breathing = 0.12;
uniform float breathing_period = 7.0;
uniform float cloud_strength = 0.55;
// Measurement dots: grid cell in px, how many of the cells get one at full
// density, their brightness (over 1 they glow) and how fast they twinkle.
uniform float dot_cell = 6.0;
uniform float dot_density = 0.5;
uniform float dot_brightness = 1.3;
uniform float twinkle_speed = 1.7;
uniform float ring_spacing = 130.0;
uniform float ring_strength = 0.06;
uniform float vignette = 0.55;

float hash(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

// |psi|^2 of the 1s orbital, 1 at the nucleus.
float density(float r_bohr) {
	return exp(-2.0 * r_bohr);
}

void fragment() {
	float aspect = SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
	vec2 p = (UV - 0.5) * vec2(aspect, 1.0) * reference_height;
	float breath = 1.0 + breathing * sin(TAU * TIME / breathing_period);
	vec2 q = p / breath;
	float px_per_bohr = reference_height * 0.5 / extent;
	float d = density(length(q) / px_per_bohr);
	float cloud = pow(d, 0.45);
	vec3 color = void_color.rgb + cloud * tint.rgb * cloud_strength;

	vec2 cell = floor(q / dot_cell);
	vec2 center = (cell + 0.5) * dot_cell;
	float cell_density = density(length(center) / px_per_bohr);
	if (hash(cell) < cell_density * dot_density) {
		vec2 dot_pos = (cell + vec2(hash(cell + 7.1), hash(cell + 3.7))) * dot_cell;
		float spot = 1.0 - smoothstep(0.4, 1.2, length(q - dot_pos));
		float level = mix(0.35, 1.0, hash(cell + 1.3));
		float twinkle = 0.6 + 0.4 * sin(TIME * twinkle_speed + hash(cell + 9.9) * TAU);
		color += accent.rgb * spot * level * twinkle * dot_brightness * (0.35 + 0.65 * cloud);
	}

	float radius = length(p);
	for (int k = 1; k <= 5; k++) {
		float ring = 1.0 - smoothstep(0.0, 1.2, abs(radius - float(k) * ring_spacing));
		color += accent.rgb * ring_strength * ring;
	}
	float edge = clamp(radius / (reference_height * aspect * 0.62), 0.0, 1.0);
	color *= 1.0 - vignette * edge * edge;
	COLOR = vec4(color, 1.0);
}
