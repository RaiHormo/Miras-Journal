shader_type canvas_item;

uniform vec4 prev_color: source_color = vec4(1.0);
uniform vec4 new_color: source_color = vec4(0.0, 0.0, 0.0, 1.0);

void fragment() {
    vec4 color = texture(TEXTURE, UV);
	
    if (color == prev_color) {
		vec4 initial_color = color;
		color = mix(new_color, color, 0);
		color.a = initial_color.a;
    }

    COLOR = color;
}