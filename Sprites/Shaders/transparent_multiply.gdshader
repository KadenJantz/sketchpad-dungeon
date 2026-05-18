shader_type canvas_item;
render_mode blend_mul;

void fragment() {
    vec4 current_pixel = texture(TEXTURE, UV);
	if (current_pixel.a == 0.0)
		COLOR.rgb = vec3(1, 1, 1);
}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
