shader_type canvas_item;

uniform vec4 color:source_color;

void fragment() {
    vec4 current_pixel = texture(TEXTURE, UV);

    if (current_pixel.r == current_pixel.g && current_pixel.g == current_pixel.b) {
		float alpha = COLOR.a;
        COLOR = color * current_pixel;
		COLOR.a = alpha;
	}
    else
        COLOR = current_pixel;
}