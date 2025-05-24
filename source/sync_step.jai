VPIXELS :: 1080;
ASPECT  :: (16. / 9.);

window_width    := cast(s32) (VPIXELS * ASPECT);
window_height   := VPIXELS;
window_aspec    := ASPECT;

window_tile := "SyncStep";

should_quit := false;

RED     :: Vector4.{1, 0, 0, 1};
GREEN   :: Vector4.{0, 1, 0, 1};
BLUE    :: Vector4.{0, 0, 1, 1};

main :: () {
    the_window := create_window(window_width, window_height, window_tile);
    Simp.set_render_target(the_window);
    Simp.set_shader_for_color(true);

    p0 := make_vector3(0);
    p1 := make_vector3(.{xx window_width, 0}, 0);
    p2 := make_vector3(.{cast(float) window_width / 2, xx window_height}, 0);

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

        Simp.immediate_triangle(p0, p1, p2, RED, GREEN, BLUE);

        Simp.swap_buffers(the_window);
        reset_temporary_storage();
    }
}

#load "module.jai";