[gd_shader format=3]

[shader_source]
shader_type canvas_item;

uniform float u_time : hint_range(0.0, 3.0);
uniform float u_intensity : hint_range(0.0, 1.0);

void fragment() {
	vec2 uv = SCREEN_UV;
	float t = u_time;
	
	// Generate white noise based on UV and time
	float noise = fract(sin(dot(uv * (1.0 + t * 10.0), vec2(12.9898, 78.233))) * 43758.5453);
	
	// Add scanline effect
	float scanline = sin(uv.y * 800.0 + t * 50.0) * 0.5 + 0.5;
	
	// Combine noise and scanlines
	float static_val = noise * u_intensity * 0.8 + scanline * u_intensity * 0.1;
	
	// White static color
	COLOR = vec4(static_val, static_val, static_val, u_intensity);
}
