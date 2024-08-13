#version 150

#moj_import <light.glsl>
#moj_import <fog.glsl>

in vec3 Position;
in vec4 Color;
in vec2 UV0;
in ivec2 UV1;
in ivec2 UV2;
in vec3 Normal;

uniform sampler2D Sampler0;
uniform sampler2D Sampler1;
uniform sampler2D Sampler2;

uniform mat4 ModelViewMat;
uniform mat4 ProjMat;
uniform int FogShape;

uniform vec3 Light0_Direction;
uniform vec3 Light1_Direction;

out float vertexDistance;
out vec4 vertexColor;
out vec4 lightMapColor;
out vec4 overlayColor;
out vec2 texCoord0;

// pass pos this counts as defining it too ***
out vec3 pos;

vec2[] corners = vec2[](
    vec2(0.0, 1.0),
    vec2(0.0, 0.0),
    vec2(1.0, 0.0),
    vec2(1.0, 1.0)
);

void main() {
    gl_Position = ProjMat * ModelViewMat * vec4(Position, 1.0);

    vertexDistance = fog_distance(Position, FogShape);
    vertexColor = minecraft_mix_light(Light0_Direction, Light1_Direction, Normal, Color);
    lightMapColor = texelFetch(Sampler2, UV2 / 16, 0);
    overlayColor = texelFetch(Sampler1, UV1, 0);
    texCoord0 = UV0;

    if (ivec4(texture(Sampler0, UV0) * 255) == ivec4(12, 34, 56, 78)) {
        vec2 cornerpos = vec2(0.0, 0.0);
        cornerpos += corners[gl_VertexID % 4];
        cornerpos.x *= 0.05;
        cornerpos.y *= 0.02;
        cornerpos.x /= 1920.0 / 1080.0;

        gl_Position = vec4(cornerpos * 2.0 - 1.0, 0.0, 1.0); // turn cornerpos (0 to 1) to position space (-1 to 1)
        pos = Position;
    }
}
