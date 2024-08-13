#version 330

uniform sampler2D DiffuseSampler;

uniform vec4 ColorModulate;

uniform float MINDIST;
uniform float MAXDIST;

in vec2 texCoord;

out vec4 fragColor;

// pass in mvmat and pos
in mat4 mvmat;
in vec3 pos;

struct ray {
    vec3 origin;
    vec3 direction;
};

struct material {
    vec3 albedo;
    vec3 emissive;
    float percentSpecular;
    float roughness;
    vec3 specularColor;
    float ior;
};

struct hit {
    float dist;
    vec3 normal;
    material m;
};

vec4 floatToChannels(float n) {
    int num = floatBitsToInt(n);
    return vec4(
        (num >> 24) & 0xff,
        (num >> 16) & 0xff,
        (num >>  8) & 0xff,
        (num      ) & 0xff
    ) / 255.0;
}

vec4 sampleSky() {
    //vec2 p = floor(uv.xy * 30.0);
    //float patternMask = mod(p.x + mod(p.y, 2.0), 2.0); // checkerboard on transparent
    //col = patternMask * vec4(1.0, 1.0, 1.0, 0.0) + vec4(0.7, 0.7, 0.7, 0.0); // white is technically more than white
    return vec4(
            0.52156862745,
            0.67058823529,
            1.00000000000,
            0.00000000000
        ); // copy mc sky color
}

void sphereTrace(ray r, inout hit h, vec4 s) { // s.xyz is pos, s.w is radius
	vec3 m = r.origin - s.xyz;

	float b = dot(m, r.direction);
	float c = dot(m, m) - s.w * s.w;

	//if (c > 0.0 && b > 0.0) return false;

	float d = b * b - c;

	//if (d < 0.0) return false;
    
    bool fromInside = false;
	float dist = -b - sqrt(d);
    
    if (dist < 0.0) {
        fromInside = true;
        dist = -b + sqrt(d);
    }
    
	if (dist > MINDIST && dist < h.dist) {
        h.dist = dist;        
        h.normal = normalize((r.origin + r.direction * dist) - s.xyz) * (fromInside ? -1.0 : 1.0);
    //    return true;
    }
    
    //return false;
}

void sceneTrace(ray r, inout hit h) {
    sphereTrace(r, h, vec4(0.0, 0.0, -3.0, 1.0));
}

void main() {
    vec4 mc = texture(DiffuseSampler, texCoord); // default mc

    vec3 uv = vec3(texCoord * 2.0 - 1.0, -1.0); // coords from -1 to 1
    uv.x *= 1920.0 / 1080.0; // correct aspect ratio
    
    ray r;
    r.origin = pos * -1.0; // dont fucking ask me why its inverted
    r.direction = normalize(uv) * mat3(mvmat);

    hit h;
    h.dist = MAXDIST;

    vec4 col;

    sceneTrace(r, h);
    col = vec4((h.normal + 1.0) * 0.5, 1.0);

    if (h.dist == MAXDIST) col = sampleSky();

    float channel = mod(gl_FragCoord.x, 2.0) + mod(gl_FragCoord.y, 2.0) * 2.0; // thx for this dom and Raccoon
    if (channel == 0.0) fragColor = floatToChannels(col.r); // encode tha shit
    if (channel == 1.0) fragColor = floatToChannels(col.g);
    if (channel == 2.0) fragColor = floatToChannels(col.b);
    if (channel == 3.0) fragColor = floatToChannels(col.a);
}