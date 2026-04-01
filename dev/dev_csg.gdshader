shader_type spatial;

uniform float scale = 2.0;

varying vec3 world_pos;

void vertex() {
    world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
    vec3 pos = world_pos * scale;

    float checker = mod(floor(pos.x) + floor(pos.z), 2.0);

    vec3 color1 = vec3(1.0);
    vec3 color2 = vec3(0.0);

    ALBEDO = mix(color1, color2, checker);
}