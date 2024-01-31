shader_type canvas_item;
render_mode blend_mix;

uniform float radius = 4.0;
uniform int steps = 32;
uniform float vertex_expand = 2.0;

mat2 rotationMatrix(float angle){
	angle *= PI / 180.0;
	float s = sin(angle);
	float c = cos(angle);
	return mat2( vec2(c, -s), vec2( s, c) );
}

void vertex() {
	VERTEX.x *= vertex_expand;
	VERTEX.y *= vertex_expand;
}

void fragment() {
	float uvx = UV.x * vertex_expand - vertex_expand/2.0 + 0.5;
	float uvy = UV.y * vertex_expand - vertex_expand/2.0 + 0.5;
	vec2 new_uv = vec2(uvx,uvy);
	vec4 col = texture(TEXTURE, new_uv);
	float angle = 360.0 / float(steps);
	for (int i = 0; i < steps; i++){
		col += texture(TEXTURE, new_uv + vec2(radius, 0.0) * rotationMatrix(angle*float(i)) * TEXTURE_PIXEL_SIZE);
	}
	col /= float(steps) + 1.0;
	COLOR = col;
}