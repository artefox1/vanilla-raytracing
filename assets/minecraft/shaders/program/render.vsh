#version 330

in vec4 Position;

uniform mat4 ProjMat;
uniform vec2 OutSize;

out vec2 texCoord;

// pass our passed data to fsh
out mat4 mvmat;
out vec3 pos;
out float focal;

// we need the sampler too
uniform sampler2D DiffuseSampler;

float channelsToFloat(vec4 n) {
    ivec4 num = ivec4(n * 255.0);
    return intBitsToFloat(
        (num.r << 24) + 
        (num.g << 16) + 
        (num.b << 8 ) + 
        (num.a      )
    );
}

float dec(ivec2 coord) {
    return channelsToFloat(texelFetch(DiffuseSampler, coord, 0));
}

void main(){

    // decode mat 0-15 dont fucking ask me why i cant use for loops the screen turns black
    //for (int i = 0; i < 4; i++) { mvmat[i][0] = dec(ivec2(i     , 0)); }
    mvmat[0][0] = dec(ivec2(0 , 0));
    mvmat[1][0] = dec(ivec2(1 , 0));
    mvmat[2][0] = dec(ivec2(2 , 0));
    mvmat[3][0] = dec(ivec2(3 , 0));
    mvmat[0][1] = dec(ivec2(4 , 0));
    mvmat[1][1] = dec(ivec2(5 , 0));
    mvmat[2][1] = dec(ivec2(6 , 0));
    mvmat[3][1] = dec(ivec2(7 , 0));
    mvmat[0][2] = dec(ivec2(8 , 0));
    mvmat[1][2] = dec(ivec2(9 , 0));
    mvmat[2][2] = dec(ivec2(10, 0));
    mvmat[3][2] = dec(ivec2(11, 0));
    mvmat[0][3] = dec(ivec2(12, 0));
    mvmat[1][3] = dec(ivec2(13, 0));
    mvmat[2][3] = dec(ivec2(14, 0));
    mvmat[3][3] = dec(ivec2(15, 0));

    // decode coordinates 16, 17, 18
    pos.x = channelsToFloat(texelFetch(DiffuseSampler, ivec2(0, 1), 0));
    pos.y = channelsToFloat(texelFetch(DiffuseSampler, ivec2(1, 1), 0));
    pos.z = channelsToFloat(texelFetch(DiffuseSampler, ivec2(2, 1), 0));

    focal = channelsToFloat(texelFetch(DiffuseSampler, ivec2(0, 2), 0));

    vec4 outPos = ProjMat * vec4(Position.xy, 0.0, 1.0);
    gl_Position = vec4(outPos.xy, 0.2, 1.0);

    texCoord = Position.xy / OutSize;
}
