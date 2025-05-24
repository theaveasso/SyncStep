CIRCLE_RESOLUTION :: 32;

big_data_ubo    : GLuint;

g_mesh_program    : GLuint;
g_line_program    : GLuint;

g_line_vao, g_line_vbo : GLuint;

GL_BIG_DATA_UNIFORM_BINDING :: 0;

Vertex2 :: struct {
    position    : Vector3;
    color       : Vector4;
}

#scope_file

create_shader_program :: (vert_source: string, frag_source: string) -> bool, GLuint {
    check_compile_errors :: (shader : GLuint) -> bool, info_log: string {
        success : s32;
        glGetShaderiv(shader, GL_COMPILE_STATUS, *success);
        if !success {
            info_len : s32;
            glGetShaderiv(shader, GL_INFO_LOG_LENGTH, *info_len);
            info_data := cast (*u8) alloc(info_len,, temp);
            glGetShaderInfoLog(shader, xx info_len, xx *info_len, info_data);
            result : string;
            result.count = info_len;
            result.data = info_data;
            return false, result;
        }
        return true, "";
    }

    check_link_errors :: (program: GLuint) -> bool, info_log: string {
        success : s32;
        glGetProgramiv(program, GL_LINK_STATUS, *success);
        if !success {
            info_len : s32;
            glGetProgramiv(program, GL_INFO_LOG_LENGTH, *info_len);
            info_data := cast (*u8) alloc(info_len,, temp);
            glGetProgramInfoLog(program, xx info_len, xx *info_len, info_data);
            result : string;
            result.count = info_len;
            result.data = info_data;
            return false, result;
        }
        return true, "";
    }

    vs := glCreateShader(GL_VERTEX_SHADER);
    defer glDeleteShader(vs);

    shaders := *u8.[SHADER_PREFIX.data, vert_source.data];
    lengths := s32.[xx SHADER_PREFIX.count, xx vert_source.count];
    glShaderSource(vs, 2, shaders.data, lengths.data);
    glCompileShader(vs);
    ok, info_log := check_compile_errors(vs);
    if !ok {
        log_error("Could not compile vertex shader %", info_log);
        return false, 0;
    }

    fs := glCreateShader(GL_FRAGMENT_SHADER);
    defer glDeleteShader(fs);
    shaders[1] = frag_source.data;
    lengths[1] = xx frag_source.count;
    glShaderSource(fs, 2, shaders.data, lengths.data);
    glCompileShader(fs);
    ok, info_log = check_compile_errors(fs);
    if !ok {
        log_error("Could not compile fragment shader %", info_log);
        return false, 0;
    }

    result := glCreateProgram();
    glAttachShader(result, vs);
    glAttachShader(result, fs);
    glLinkProgram(result);
    ok, info_log = check_link_errors(result);
    if !ok {
        log_error("Could not link shader program %", info_log);
        glDeleteProgram(result);
        return false, 0;
    }

    return true, result;
}

#scope_export

immediate_grid :: (x : s8, y : s8, color : Vector4 = .{1., 1. , 1., 1.}) {
    for i : -x..x immediate_line(xyz(xx i, 0., xx -x), xyz(xx i, 0., xx x), color);
    for i : -y..y immediate_line(xyz(xx -y, 0., xx i), xyz(xx y, 0., xx i), color);
}

immediate_line :: inline (start : Vector3, end: Vector3, color : Vector4) {
    immediate_line(start, end, color, color);
}

immediate_line :: inline (start : Vector3, end: Vector3) {
    immediate_line(start, end, .{1., 1., 1., 1.}, .{1., 1., 1., 1.});
}

