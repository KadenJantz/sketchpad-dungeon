shader_type canvas_item;
render_mode unshaded;

uniform float progress: hint_range(0.0, 1.0) = 0.5;
uniform vec4 bg_color: source_color;
uniform vec4 color_1: source_color;
uniform vec4 color_2: source_color;
uniform float wave_1_speed = -1.0;
uniform float wave_2_speed = 1.0;
uniform float wave_1_scale = 1.0;
uniform float wave_2_scale = 1.0;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

vec4 wave( vec2 uv, vec4 wave_color, float level, float freq, float amp, float sin_shift, float speed ){
	float sinus = sin( (uv.x + sin_shift + TIME * speed) * freq) * amp;
	float shifted_level = ( 1.0 + 2.0 * amp ) * level - amp; //shift to completely hide or fill
	float treshold = step( 1.0 - sinus - shifted_level, uv.y);
	return wave_color * treshold;
}

void fragment() {
	vec4 c = textureLod(screen_texture, SCREEN_UV, 0.0);

	if (c.a > 0.0001) {
		c.rgb /= c.a;
	}

	COLOR *= c;
	
	if (COLOR.a != 0.0) {
		vec4 wave1 = wave(UV, color_1, progress, 2.5, 0.13 * wave_1_scale, 0.0, wave_1_speed);
		vec4 wave2 = wave(UV, color_2, progress, 2.0, 0.1 * wave_2_scale, 0.7785*TIME, wave_2_speed);
		
		vec4 combined_waves = mix(wave1, wave2, wave2.a);
		COLOR.rgba = mix( bg_color, combined_waves, combined_waves.a ).rgba;
	}
}