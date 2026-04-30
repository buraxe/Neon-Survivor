shader_type canvas_item;

uniform float intensity : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 center = vec2(0.5, 0.5);
	
	float dx = abs(uv.x - 0.5) * 2.0;
	float dy = abs(uv.y - 0.5) * 2.0;
	float edge_dist = max(dx, dy);
	
	float vignette = smoothstep(0.5, 1.0, edge_dist);
	float soft_edge = smoothstep(0.3, 0.7, edge_dist);
	
	float alpha = vignette * soft_edge * intensity;
	COLOR = vec4(0.85, 0.0, 0.0, alpha * 0.6);
}