immediate_line :: (start : Vector3, end : Vector3, start_color : Vector4, end_color : Vector4) {
    data : [2]Vertex2 = ---;
    data[0].position = start;
    data[0].color= start_color;
    data[1].position = end;
    data[1].color= end_color;

    glBindVertexArray(g_line_vao);
    glBindBuffer(GL_ARRAY_BUFFER, g_line_vbo);
    glBufferSubData(GL_ARRAY_BUFFER, 0, size_of(Vertex2) * 2, data.data);
    glUseProgram(g_line_program);
    glUniformMatrix4fv(glGetUniformLocation(g_line_program, "u_ViewProj"), 1, GL_TRUE, *g_camera.viewproj.coef[0][0]);
    glDrawArrays(GL_LINES, 0, 2);

}

immediate_circle :: (center: Vector2, radius: float, color : Vector4=.{1., 1., 1., 1.}) {
    STEP_ANGLE :: 2*PI/CIRCLE_RESOLUTION;
    for 0..CIRCLE_RESOLUTION-1 {
        p0 := center;
        p1 := center + .{cos(STEP_ANGLE*it), sin(STEP_ANGLE*it)} * radius;
        p2 := center + .{cos(STEP_ANGLE*(it+1)), sin(STEP_ANGLE*(it+1))} * radius;
        Simp.immediate_triangle(make_vector3(p0, 0), make_vector3(p1, 0), make_vector3(p2, 0), color, color, color);
    }
}

immediate_mesh :: (using mesh : Skinned_Mesh, model_matrix : Matrix4, skinning_matrices : []Matrix4) {
    glBindBuffer(GL_UNIFORM_BUFFER, big_data_ubo);
    glBufferSubData(GL_UNIFORM_BUFFER, 0, size_of(Matrix4) * skinning_matrices.count, skinning_matrices.data);
    glBindBuffer(GL_UNIFORM_BUFFER, 0);

    glBindVertexArray(vao);
    glBindBuffer(GL_ARRAY_BUFFER, vbo);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ibo);
    glUseProgram(g_mesh_program);

    glUniformMatrix4fv(glGetUniformLocation(g_mesh_program, "u_Model"), 1, GL_TRUE, *model_matrix.coef[0][0]);
    glUniformMatrix4fv(glGetUniformLocation(g_mesh_program, "u_ViewProj"), 1, GL_TRUE, *g_camera.viewproj.coef[0][0]);

    glDrawElements(GL_TRIANGLES, cast (u32) indices.count , GL_UNSIGNED_INT, null);
}

init_rendering_object :: () -> bool {
    ok: bool;
    ok, g_mesh_program = create_shader_program(MESH_VERTEX_SHADER, MESH_FRAMENT_SHADER);
    if !ok return false;

    big_data_uniform_index := glGetUniformBlockIndex(g_mesh_program, "Big_Data");
    glUniformBlockBinding(g_mesh_program, big_data_uniform_index, GL_BIG_DATA_UNIFORM_BINDING);

    glGenBuffers(1, *big_data_ubo);
    glBindBuffer(GL_UNIFORM_BUFFER, big_data_ubo);
    glBufferData(GL_UNIFORM_BUFFER, size_of(Matrix4) * MAX_JOINTS, null, GL_DYNAMIC_DRAW);
    glBindBuffer(GL_UNIFORM_BUFFER, 0);
    glBindBufferBase(GL_UNIFORM_BUFFER, GL_BIG_DATA_UNIFORM_BINDING, big_data_ubo);

    ok, g_line_program = create_shader_program(LINE_VERTEX_SHADER, LINE_FRAGMENT_SHADER);
    if !ok return false;

    glGenVertexArrays(1, *g_line_vao);
    glBindVertexArray(g_line_vao);
    glGenBuffers(1, *g_line_vbo);
    glBindBuffer(GL_ARRAY_BUFFER, g_line_vbo);
    glBufferData(GL_ARRAY_BUFFER, size_of(Vertex2) * 2, null, GL_DYNAMIC_DRAW);

    glEnableVertexAttribArray(0);
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, size_of(Vertex2), cast(*void) 0);

    glEnableVertexAttribArray(1);
    glVertexAttribPointer(1, 4, GL_FLOAT, GL_FALSE, size_of(Vertex2), cast(*void) size_of(Vector3));

    glBindVertexArray(0);
    glBindBuffer(GL_ARRAY_BUFFER, 0);


    return true;
}

