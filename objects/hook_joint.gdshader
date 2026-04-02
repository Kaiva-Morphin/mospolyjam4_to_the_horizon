shader_type spatial;
render_mode unshaded, cull_disabled;

uniform float rotation_speed = 1.0;
uniform sampler2D tex;
void vertex() {
    // --- Billboard (смотрит на камеру) ---
    mat4 view = INV_VIEW_MATRIX;
    
    vec3 cam_right = vec3(view[0][0], view[1][0], view[2][0]);
    vec3 cam_up    = vec3(view[0][1], view[1][1], view[2][1]);
    vec3 center = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;

    vec3 local_pos = VERTEX;

    // --- Rotation вокруг Y ---
    float angle = TIME * rotation_speed;
    float s = sin(angle);
    float c = cos(angle);

    mat2 rot = mat2(vec2(c, -s), vec2(s, c));
    local_pos.xz = rot * local_pos.xz;

    // --- Billboard позиционирование ---
    vec3 world_pos = center 
        + cam_right * local_pos.x 
        + cam_up    * local_pos.y;

    VERTEX = (INV_VIEW_MATRIX * vec4(world_pos, 1.0)).xyz;
}

void fragment() {
    ALBEDO = vec3(1.0);
}