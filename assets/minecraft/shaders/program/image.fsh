#version 150

uniform sampler2D DefaultSampler;
uniform sampler2D DiffuseSampler;

uniform vec4 ColorModulate;

uniform float MINDIST;
uniform float MAXDIST;

in vec2 texCoord;

out vec4 fragColor;

void main() {
    vec4 mc  = texture(DefaultSampler, texCoord); // default mc
    
    vec4 col = texture(DiffuseSampler, texCoord); // raytracer
    col.rgb = pow(col.rgb, vec3(1.0 / 2.2)); // convert to srgb (very simple and likely wrong but i dont care)

    fragColor = vec4(mix(mc.rgb, col.rgb, col.a), 1.0); // blend the shader with mc
}