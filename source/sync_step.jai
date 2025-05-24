VPIXELS :: 360;
ASPECT  :: (16. / 9.);

window_width    := cast(s32) (VPIXELS * ASPECT);
window_height   := VPIXELS;
window_aspec    := ASPECT;

window_tile := "SyncStep";

should_quit := false;

RED     :: Vector4.{1, 0, 0, 1};
GREEN   :: Vector4.{0, 1, 0, 1};
BLUE    :: Vector4.{0, 0, 1, 1};

MAX_WEIGHTS :: 4;
MAX_JOINTS  :: 1000;

loaded_meshes : Table(string, [..]Skinned_Mesh);
loaded_animation : Table(string, Sampled_Animation);
mesh : *Skinned_Mesh;

g_camera : Camera;
g_window : Window_Type;

main :: () {
    g_window = create_window(window_width, window_height, window_tile);
    Simp.set_render_target(g_window);
    Simp.set_shader_for_color(true);

    p0 := make_vector3(0);
    p1 := make_vector3(.{xx window_width, 0}, 0);
    p2 := make_vector3(.{cast(float) window_width / 2, xx window_height}, 0);

    init_rendering_object();

    ok, meshes_barbarian := load_mesh_from_file("Barbarian.glb");
    for mesh : meshes_barbarian {
        init_mesh_rendering_object(*mesh);
    }
    table_add(*loaded_meshes, copy_string("Barbarian"), meshes_barbarian);

    // g_camera.position = xyz(1, 1.3, 2.3);
    // g_camera.euler_angles.x = -20 * PI / 180.0;
    // g_camera.euler_angles.y = 10 * PI / 180.0;
    make_camera_3d(*g_camera);

    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

    delta_time := 0.01667;

    while !should_quit {
        Input.update_window_events();
        for event : Input.events_this_frame {
            if event.type == .QUIT {
                should_quit = true;
            }
            if event.type == .KEYBOARD {
                if event.key_code == .ESCAPE if event.key_pressed should_quit = true;
            }
        }
        update_camera(*g_camera, delta_time);

        Simp.clear_render_target(.1, .2, .3, 1.);

        immediate_line(.{}, .{x=1}, RED);
        immediate_line(.{}, .{y=1}, GREEN);
        immediate_line(.{}, .{z=1}, BLUE);

        immediate_grid(10, 10);

        Simp.swap_buffers(g_window);
        reset_temporary_storage();
    }
}

is_key_down :: inline (key : Input.Key_Code) -> bool { return (Input.input_button_states[cast (s64) key] & .DOWN) != 0; }

#load "animation.jai";
#load "camera.jai";
#load "module.jai";
#load "renderer.jai";
#load "mesh.jai";