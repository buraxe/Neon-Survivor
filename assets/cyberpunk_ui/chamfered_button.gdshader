shader_type canvas_item;

uniform float chamfer : hint_range(0.0, 30.0) = 8.0;
uniform float border_width : hint_range(0.0, 6.0) = 2.0;
uniform vec4 border_color : source_color = vec4(0.0, 1.0, 1.0, 1.0);
uniform float glow_size : hint_range(0.0, 12.0) = 4.0;
uniform vec4 glow_color : source_color = vec4(0.0, 1.0, 1.0, 0.3);
uniform float scanline_intensity : hint_range(0.0, 0.15) = 0.04;

void fragment() {
	vec2 size = vec2(textureSize(TEXTURE, 0));
	vec2 uv = FRAGCOORD.xy;
	
	float c = chamfer;
	float bw = border_width;
	
	bool inside_chamfer = true;
	
	if (uv.x < c && uv.y < c) {
		if (uv.x + uv.y < c) inside_chamfer = false;
	}
	if (uv.x > size.x - c && uv.y < c) {
		if ((size.x - uv.x) + uv.y < c) inside_chamfer = false;
	}
	if (uv.x < c && uv.y > size.y - c) {
		if (uv.x + (size.y - uv.y) < c) inside_chamfer = false;
	}
	if (uv.x > size.x - c && uv.y > size.y - c) {
		if ((size.x - uv.x) + (size.y - uv.y) < c) inside_chamfer = false;
	}
	
	bool is_border = false;
	if (inside_chamfer) {
		float dist_left = uv.x;
		float dist_right = size.x - uv.x;
		float dist_top = uv.y;
		float dist_bottom = size.y - uv.y;
		
		float min_dist = min(min(dist_left, dist_right), min(dist_top, dist_bottom));
		
		if (min_dist < bw) {
			is_border = true;
		}
	}
	
	vec4 tex_color = texture(TEXTURE, UV);
	vec4 col = tex_color;
	
	if (!inside_chamfer) {
		col = vec4(0.0);
	} else if (is_border) {
		col = mix(col, border_color, 0.85);
	}
	
	float scan = sin(uv.y * 3.14159 * 2.0) * scanline_intensity;
	col.rgb += scan;
	
	COLOR = col;
}
