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
    vec3 col = vec3(
            0.52156862745,
            0.67058823529,
            1.00000000000
        ); // copy mc sky color
    return pow(col, vec3(2.2));
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

    addSphere(r, h, vec4(-0.5, 6.5, -3.0, 1.0), material(vec3(1.0, 1.0, 1.0), 0.5));
    addSphere(r, h, vec4(0.9, 6.25, -3.5, 0.75), material(vec3(0.9, 0.1, 0.1), 0.2));
    addSphere(r, h, vec4(0.7, 5.9, -2.5, 0.4), material(vec3(0.1, 0.9, 0.1), 0.2));
    addPlane(r, h, 5.5, material(vec3(1.0, 1.0, 1.0), 1.0));

    //h.m.reflectivity = mix(pow(dot(h.normal, r.direction) + 1.0, 4.0) * (h.m.reflectivity > 0.01 ? 1.0 : 0.0), 1.0, h.m.reflectivity); // shitty fresnel

    return h;
}

void addPointLight(inout vec3 shade, ray r, hit h, vec4 l, vec3 color) { // passes like this have inout data   l.xyz is pos, l.w is intesnity
    vec3 point = hitPoint(r, h.dist);

    vec3 vectorToLight = l.xyz - point;
    float lightDistance = length(vectorToLight);
    vectorToLight /= lightDistance; // normalize  I do it this way to preserve lightDistance. its a shitty optimization but who tf cares

    vec3 lightness = vec3(max(dot(h.normal, vectorToLight), 0.0) / (lightDistance * lightDistance)); // woohoo inverse square law

    hit rayToLight = shootRay(ray(point, vectorToLight));
    vec3 col = (rayToLight.dist > lightDistance ? lightness : vec3(0.0)) * l.w * color; // cast shadow ray then multiply by intensity and color
    
    shade += col;
}

vec3 shadeHitData(ray r, hit h) { // we need the ray to calculate hit point, in the future calc hitpoiunt in the intersection as well as dist.
    vec3 shade;

    addPointLight(shade, r, h, vec4(2.7, 12.5, 0.3, 35.0), vec3(1.0, 0.9, 0.8));
    addPointLight(shade, r, h, vec4(-4.0, 9.0, -2.0, 3.0), vec3(0.6, 0.5, 0.9));

    shade *= h.m.albedo; // tint by albedo
    if (h.dist == MAXDIST) shade = sampleSky();

    return shade;
}

void main() {
    vec3 uv = vec3(texCoord * 2.0 - 1.0, -1.0); // coords from -1 to 1
    uv.x *= OutSize.x / OutSize.y; // correct aspect ratio
    
    ray r;
    r.origin = -pos; // dont FUCKING ask me why its inverted
    r.direction = normalize(uv) * mat3(mvmat); // is just a direction vector not changing with ro

    vec4 col = vec4(0.0, 0.0, 0.0, 1.0);

    // THE ALMIGHTY FUNCTION
    col.rgb = shadeHitData(r, shootRay(r));

    if (shootRay(r).dist == MAXDIST) { // sky alpha invisible if in main bounce
        col.a = 0.0;
    };
    fragColor = col; // send raw raytracer to swap
}