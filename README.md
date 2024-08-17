# Vanilla Shader Raytracing in Minecraft 1.21
Credit to [Godlander](https://github.com/Godlander/raytracing) and d for the concept of passing core values into post shaders. Scroll down below for the extended credits.

https://github.com/user-attachments/assets/00238f7b-3979-4010-99d2-4dcd30760003

The core shader transforms the vertices of the item display to cover a small portion of the screen, then encodes a couple of variables to the texture such as the view matrix and position. Since each fragment has 8-bit RGBA color channels, we can encode one 32-bit float per pixel. Then, the post shader decodes the buffer and passes it to the fragment post shader to do the raytracing.

## Usage
The shader uses an `item_display` as a mud block to get the core values. To run the shader at world origin, simply run
```mcfunction
summon item_display 0.0 0 0.0 {item:{id:"minecraft:mud"}}
```

# Editing files
## Core shaders
All of the core shaders are located in `shaders/core`.
### Vertex shader
Vertex transformations are written in  `core/rendertype_entity_cutout.vsh`.

For example, if you wanted to scale the region where the vertices are mapped to, simply edit:
```glsl
cornerpos.x *= 0.05; // scale x axis by 0.05
cornerpos.y *= 0.02; // scale y axis by 0.02
```
### Fragment shader
Encoding the variables to colors is written all in `core/rendertype_entity_cutout.fsh`.

To encode your own data, you'd probably want to use the included `plot()` function. Your data might be in the vertex shader, so simply pass it in using the `in` and `out` qualifiers. Keep in mind that the function does not return a value, and you must input the color value that you want to edit. Here is an example:
```glsl
in vec4 data;
plot(vec2(0.0, 1.0), data.x, col); // encode data.x to (0, 1) on the screen
plot(vec2(1.0, 1.0), data.y, col); // encode data.y to (1, 1) on the screen
plot(vec2(2.0, 1.0), data.z, col); // encode data.z to (2, 1) on the screen
plot(vec2(3.0, 1.0), data.w, col); // encode data.w to (3, 1) on the screen
```

## Post shaders
The post shaders are located in `shaders/program`.
### Vertex shader
The code for decoding color data is located in `program/render.vsh`.

To decode data, use the `dec()` function. Unlike the encoding function in `core`, this function **does** return a value. Another inconsistency is that the texture coordinates here uses `ivec2` instead of `vec2`. It's not my biggest concern to fix this.
```glsl
out vec4 data;
data.x = dec(ivec2(0, 1)); // decode (0, 1) to data.x
data.y = dec(ivec2(1, 1)); // decode (1, 1) to data.y
data.z = dec(ivec2(2, 1)); // decode (2, 1) to data.z
data.w = dec(ivec2(3, 1)); // decode (3, 1) to data.w
```
### Fragment shader
All of the raytracing is actually written in `program/render.fsh`.

To edit object data, use one of the intersection functions in the `shootRay()` function. The intersection functions require data like positions and a `material`. As of now, `material` structs consists of `vec4 albedo` and `float reflectivity`. The default scene looks like this:
```glsl
// addSphere(ray r, hit h, vec4 s, material m) - s.xyz is position, s.w is radius
addSphere(r, h, vec4(-0.5, 6.5, -3.0, 1.0), material(vec4(1.0, 1.0, 1.0, 1.0), 0.5));  // white sphere of 1.0 radius and 0.5 reflectivity
addSphere(r, h, vec4(0.9, 6.25, -3.5, 0.75), material(vec4(0.9, 0.1, 0.1, 1.0), 0.2)); // red sphere of 0.75 radius and 0.2 reflectivity
addSphere(r, h, vec4(0.7, 5.9, -2.5, 0.4), material(vec4(0.1, 0.9, 0.1, 1.0), 0.2));   // green sphere of 0.4 radius and 0.2 reflectivity

// addPlane(ray r, hit h, float y, material m) - y is plane height
addPlane(r, h, 5.5, material(vec4(1.0, 1.0, 1.0, 0.0), 1.0)); // plane at Y = 5.5, 1 reflectivity and 0 alpha, which results in an invisible shadow caster
```

To add lights, use `addPointLight()` which is located in the `shadeHitData()` function. The default lighting scene looks like:
```glsl
// addPointLight(vec4 shade, ray r, hit h, vec4 l, vec4 color) - l.xyz is position, l.w is intensity
addPointLight(shade, r, h, vec4(2.7, 12.5, 0.3, 35.0), vec4(1.0, 0.9, 0.8, 1.0)); // warm light with 35 intensity
addPointLight(shade, r, h, vec4(-4.0, 9.0, -2.0, 3.0), vec4(0.6, 0.5, 0.9, 1.0)); // blue light with 3 intensity
```

The raytracer then gets passed into `program/image.fsh`. This is where any color transformations such as tonemapping take place, and it's the image that gets shown on the final buffer.

To overlay the raytracer on the minecraft buffer, I used the `mix()` function to lerp along the `alpha` channel.
```glsl
vec4 mc = texture(DiffuseSampler, texCoord); // default minecraft buffer
vec4 color;                                  // overlay shader
mix(mc.rgb, color.rgb, color.a);             // blend the shader with minecraft
```

# Credits
[Godlander](https://github.com/Godlander/raytracing) for the idea of decoding view data in the vertex shader

d (DerDiscohund) for explaining the whole concept of passing core shader values into the post shader

Dominexis for some of the encoding code

UMSOEA for explaining raytracing and some intersection functions