VPIXELS :: 1080;
ASPECT  :: (16. / 9.);

window_width    := cast(s32) (VPIXELS * ASPECT);
window_height   := VPIXELS;
window_aspec    := ASPECT;

window_tile := "SyncStep";

should_quit := false;

main :: () {
    the_window := create_window(window_width, window_height, window_tile);
    Simp.set_render_target(the_window);

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

        Simp.swap_buffers(the_window);
        reset_temporary_storage();
    }
}

#load "module.jai";