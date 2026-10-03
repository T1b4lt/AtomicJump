// The Decoherence: a pale noise front with a bright wavy edge, 4 px blocks that
// break away ahead of it and scanlines. Port of decoherence_strip() in
// art/atomic_art/world.py; docs/13-art-style.md#decoherencia.
shader_type canvas_item;

uniform vec4 base_color : source_color = vec4(0.788, 0.824, 1.0, 1.0);
// Size of the rect in px (UV goes 0-1 over it).
uniform vec2 rect_size = vec2(1600.0, 1000.0);
// Px from the top of the rect to the mean front line (the threat's y).
uniform float front_offset = 60.0;
// Brightness of the edge; above 1 it glows (HDR).
uniform float edge_glow = 2.0;
uniform float block_size = 4.0;
// Speed of the waves and of the flicker.
uniform float speed = 1.0;
// Blocks and noise change this many times per second.
uniform float flicker_rate = 12.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 px = UV * rect_size;
	float t = TIME * speed;
	float front = front_offset
		+ 18.0 * sin(px.x / 57.0 + 1.3 * t)
		+ 10.0 * sin(px.x / 13.0 + 1.3 - 2.1 * t)
		+ 6.0 * sin(px.x / 5.1 + 3.7 * t);
	// Positive inside the Decoherence
	float depth = px.y - front;
	float frame = floor(TIME * flicker_rate);
	float block = hash(floor(px / block_size) + vec2(frame * 0.37, frame * 1.71));
	float noise = hash(floor(px) + vec2(frame));

	float alpha = 0.0;
	if (depth > 0.0) {
		alpha = clamp(0.35 + depth / 180.0, 0.0, 0.95);
	} else if (depth > -40.0 && block > clamp(-depth / 40.0, 0.0, 1.0)) {
		alpha = 0.55 * block;
	}
	float edge = exp(-(depth * depth) / 18.0);
	alpha = clamp(alpha + edge * 0.9, 0.0, 1.0);

	float scan = mod(floor(px.y), 3.0) < 1.0 ? 1.0 : 0.85;
	vec3 rgb = base_color.rgb * (0.55 + 0.45 * noise) * scan;
	rgb += vec3(edge * 0.4 * edge_glow);
	COLOR = vec4(rgb, alpha);
}
