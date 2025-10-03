shader_type canvas_item;

uniform vec4 prev_color: source_color = vec4(1.0);
uniform vec4 prev_subcolor: source_color = vec4(1.0);
uniform vec4 new_color: source_color = vec4(0.0, 0.0, 0.0, 1.0);

void fragment() {
    vec4 color = texture(TEXTURE, UV);
    vec4 initial_color = color;
	
    if (color == prev_color) {
		color = mix(new_color, color, 0);
    } else if (prev_subcolor == color) {
		color = mix(new_color+vec4(0.3, 0.3, 0.3, 0), color, 0);
    }
	color.a = initial_color.a;

    COLOR = color;
}