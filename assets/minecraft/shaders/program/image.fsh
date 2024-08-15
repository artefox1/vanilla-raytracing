#version 330

//uniform sampler2D DefaultSampler;
uniform sampler2D DiffuseSampler;

uniform vec4 ColorModulate;

uniform float MINDIST;
uniform float MAXDIST;

in vec2 texCoord;

out vec4 fragColor;

float channelsToFloat(vec4 n) { // decoder
    ivec4 num = ivec4(n * 255.0);
    return intBitsToFloat(
        (num.r << 24) + 
        (num.g << 16) + 
        (num.b << 8 ) + 
        (num.a      )
    );
}

//float dec(ivec2 relative) {
//    return channelsToFloat(texelFetch(DiffuseSampler, ivec2(gl_FragCoord.xy) * 2 + relative, 0));
//}

void main() {
    //vec4 mc  = texture(DefaultSampler, texCoord); // default mc

    vec4 col = vec4(
        channelsToFloat(texelFetch(DiffuseSampler, ivec2(gl_FragCoord.xy - 0.5) * 2 + ivec2(0, 0), 0)), // bottom left
        channelsToFloat(texelFetch(DiffuseSampler, ivec2(gl_FragCoord.xy - 0.5) * 2 + ivec2(1, 0), 0)), // bottom right
        channelsToFloat(texelFetch(DiffuseSampler, ivec2(gl_FragCoord.xy - 0.5) * 2 + ivec2(0, 1), 0)), // top left
        channelsToFloat(texelFetch(DiffuseSampler, ivec2(gl_FragCoord.xy - 0.5) * 2 + ivec2(1, 1), 0))  // top right
    ); // raytracer
    //vec4 col = texelFetch(DiffuseSampler, ivec2(gl_FragCoord.xy - 0.5), 0);
    //vec4 col = texture(DiffuseSampler, texCoord);
    fragColor = vec4(vec3(col), 1.0);
    //fragColor = vec4(mix(mc.rgb, col.rgb, col.a), 1.0); // blend the shader with mc
}