shader_type canvas_item;

uniform sampler2D mask_texture;
uniform vec2 offset;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;

varying vec2 world_position;

void vertex() {
	 world_position = (SCREEN_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	vec2 texture_position = (world_position + offset);
	
	// Do not allow out of bounds pixels
	if (texture_position.x < 0.0 || texture_position.y < 0.0 || texture_position.x > 1.0|| texture_position.y > 1.0)
		COLOR.a = 0.0;
	else {
		vec4 texture_sample = texture(mask_texture, texture_position);
		vec4 screen_sample = textureLod(screen_texture, SCREEN_UV, 0.0);
		
		COLOR.rgb *= screen_sample.rgb;
		COLOR.a *= texture_sample.a;
	}
}