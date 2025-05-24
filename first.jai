OUTPUT_EXECUTABLE_NAME  := "sync_step";
OUTPUT_PATH             := ".build";

#run {
    make_directory_if_it_does_not_exist(OUTPUT_PATH);
    set_build_options_dc(.{do_output = false});

    w := compiler_create_workspace("Target workspace");
    options := get_build_options(w);
    copy_commonly_propagated_fields(get_build_options(), *options);
    options.output_executable_name  = OUTPUT_EXECUTABLE_NAME;
    options.output_path             = OUTPUT_PATH;
    set_build_options(options, w);

    compiler_begin_intercept(w);
    add_build_file("source/sync_step.jai", w);
    compiler_end_intercept(w);

    copy_directory("resources/", tprint("%/resources/", OUTPUT_PATH));
}

#import "Basic";
#import "Compiler";
#import "File";
#import "File_Utilities";
#import "Windows_Resources";
#import "Ico_File";