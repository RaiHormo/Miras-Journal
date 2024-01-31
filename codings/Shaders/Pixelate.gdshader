shader_type canvas_item;
render_mode unshaded;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

uniform sampler2D TextureMap;
uniform int NumDivisions = 32;

void fragment()
{
	vec4 c = textureLod(screen_texture, SCREEN_UV, 0.0);

    if (c.a > 0.0001) {
        c.rgb /= c.a;
    }

    COLOR *= c;
    // quantize the UV value to a stepped value
    // based on number of divisions.
    // the 0.5 added ensures we sample from
    // the centre of the "pixel"
    vec2 st = (vec2(ivec2( UV * float(NumDivisions) ))+0.5)/float(NumDivisions);
    // read the texture using the highest LOD to avoid
    // filtering problems on discontinuities

    vec4 tex_col = textureLod(TextureMap, st, 0 );
    // set the output
    COLOR = tex_col;


}
