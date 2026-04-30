shader_type canvas_item;

uniform float glow_intensity : hint_range(0.0, 2.0) = 1.0;
uniform float pulse_speed : hint_range(0.5, 10.0) = 2.0;
uniform vec4 glow_color : source_color = vec4(0.0, 1.0, 1.0, 0.6);

void fragment() {
	vec4 col = COLOR * TEXTURE;
	float pulse = 0.8 + 0.2 * sin(TIME * pulse_speed);
	col.rgb += glow_color.rgb * glow_intensity * pulse * col.a;
	COLOR = col;
}
