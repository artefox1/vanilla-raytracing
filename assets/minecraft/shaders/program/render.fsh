#version 150

uniform sampler2D DiffuseSampler;

uniform vec4 ColorModulate;

uniform float MINDIST;
uniform float MAXDIST;

uniform vec2 OutSize; // get resolution

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
    float reflectivity;
};

struct hit {
    float dist;
    vec3 normal;
    material m;
};

vec3 sampleSky() {
    //vec2 p = floor(uv.xy * 30.0);
    //float patternMask = mod(p.x + mod(p.y, 2.0), 2.0); // checkerboard on transparent
    //col = patternMask * vec4(1.0, 1.0, 1.0, 0.0) + vec4(0.7, 0.7, 0.7, 0.0); // white is technically more than white
    return vec3(
            0.52156862745,
            0.67058823529,
            1.00000000000
        ); // copy mc sky color
}

vec3 hitPoint(ray r, float dist) {
    return r.direction * dist + r.origin;
}

// General sphere intersection function. Affects material to not have nested functions. edits hit metadata
void addSphere(ray r, inout hit h, vec4 s, vec3 albedo, float reflectivity) {
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
        dist = -b + sqrt(d); // other quadratic solution
    }
    
	if (dist > MINDIST && dist < h.dist) { // hit passed, change hit metadata
        h.dist = dist;        
        h.normal = normalize((r.origin + r.direction * dist) - s.xyz) * (fromInside ? -1.0 : 1.0); // flip if inside (I ripped this out of my old path tracer. I don't know why I invert it. THeres probably a good reason.)
        h.m.albedo = albedo;
        h.m.reflectivity = reflectivity;
        //return true;
    }
    
    //return false;
}

hit sceneTrace(ray r) { // trying no void to be consistent with shadehitdata
    hit h;
    addSphere(r, h, vec4(0.0, 0.0, -3.0, 1.0), vec3(1.0, 0.0, 0.3), 0.5);
    addSphere(r, h, vec4(0.3, 0.0, -2.0, 1.0), vec3(0.2, 0.2, 1.0), 0.2);
    return h;
}

hit shootRay(ray r) { // general raytracing color function. does not shade anything.
    hit h;
    h.dist = MAXDIST; // start at max dist in case we dont hit anything

    h = sceneTrace(r); // do za intersections

    //h.m.reflectivity = mix(pow(dot(h.normal, r.direction) + 1.0, 4.0) * (h.m.reflectivity > 0.01 ? 1.0 : 0.0), 1.0, h.m.reflectivity);

    return h;
}

void addPointLight(inout vec3 shade, ray r, hit h, vec4 l, vec3 color) { // passes like this have inout data   l.xyz is pos, l.w is intesnity
    vec3 vectorToLight = l.xyz - hitPoint(r, h.dist);
    float lightDistance = length(vectorToLight);
    vectorToLight /= lightDistance; // normalize

    vec3 s = vec3(max(dot(h.normal, vectorToLight), 0.0) / (lightDistance * lightDistance)); // woohoo inverse square law
    vec3 col = (shootRay(ray(hitPoint(r, h.dist), vectorToLight)).dist > lightDistance ? s : vec3(0.0)) * l.w * color; // cast shadow ray then multiply by intensity and color
    
    shade += col;
}

vec3 shadeHitData(ray r, hit h) { // we need the ray to calculate hit point
    vec3 shade;
    addPointLight(shade, r, h, vec4(0.5, 3.0, -2.5, 10.0), vec3(0.5, 1.0, 0.5));

    shade *= h.m.albedo;
    if (h.dist == MAXDIST) shade = sampleSky();

    return shade; // tint by albedo
}

void main() {
    vec4 mc = texture(DiffuseSampler, texCoord); // default mc

    vec3 uv = vec3(texCoord * 2.0 - 1.0, -1.0); // coords from -1 to 1
    uv.x *= OutSize.x / OutSize.y; // correct aspect ratio
    
    ray r;
    r.origin = pos * -1.0;
    r.direction = normalize(uv) * mat3(mvmat); // is just a direction vector not changing with ro

    vec4 col = vec4(0.0, 0.0, 0.0, 1.0);
    col.rgb = shadeHitData(r, shootRay(r));

    if (shootRay(r).dist == MAXDIST) { // sky alpha invisible if in main bounce
        col.a = 0.0;
    };

    fragColor = col; // send raw raytracer to swap
}