shader_type canvas_item;
render_mode blend_mix;

uniform sampler2D mask_texture;
uniform float rect_size = 1.0;
uniform float ratio_width = 1.0;
uniform float ratio_height = 1.0;
uniform float ratio_width_sprite = 1.0;
uniform float ratio_height_sprite = 1.0;
uniform float angle = 0.0;
uniform float location_x = 0.0;
uniform float location_y = 0.0;
uniform bool invert_mask = false;

vec2 rotateUV(vec2 uv, vec2 pivot, float degree)
{
	mat2 rotation = mat2(vec2(sin(degree), -cos(degree)),
						vec2(cos(degree), sin(degree)));
	
	uv -= pivot;
	uv = uv * rotation;
	uv += pivot;
	return uv;
}

void fragment() {
    vec4 colour = texture(TEXTURE, UV);
	vec2 offset = vec2(location_x/ratio_width_sprite,location_y/ratio_height_sprite);
	vec2 texture_position = (rotateUV(UV / vec2(ratio_width_sprite,ratio_height_sprite), vec2(0.5) * vec2(ratio_width,ratio_height) * rect_size + offset, PI/2.0 + angle) - offset) / vec2(ratio_width,ratio_height) / rect_size;
	if (!invert_mask && (texture_position.x < 0.0 || texture_position.y < 0.0 || texture_position.x > 1.0|| texture_position.y > 1.0))
		colour.a = 0.0;
		
	else {
		vec4 mask_color = texture(mask_texture, texture_position);
		float alpha_total = mask_color.a;
		
		if (invert_mask == true) {
			alpha_total = 1.0 - alpha_total;
		}
	    colour.a *= alpha_total;
		colour.rgb *= mask_color.rgb;
	}
	
    COLOR.rgba *= colour.rgba;
}