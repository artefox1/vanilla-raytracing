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
    vec4 mc  = texture(DefaultSampler, texCoord); // default mc
    vec4 col = texture(DiffuseSampler, texCoord); // raytracer
    fragColor = vec4(mix(mc.rgb, col.rgb, col.a), 1.0); // blend the shader with mc
}