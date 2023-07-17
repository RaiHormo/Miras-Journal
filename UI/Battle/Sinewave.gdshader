shader_type canvas_item; 
render_mode unshaded;

uniform float circle_size= 0.55;
uniform float circle_thickness= 0.005;

uniform float sine_freq=25.0;
uniform float sine_amp=0.03;
uniform float sine_phase=1.0;

void fragment() {
    vec2 uv = UV * 2.0 - 1.0;
    // Take the sin of the angle times some amount to get the bumps 
    float sine_wave = sin(atan(uv.y, uv.x) * sine_freq + sine_phase*TIME*20.0) * sine_amp;
    
    // Circle distance field
    float circle = abs(length(uv) + sine_wave - circle_size) - circle_thickness;
    
    // Smoothstep the circle to get aa
    circle = smoothstep(fwidth(circle), 0.0, circle);
    
    // Cut out
    COLOR.a = circle;
}