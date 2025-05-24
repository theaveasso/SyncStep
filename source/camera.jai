Camera_Type :: enum u8 {
    PERSPECTIVE :: 0;
    ORTHOGRAPHIC  :: 1;
}

Camera :: struct {
    FLY_SPEED           :: 1.0;
    ROTATION_SPEED      :: 0.3;
    ROTATION_SMOOTHING  :: 0.3;

    fov := 60;
    type : Camera_Type;
    ortho_size : float;

    position        : Vector3;
    euler_angles    : Vector3;
    rotation        : Quaternion;
    rotation_input  : Vector2;

    transform   := Matrix4_Identity;
    view        := Matrix4_Identity;
    proj        := Matrix4_Identity;
    viewproj    := Matrix4_Identity;
}

make_camera_2d :: (using camera: *Camera) {
    type = .ORTHOGRAPHIC;
    vx, vy, vw, vh := get_dimensions(g_window, false);
    proj =  orthographic_projection_matrix(0, cast (float) vw, cast (float) vh, 0, -1, 1);
}

make_camera_3d :: (using camera: *Camera) {
    type = .PERSPECTIVE;
    vx, vy, vw, vh := get_dimensions(g_window, false);
    aspect_ratio := vw / cast (float) vh;
    position = xyz(1, 1.3, 2.3);
    euler_angles.x = -20 * PI / 180.0;
    euler_angles.y = 10 * PI / 180.0;
    proj = make_projection_matrix(fov * PI / 180.0, aspect_ratio, 0.1, 1000.0);
}

make_camera_isometric :: (using camera: *Camera, size : float = 10.) {
    type = .ORTHOGRAPHIC;
    vx, vy, vw, vh := get_dimensions(g_window, false);
    aspect_ratio := vw / cast (float) vh;
    ortho_size = size;
    left    : float = -ortho_size * aspect_ratio;
    right   : float =  ortho_size * aspect_ratio;
    bottom  : float = -ortho_size;
    top     : float =  ortho_size;

    proj =  orthographic_projection_matrix(left, right, bottom, top, -1, 1);
}

update_camera :: (using camera : *Camera, delta_time : float) {
    mouse_delta : Vector2;
    move_input  : Vector3;
    move_speed  : float;

    move_speed = FLY_SPEED;

    if is_key_down(.SHIFT) then move_speed *= 10;
    move_input.x = cast (float) is_key_down(xx #char "D") - cast (float) is_key_down(xx #char "A");
    move_input.y = cast (float) is_key_down(xx #char "Q") - cast (float) is_key_down(xx #char "E");
    move_input.z = cast (float) is_key_down(xx #char "S") - cast (float) is_key_down(xx #char "W");

    move_input = rotate(unit_vector(move_input), rotation);

    position += move_input * move_speed;

    rotation_input = lerp(rotation_input, mouse_delta, ROTATION_SMOOTHING);
    delta := rotation_input * ROTATION_SPEED;
    euler_angles.x += delta.x * PI / 180.0;
    euler_angles.y += delta.y * PI / 180.0;
    euler_angles.y = clamp(euler_angles.y, -80.0 * PI / 180.0, 80.0 * PI / 180.0);

    yaw     : Quaternion;
    pitch   : Quaternion;
    set_from_axis_and_angle(*yaw, 0, -1, 0, euler_angles.x);
    set_from_axis_and_angle(*pitch, -1, 0, 0, euler_angles.y);
    rotation = yaw * pitch;

    transform = make_translation_matrix4(position) * rotation_matrix(Matrix4, rotation);
    success:, view = inverse(transform);
    if !success {
        log_error("(update camera) Could not invert the transform");
    }

    vx, vy, vw, vh := get_dimensions(g_window, false);
    aspect_ratio := vw / cast (float) vh;

    if type == .PERSPECTIVE {
        proj = make_projection_matrix(fov * PI / 180.0, aspect_ratio, 0.1, 1000.0);
    } else if type == .ORTHOGRAPHIC {
        left    : float = -ortho_size * aspect_ratio;
        right   : float =  ortho_size * aspect_ratio;
        bottom  : float = -ortho_size;
        top     : float =  ortho_size;

        proj = orthographic_projection_matrix(left, right, bottom, top, -1.0, 1.0);
    }

    viewproj = proj * view;
}
