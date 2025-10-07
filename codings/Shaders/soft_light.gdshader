shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture;

// Soft light blend mode function
vec4 soft_light(vec4 base, vec4 blend) {
    vec4 limit = step(0.5, blend);
    return mix(2.0 * base * blend + base * base * (1.0 - 2.0 * blend), sqrt(base) * (2.0 * blend - 1.0) + (2.0 * base) * (1.0 - blend), limit);
}

void fragment() {
    vec4 baseColor = texture(TEXTURE, UV);
    vec4 screenColor = texture(SCREEN_TEXTURE, SCREEN_UV); // Sample the screen texture
    COLOR = soft_light(baseColor, screenColor); // Use screen color as blend color
}