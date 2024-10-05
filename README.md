# Vanilla Shader Raytracing in Minecraft 1.21
Credit to [Godlander](https://github.com/Godlander/raytracing) and d for the concept of passing core values into post shaders. Scroll down below for screenshots.

https://github.com/user-attachments/assets/1d20e644-4acb-49f8-a567-e5870a53e1b4

## Usage
This resource pack requires the *Fabulous!* graphics setting, and View Bobbing turned off in order to work properly.

![better fabulous](https://github.com/user-attachments/assets/ac56a580-5ed1-4a8c-8b26-a2b43e726239)
![better view bobbing](https://github.com/user-attachments/assets/809d62c8-4185-435a-b42a-68154e395dbc)

The shader uses an `item_display` as a mud block to get the core values. To run the shader at world origin, simply run:
```mcfunction
summon item_display 0.0 0 0.0 {item:{id:"minecraft:mud"}}
```

It's also recommended to set the time to midnight:
```mcfunction
gamerule doDaylightCycle false
time set midnight
```

# Editing files
The core shader transforms the vertices of an item display to cover a small portion of the screen (bottom left corner), then encodes a couple of variables to the texture such as the view matrix and position. Since each fragment has 8-bit RGBA color channels, we can encode one 32-bit float per pixel. Then, the post shader decodes the buffer and passes it to the fragment post shader to do the raytracing.
## Core shaders
All of the core shaders are located in `shaders/core`.
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

# Screenshots
![1](https://github.com/user-attachments/assets/6c65f8c0-3c9d-48ce-90b7-de4070d58833)

![2024-08-17_15 41 42](https://github.com/user-attachments/assets/151befb3-eb57-4326-9e8b-eceadc8485b8)

![2024-08-17_15 50 22](https://github.com/user-attachments/assets/9975dd17-fc12-473e-bf5d-0b310ebe3654)

![2024-08-17_02 09 23](https://github.com/user-attachments/assets/c51493b3-4bea-49c0-876c-e00a32fd95df)

![2024-08-14_16 26 16](https://github.com/user-attachments/assets/9aa7e029-1ed6-487a-b103-d2f167feacc9)

![2024-08-18_13 29 02](https://github.com/user-attachments/assets/e12a3c5c-be23-4bc4-8034-1dd8fa342c98)

https://github.com/user-attachments/assets/1132ca1d-f0e0-47d7-b76e-f6dc681d53c2

https://github.com/user-attachments/assets/00238f7b-3979-4010-99d2-4dcd30760003
