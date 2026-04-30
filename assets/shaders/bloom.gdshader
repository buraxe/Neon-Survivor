shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform float intensity : hint_range(0.0, 2.0, 0.01) = 0.8;
uniform float threshold : hint_range(0.0, 1.0, 0.01) = 0.5;

void fragment() {
	vec2 size = vec2(textureSize(SCREEN_TEXTURE, 0));
	vec2 uv = UV;
	
	vec4 sum = vec4(0.0);
	
	// Multi-pass blur for bloom
	float weights[5] = float[](0.227027, 0.1945946, 0.1216216, 0.054054, 0.016216);
	
	sum += texture(SCREEN_TEXTURE, uv) * weights[0];
	
	for (int i = 1; i < 5; i++) {
		float offset = float(i) * 2.0 / size.x * intensity;
		sum += texture(SCREEN_TEXTURE, uv + vec2(offset, 0.0)) * weights[i];
		sum += texture(SCREEN_TEXTURE, uv - vec2(offset, 0.0)) * weights[i];
	}
	
	for (int i = 1; i < 5; i++) {
		float offset = float(i) * 2.0 / size.y * intensity;
		sum += texture(SCREEN_TEXTURE, uv + vec2(0.0, offset)) * weights[i];
		sum += texture(SCREEN_TEXTURE, uv - vec2(0.0, offset)) * weights[i];
	}
	
	// Only bloom bright pixels
	float brightness = dot(sum.rgb, vec3(0.2126, 0.7152, 0.0722));
	if (brightness < threshold) {
		sum = vec4(0.0);
	}
	
	// Add bloom to original
	vec4 original = texture(SCREEN_TEXTURE, uv);
	COLOR = original + sum * 0.5;
}
