shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform float blur_amount : hint_range(0.0, 20.0) = 4.0;

void fragment() {
	vec2 tex_size = vec2(textureSize(SCREEN_TEXTURE, 0));
	vec2 uv = SCREEN_UV;
	vec2 delta = blur_amount / tex_size;
	
	vec4 col = vec4(0.0);
	col += textureLod(SCREEN_TEXTURE, uv + vec2(-2.0, -2.0) * delta, 0.0) * 0.0625;
	col += textureLod(SCREEN_TEXTURE, uv + vec2(-1.0, -2.0) * delta, 0.0) * 0.125;
	col += textureLod(SCREEN_TEXTURE, uv + vec2(0.0, -2.0) * delta, 0.0) * 0.0625;
	col += textureLod(SCREEN_TEXTURE, uv + vec2(1.0, -2.0) * delta, 0.0) * 0.125;
	col += textureLod(SCREEN_TEXTURE, uv + vec2(2.0, -2.0) * delta, 0.0) * 0.0625;
	
	col += textureLod(SCREEN_TEXTURE, uv + vec2(-2.0, -1.0) * delta, 0.0) * 0.125;
	col += textureLod(SCREEN_TEXTURE, uv + vec2(-1.0, -1.0) * delta, 0.0) * 0.25;
	col += textureLod(SCREEN_TEXTURE, uv + vec2(0.0, -1.0) * delta, 0.0) * 0.125;
	col += textureLod(SCREEN_TEXTURE, uv + vec2(1.0, -1.0) * delta, 0.0) * 0.25;
	col += textureLod(SCREEN_TEXTURE, uv + vec2(2.0, -1.0) * delta, 0.0) * 0.125;
	
	col += textureLod(SCREEN_TEXTURE, uv + vec2(-2.0, 0.0) * delta, 0.0) * 0.0625;
	col += textureLod(SCREEN_TEXTURE, uv + vec2(-1.0, 0.0) * delta, 0.0) * 0.125;
	col += textureLod(SCREEN_TEXTURE, uv + vec2(0.0, 0.0) * delta, 0.0) * 0.0625;
	col += textureLod(SCREEN_TEXTURE, uv + vec2(1.0, 0.0) * delta, 0.0) * 0.125;
	col += textureLod(SCREEN_TEXTURE, uv + vec2(2.0, 0.0) * delta, 0.0) * 0.0625;
	
	col += textureLod(SCREEN_TEXTURE, uv + vec2(-2.0, 1.0) * delta, 0.0) * 0.125;
	col += textureLod(SCREEN_TEXTURE, uv + vec2(-1.0, 1.0) * delta, 0.0) * 0.25;
	col += textureLod(SCREEN_TEXTURE, uv + vec2(0.0, 1.0) * delta, 0.0) * 0.125;
	col += textureLod(SCREEN_TEXTURE, uv + vec2(1.0, 1.0) * delta, 0.0) * 0.25;
	col += textureLod(SCREEN_TEXTURE, uv + vec2(2.0, 1.0) * delta, 0.0) * 0.125;
	
	col += textureLod(SCREEN_TEXTURE, uv + vec2(-2.0, 2.0) * delta, 0.0) * 0.0625;
	col += textureLod(SCREEN_TEXTURE, uv + vec2(-1.0, 2.0) * delta, 0.0) * 0.125;
	col += textureLod(SCREEN_TEXTURE, uv + vec2(0.0, 2.0) * delta, 0.0) * 0.0625;
	col += textureLod(SCREEN_TEXTURE, uv + vec2(1.0, 2.0) * delta, 0.0) * 0.125;
	col += textureLod(SCREEN_TEXTURE, uv + vec2(2.0, 2.0) * delta, 0.0) * 0.0625;
	
	COLOR = col;
}
