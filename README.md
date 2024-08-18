# Vanilla Shader Raytracing in Minecraft 1.21
Credit to [Godlander](https://github.com/Godlander/raytracing) and d for the concept of passing core values into post shaders. Scroll down below for the extended credits.

![1](https://github.com/user-attachments/assets/6c65f8c0-3c9d-48ce-90b7-de4070d58833)

![2024-08-17_15 50 22](https://github.com/user-attachments/assets/9975dd17-fc12-473e-bf5d-0b310ebe3654)

https://github.com/user-attachments/assets/00238f7b-3979-4010-99d2-4dcd30760003

The core shader transforms the vertices of an item display to cover a small portion of the screen, then encodes a couple of variables to the texture such as the view matrix and position. Since each fragment has 8-bit RGBA color channels, we can encode one 32-bit float per pixel. Then, the post shader decodes the buffer and passes it to the fragment post shader to do the raytracing.

## Usage
The shader uses an `item_display` as a mud block to get the core values. To run the shader at world origin, simply run:
```mcfunction
summon item_display 0.0 0 0.0 {item:{id:"minecraft:mud"}}
```

It's also recommended to set the time to midnight
```mcfunction
gamerule doDaylightCycle false
time set midnight
```

# Editing files
## Core shaders
All of the core shaders are located in `shaders/core`.
### Vertex shader
Vertex transformations are written in `core/rendertype_entity_cutout.vsh`.

For example, to scale the region where the vertices are mapped to, simply edit:
```glsl
cornerpos.x *= 0.05; // scale x axis by 0.05
cornerpos.y *= 0.02; // scale y axis by 0.02
```
### Fragment shader
Encoding the variables to colors is done in `core/rendertype_entity_cutout.fsh`.

To encode your own data, you can use the included `plot()` function. If your data is in the vertex shader, you can pass it in using the `in` and `out` qualifiers. Note that this function does not return a value, and you must input the color you want to edit. Here is an example:
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
The code for decoding color data is in `program/render.vsh`. To decode data, use the `dec()` function. Unlike the encoding function in core, this function **does** return a value. Note that texture coordinates here use `ivec2` instead of `vec2`. Here’s how it works:
```glsl
out vec4 data;
data.x = dec(ivec2(0, 1)); // decode (0, 1) to data.x
data.y = dec(ivec2(1, 1)); // decode (1, 1) to data.y
data.z = dec(ivec2(2, 1)); // decode (2, 1) to data.z
data.w = dec(ivec2(3, 1)); // decode (3, 1) to data.w
```
### Fragment shader
All of the raytracing is actually written in `program/render.fsh`. You can replace this with your own fragment shader like a raymarcher, or you can edit the default raytracer.

To edit the current scene, you can use one of the intersection functions within the `shootRay()` function. Intersection functions typically require position data and material data. Some functions store different kinds of data in the same vec4 to conserve space. For example, sphere intersections use `vec4.xyz` for position coordinates and `vec4.w` for radius. Currently, the material struct is defined as:
```glsl
struct material {
    vec4 albedo;        // albedo (color) defined as vec4 to support invisible materials
    float reflectivity; // reflectivity amount defined from 0.0 - 1.0
};
```

The default scene looks like this:
```glsl
//              Position and Radius              Albedo and Reflectivity
addSphere(r, h, vec4(-0.5,  6.5,  -3.0, 1.0 ),   material(vec4(1.0, 1.0, 1.0, 1.0), 0.4 ));
addSphere(r, h, vec4( 0.9,  6.25, -3.5, 0.75),   material(vec4(0.9, 0.1, 0.1, 1.0), 0.05));
addSphere(r, h, vec4( 0.7,  5.9,  -2.5, 0.4 ),   material(vec4(0.1, 0.9, 0.1, 1.0), 0.1 ));

//             Plane height   Albedo and Reflectivity
addPlane(r, h, 5.5,           material(vec4(0.5, 0.5, 0.6, 0.0), 0.8)); // 0 alpha which results in an invisible shadow caster
```

To add lights, use `addPointLight()` which is located in the `shadeHitData()` function. The default lighting scene looks like:
```glsl
//                         Position and Intensity        Color
addPointLight(shade, r, h, vec4( 2.7, 12.5, -1.0, 35.0), vec4(1.0, 0.9, 0.8, 1.0));
addPointLight(shade, r, h, vec4(-4.0, 9.0,  -2.0, 3.0 ), vec4(0.6, 0.5, 0.9, 1.0));
```

The raytracer then gets passed into `program/image.fsh`. This is where any color transformations such as tonemapping take place, and it's the image that gets shown on the final buffer.

To overlay the raytracer on the minecraft buffer, I used the `mix()` function to lerp along the `alpha` channel.
```glsl
vec4 mc    = texture(DefaultSampler, texCoord); // default minecraft buffer
vec4 color = texture(DiffuseSampler, texCoord); // overlay shader

mix(mc.rgb, color.rgb, color.a);                // blend the shader with minecraft
```

# Credits
Godlander

d (DerDiscohund)

Dominexis

umsoea

Onnowhere
