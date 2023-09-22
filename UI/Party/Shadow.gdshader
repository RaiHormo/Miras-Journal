shader_type canvas_item;
render_mode blend_mix;

uniform float radius = 4.0;
uniform bool black_out = false;
uniform float alpha : hint_range(0, 1) = 1;

void fragment() {
    vec4 col = texture(TEXTURE, UV);
    vec2 ps = TEXTURE_PIXEL_SIZE;

    int div = 1;
    
    for (float x = -radius; x <= radius; x++){
        for (float y = -radius; y <= radius; y++){
                col += texture(TEXTURE, UV + vec2(x, y) * ps);
                col += texture(TEXTURE, UV + vec2(-x, -y) * ps);
                col += texture(TEXTURE, UV + vec2(x, -y) * ps);
                col += texture(TEXTURE, UV + vec2(-x, y) * ps);
                div += 4;
        }
    }
    col = col / float(div);
    if (black_out) {col.rgb = vec3(0, 0, 0);}
    
    COLOR = vec4(0, 0, 0, col.a * alpha);
}