init_mesh_rendering_object :: (using mesh : *Skinned_Mesh) {
    glGenBuffers(1, *vbo);
    glBindBuffer(GL_ARRAY_BUFFER, vbo);
    defer glBindBuffer(GL_ARRAY_BUFFER, 0);
    glBufferData(GL_ARRAY_BUFFER, size_of(Vertex) * vertices.count, vertices.data, GL_STATIC_DRAW);

    glGenBuffers(1, *ibo);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ibo);
    defer glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, size_of(u32) * indices.count, indices.data, GL_STATIC_DRAW);

    glGenVertexArrays(1, *vao);
    glBindVertexArray(vao);
    defer glBindVertexArray(0);

    glEnableVertexAttribArray(0);
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, size_of(Vertex), cast(*void)0);

    glEnableVertexAttribArray(1);
    glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, size_of(Vertex), cast(*void) size_of(Vector3));

    glEnableVertexAttribArray(2);
    glVertexAttribPointer(2, 3, GL_FLOAT, GL_FALSE, size_of(Vertex), cast(*void) (2 * size_of(Vector3)));

    glEnableVertexAttribArray(3);
    glVertexAttribPointer(3, 3, GL_FLOAT, GL_FALSE, size_of(Vertex), cast(*void) (3 * size_of(Vector3)));
}

SHADER_PREFIX :: #string END 
#version 330 core 
END

MESH_VERTEX_SHADER :: #run sprint(#string END
const int MAX_JOINTS    = %1;
const int MAX_WEIGHTS   = %2;

layout (location = 0) in vec3   a_Position;
layout (location = 1) in vec3   a_Normal;
layout (location = 2) in vec3   a_Weights;
layout (location = 3) in ivec4  a_Joint_Ids;

uniform mat4 u_Model;
uniform mat4 u_ViewProj;

layout (std140) uniform Big_Data {
    mat4 u_Skinning_Matrices[MAX_JOINTS];
};

out vec3 Normal;

void main () {
    vec3 model_position = vec3(0);
    vec3 model_normal   = vec3(0);
    if (a_Joint_Ids[0] == -1) {
        model_position  = a_Position;
        model_normal    = a_Normal;
    } 
    for (int i = 0; i < MAX_WEIGHTS && a_Joint_Ids[i] != -1; ++i) {
        int joint_id = a_Joint_Ids[i];
        float weight;
        if (i == MAX_WEIGHTS - 1) {
            weight = 1.0 - (a_Weights.x + a_Weights.y + a_Weights.z);
        } else {
            weight = a_Weights[i];
        }
        mat4 skinning_matrix = u_Skinning_Matrices[joint_id];
        vec3 pose_position = (skinning_matrix * vec4(a_Position, 1)).xyz;
        model_position += pose_position * weight;
        vec3 pose_normal = (skinning_matrix * vec4(a_Normal, 0)).xyz;
        model_normal += pose_normal * weight;
    }
    gl_Position = u_ViewProj * u_Model * vec4(model_position, 1.);
    Normal = model_normal.xyz;
}
END, MAX_JOINTS, MAX_WEIGHTS);

MESH_FRAMENT_SHADER :: #string GLSL
in vec3 Normal;

out vec4 Frag_Color;

void main () {
    Frag_Color = vec4(Normal, 1);
}
GLSL

LINE_VERTEX_SHADER :: #string GLSL
layout (location = 0) in vec3 a_Position;
layout (location = 1) in vec4 a_Color;

uniform mat4 u_ViewProj;

out vec4 Color;

void main() {
    gl_Position = u_ViewProj * vec4(a_Position, 1);
    Color = a_Color;
}

GLSL

LINE_FRAGMENT_SHADER :: #string GLSL
in vec4 Color;

out vec4 Frag_Color;

void main() {
    Frag_Color = Color;
}

GLSL