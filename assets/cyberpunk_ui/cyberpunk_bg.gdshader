shader_type canvas_item;

void fragment() {
	vec2 uv = UV;
	vec3 col = vec3(0.02, 0.01, 0.06);

	float gx = step(0.96, fract(uv.x * 60.0));
	float gy = step(0.96, fract(uv.y * 40.0));
	col += vec3(0.0, 0.08, 0.12) * (gx + gy);

	float scan = sin(uv.y * 300.0) * 0.5 + 0.5;
	col += vec3(0.0, 0.012, 0.025) * scan;

	float d = distance(uv, vec2(0.5));
	col *= 1.0 - d * 0.6;

	COLOR = vec4(col, 1.0);
}
