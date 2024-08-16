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
    float roughness;
};

struct hit {
    float dist;
    vec3 normal;
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
            1.00000000000
        ); // copy mc sky color
}

// General sphere intersection function. Doesnt affect material. Returns bool, edits hit distance, normal data
// todo: add material shit cuz we dont want nested nodes.
bool addSphere(ray r, inout hit h, vec4 s) {
	vec3 m = r.origin - s.xyz;

	float b = dot(m, r.direction);
	float c = dot(m, m) - s.w * s.w;

	if (c > 0.0 && b > 0.0) return false;

	float d = b * b - c;

	if (d < 0.0) return false;
    
    bool fromInside = false;
	float dist = -b - sqrt(d);
    
    if (dist < 0.0) {
        fromInside = true;
        dist = -b + sqrt(d);
    }
    
	if (dist > MINDIST && dist < h.dist) {
        h.dist = dist;        
        h.normal = normalize((r.origin + r.direction * dist) - s.xyz) * (fromInside ? -1.0 : 1.0);
        return true;
    }
    
    return false;
}

void addPointLight(inout vec3 shade, hit h, vec3 pos, float intensity, vec3 color) { // directly ripped out of my 2-year old raytracer which was made by the help of UMSOEA
    vec3 col;
    vec3 vtol = pos - data.hit;
    float ld = length(vtol);
    vtol /= ld;

    if (h.dist < MAXDIST) {
        vec3 s = vec3(max(dot(data.n, vtol), 0.0) / (ld * ld));
        col = (ray(data.hit, vtol).d > ld ? s : vec3(0.0)) * intensity * color;
    }
    
    shade += col;
}

void sceneTrace(ray r, inout hit h) { // this intersection does affect material
    if (addSphere(r, h, vec4(0.0, 0.0, -3.0, 1.0))) {
        hit.m.albedo = vec3(1.0, 0.0, 0.0);
        hit.m.roughness = 0.5;
    }
}

vec3 shootRay(ray r) { // general raytracing color function. in main, return alpha 0 for sky if its in the first bounce for reflection.
    hit h;
    h.dist = MAXDIST; // start at max dist in case we dont hit anything

    sceneTrace(r, h) // do za intersections
}

vec3 calculateLighting(hit h) {
    
}

void main() {
    vec4 mc = texture(DiffuseSampler, texCoord * 2.0); // default mc

    vec3 uv = vec3((texCoord * 2.0) * 2.0 - 1.0, -1.0); // coords from -1 to 1  we need to multiply texCoord by 2 because we are writing to a buffer 2x the size
    uv.x *= 1920.0 / 1080.0; // correct aspect ratio
    
    ray r;
    r.origin = pos * -1.0;
    r.direction = normalize(uv) * mat3(mvmat);

    hit h;
    h.dist = MAXDIST;

    vec4 col;

    sceneTrace(r, h);
    col = vec4((h.normal + 1.0) * 0.5, 1.0);

    if (h.dist == MAXDIST) {
        col = sampleSky();
    };
    fragColor = col; // send raw raytracer to swap
}