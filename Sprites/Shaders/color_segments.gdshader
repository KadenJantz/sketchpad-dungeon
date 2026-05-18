shader_type canvas_item;
render_mode unshaded;

// Global Variables
global uniform vec4 color_1:source_color;
global uniform vec4 color_2:source_color;
global uniform vec4 color_3:source_color;
global uniform vec4 color_4:source_color;
global uniform vec4 color_5:source_color;
global uniform vec4 color_6:source_color;

// Public Variables
uniform int sections;
uniform int colors_order;
uniform int colors_count;

uniform bool reverse;
uniform vec2 size;

// Private Variables
varying vec2 scaledUV;
varying float selectedUV;

void vertex() {
	scaledUV = VERTEX.xy / size; //Scales UV according to input size.
	if(!reverse) { selectedUV = scaledUV.x; } //Switches between Horizontal and Vertical Gradient
	else { selectedUV = -scaledUV.x; }
}

void fragment() {
	int section = int((selectedUV*size).x)/sections;
	
    vec4 current_pixel = texture(TEXTURE, UV);
	
	if (section < 1) {
		COLOR = vec4(0, 0, 0, 1);
	}
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
