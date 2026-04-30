shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform float curvature : hint_range(0.0, 1.0, 0.01) = 0.4;
uniform float chroma : hint_range(0.0, 1.0, 0.01) = 0.5;
uniform float scanlines : hint_range(0.0, 1.0, 0.01) = 0.6;
uniform float vignette : hint_range(0.0, 1.0, 0.01) = 0.4;
uniform float flicker_amount : hint_range(0.0, 1.0, 0.01) = 0.5;
uniform float time : hint_range(0.0, 10000.0, 0.01) = 0.0;

void fragment() {
	vec2 uv = UV;
	
	// Barrel Distortion
	if (curvature > 0.0) {
		vec2 center = uv * 2.0 - 1.0;
		float r2 = dot(center, center);
		vec2 distorted = center * (1.0 + curvature * 0.15 * r2);
		uv = (distorted + 1.0) * 0.5;
	}
	
	// Chromatic Aberration
	vec2 center = UV - 0.5;
	float dist = length(center) * 1.5;
	float offset = chroma * 0.008 * pow(dist, 1.5);
	
	if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
		COLOR = vec4(0.0, 0.0, 0.0, 1.0);
	} else {
		float r = texture(SCREEN_TEXTURE, uv + vec2(offset, 0.0)).r;
		float g = texture(SCREEN_TEXTURE, uv).g;
		float b = texture(SCREEN_TEXTURE, uv - vec2(offset, 0.0)).b;
		vec3 color = vec3(r, g, b);
	
		// Scanlines
		if (scanlines > 0.0) {
			float scan = sin(uv.y * 800.0 + time * 2.0) * 0.5 + 0.5;
			scan = pow(scan, 1.5);
			color *= mix(1.0, scan, scanlines * 0.3);
		}
		
		// Vignette
		if (vignette > 0.0) {
			vec2 vc = UV - 0.5;
			float v = 1.0 - dot(vc, vc) * (1.0 + vignette);
			color *= clamp(v, 0.0, 1.0);
		}
		
		// Flicker
		if (flicker_amount > 0.0) {
			float flicker = 1.0 - sin(time * 11.0) * flicker_amount * 0.02;
			color *= flicker;
		}
		
		COLOR = vec4(color, 1.0);
	}
}
