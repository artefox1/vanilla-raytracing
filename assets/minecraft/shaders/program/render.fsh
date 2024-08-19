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
in float focal;

struct ray {
    vec3 origin;
    vec3 direction;
};

struct material {
    vec4 albedo; // OMG 4 CHANNELS LETS GOOOOOOOOOOOOOOO
    float reflectivity;
};

struct hit {
    float dist;
    vec3 normal;
    material m;
};

vec4 sampleSky() {
    //vec2 p = floor(uv.xy * 30.0);
    //float patternMask = mod(p.x + mod(p.y, 2.0), 2.0); // checkerboard on transparent
    //col = patternMask * vec4(1.0, 1.0, 1.0, 0.0) + vec4(0.7, 0.7, 0.7, 0.0); // white is technically more than white
    //vec4 col = vec4(
    //        0.52156862745,
    //        0.67058823529,
    //        1.00000000000,
    //        0.00000000000
    //    ); // copy mc sky color
    vec4 col = vec4(
        0.03921568627,
        0.04705882352,
        0.08235294117,
        0.00000000000
    );
    col.rgb = pow(col.rgb, vec3(2.2)); // transform to linear space
    return col;
}

vec3 hitPoint(ray r, float dist) {
    return (r.direction * dist) + r.origin;
}

// General sphere intersection function. Affects material to not have nested functions. edits hit metadata  s.xyz is position, s.w is radius
void addSphere(ray r, inout hit h, vec4 s, material m) {
	vec3 pos = r.origin - s.xyz;

	float b = dot(pos, r.direction);
	float c = dot(pos, pos) - s.w * s.w;

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
        h.m.albedo = m.albedo;
        h.m.reflectivity = m.reflectivity;
        //return true;
    }
    
    //return false;
}

// general XZ plane
void addPlane(ray r, inout hit h, float y, material m) { // y is height
    float dist = (r.origin.y - y) / -r.direction.y;

    if (dist > MINDIST && dist < h.dist) {
        h.dist = dist;
        h.normal = vec3(0.0, 1.0, 0.0); // normal straight up
        h.m.albedo = m.albedo;
        h.m.reflectivity = m.reflectivity;
    }
}

hit shootRay(ray r) { // general raytracing color function. does not shade anything.
    hit h;
    h.dist = MAXDIST; // start at max dist in case we dont hit anything

    addSphere(r, h, vec4(-0.5, 6.5, -3.0, 1.0), material(vec4(1.0, 1.0, 1.0, 1.0), 0.4));
    addSphere(r, h, vec4(0.9, 6.25, -3.5, 0.75), material(vec4(0.9, 0.1, 0.1, 1.0), 0.05));
    addSphere(r, h, vec4(0.7, 5.9, -2.5, 0.4), material(vec4(0.1, 0.9, 0.1, 1.0), 0.1));
    addPlane(r, h, 5.5, material(vec4(0.5, 0.5, 0.6, 0.0), 0.8));

    h.m.reflectivity = mix(min(pow(dot(h.normal, r.direction) + 1.0, 4.0) * (h.m.reflectivity > 0.01 ? 1.0 : 0.0), 0.0), 1.0, h.m.reflectivity); // shitty fresnel and clamp to 0 for some reason

    return h;
}

void addPointLight(inout vec4 shade, ray r, hit h, vec4 l, vec4 color) { // passes like this have inout data (thanks for UMSOEA for explaining this to me like 2 years ago)  l.xyz is pos, l.w is intesnity
    vec4 ambient = vec4(0.02);
    vec3 point = hitPoint(r, h.dist);

    vec3 vectorToLight = l.xyz - point;
    float lightDistance = length(vectorToLight);
    vectorToLight /= lightDistance; // normalize  I do it this way to preserve lightDistance. its a shitty optimization but who tf cares

    // shading part
    float lightness = max(dot(h.normal, vectorToLight), 0.0); // 1d lightness
    vec4 lighting = vec4((lightness + ambient) / (lightDistance * lightDistance)); // 4d lightness with inverse square law

    // cast shadow ray then multiply by intensity and color
    hit rayToLight = shootRay(ray(point, vectorToLight)); // actual distance to light (could get obstructed)
    lighting *= rayToLight.dist > lightDistance ? vec4(1.0) : vec4(vec3(ambient), 1.0); // we want the shadow visible but not shadin
    vec4 col = lighting * vec4(l.w) * color; // lighting is 4d
    
    shade += col;
}

vec4 shadeHitData(ray r, hit h) { // we need the ray to calculate hit point, in the future calc hitpoiunt in the intersection as well as dist.
    vec4 shade;

    addPointLight(shade, r, h, vec4(2.7, 12.5, -1.0, 35.0), vec4(1.0, 0.9, 0.8, 1.0));
    addPointLight(shade, r, h, vec4(-4.0, 9.0, -2.0, 3.0), vec4(0.6, 0.5, 0.9, 1.0));

    shade.rgb *= h.m.albedo.rgb; // tint by albedo
    shade.a   += h.m.albedo.a;   // ADD alpha

    if (h.dist == MAXDIST) shade = sampleSky();

    return shade;
}

vec4 getColor(ray r, inout hit h) {
    h = shootRay(r);
    return shadeHitData(r, h);
}

void main() {
    vec3 uv = vec3(texCoord * 2.0 - 1.0, -focal); // coords from -1 to 1
    uv.x *= OutSize.x / OutSize.y; // correct aspect ratio
    
    ray r;
    r.origin = -pos; // dont FUCKING ask me why its inverted
    r.direction = normalize(uv) * mat3(mvmat); // is just a direction vector not changing with ro

    vec4 col;
    hit h;

    float reflectivity;

    col = getColor(r, h);
    reflectivity = h.m.reflectivity;
    col = mix(col, getColor(ray(hitPoint(r, h.dist), reflect(r.direction, h.normal)), h), reflectivity);
    
    col.a = 1.0;
    vec4 main = getColor(r, h);
    col.a = main.a; // only use alpha if in main bounce

    fragColor = col; // send raw raytracer to swap
}