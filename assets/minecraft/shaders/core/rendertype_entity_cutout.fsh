#version 330

#moj_import <fog.glsl>

uniform sampler2D Sampler0;

uniform vec4 ColorModulator;
uniform float FogStart;
uniform float FogEnd;
uniform vec4 FogColor;

in float vertexDistance;
in vec4 vertexColor;
in vec4 lightMapColor;
in vec4 overlayColor;
in vec2 texCoord0;

out vec4 fragColor;

// pass view data well model and proj mat can just get from json (we dont encode projmat i dont fucking know why i included it)
uniform mat4 ModelViewMat;
uniform mat4 ProjMat;
in vec3 pos;

vec4 floatToChannels(float n) {
    int num = floatBitsToInt(n);
    return vec4(
        (num >> 24) & 0xff,
        (num >> 16) & 0xff,
        (num >>  8) & 0xff,
        (num      ) & 0xff
    ) / 255.0;
}

void plot(vec2 coord, float n, inout vec4 col) {
    col = gl_FragCoord.xy == coord + vec2(0.5) ? floatToChannels(n) : col; // fragcoord is 0.5 centered idk why
}

void main() {
    vec4 color = texture(Sampler0, texCoord0);
    
    if (ivec4(color * 255) == ivec4(12, 34, 56, 78)) {
        vec4 col = vec4(0.0);
        
        // plot mat to pixels 0-15
        for (int i = 0; i < 4; i++) { plot(vec2(i     , 0.0), ModelViewMat[i][0], col); }
        for (int i = 0; i < 4; i++) { plot(vec2(i + 4 , 0.0), ModelViewMat[i][1], col); }
        for (int i = 0; i < 4; i++) { plot(vec2(i + 8 , 0.0), ModelViewMat[i][2], col); }
        for (int i = 0; i < 4; i++) { plot(vec2(i + 12, 0.0), ModelViewMat[i][3], col); }
    
        // plot coordinates to pixels 16, 17, 18
        plot(vec2(0.0, 1.0), pos.x, col);
        plot(vec2(1.0, 1.0), pos.y, col);
        plot(vec2(2.0, 1.0), pos.z, col);

        plot(vec2(0.0, 2.0), ProjMat[1][1], col);

        fragColor = col;
    } else {
        if (color.a < 0.1) {
            discard;
        }
    
        color *= vertexColor * ColorModulator;
        color.rgb = mix(overlayColor.rgb, color.rgb, overlayColor.a);
        color *= lightMapColor;
        fragColor = linear_fog(color, vertexDistance, FogStart, FogEnd, FogColor);
    }
}
