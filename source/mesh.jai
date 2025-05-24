SCENE_MAX_BUFFERS   :: 100;
SCENE_MAX_MESHES    :: 200;

Vertex :: struct {
    position    := Vector3.{0, 0, 0};
    normal      := Vector3.{0, 0, 0};
    weights     := Vector3.{0, 0, 0};
    joints      : [4]s16;
}

Skeleton :: struct {
    Joint :: struct {
        id : s16;
        local_bind_transform    : Matrix4;
        inverse_bind_transform  : Matrix4;
        parent                  : *Joint;
    }

    name_to_joint_id : Table(string, s16);
    joint : []Joint;
}

Skinned_Mesh :: struct {
    #as using skeleton : Skeleton;
    vertices        : [..]Vertex;
    indices         : [..]u32;
    vao, vbo, ibo   : GLuint;
}

load_mesh_from_file :: (filename : string) -> bool, [..]Skinned_Mesh {
    meshes : [..]Skinned_Mesh;
    data := gltf_parse_file(tprint("resources/models/%", filename));

    for mesh : data.meshes {
        for primitive: mesh.primitives {
            sm : Skinned_Mesh;
            using primitive;

            if position_accessor == -1 {
                continue;
            }

            pos_acc := data.accessors[position_accessor];
            positions : [..]float;
            read_buffer_from_accessor(*data, pos_acc, *positions);

            normals : [..]float;
            if normal_accessor != -1 {
                nor_acc := data.accessors[normal_accessor];
                read_buffer_from_accessor(*data, nor_acc, *normals);
            }

            weights : [..]float;
            if weights_accessor != -1 {
                weight_acc := data.accessors[weights_accessor];
                read_buffer_from_accessor(*data, weight_acc, *weights);
            }

            joints : [..]float;
            if joints_accessor != -1 {
                joint_acc := data.accessors[joints_accessor];
                read_buffer_from_accessor(*data, joint_acc, *joints);
            }

            idx_acc : GLTF_Accessor;
            if indices_accessor != -1 idx_acc = data.accessors[indices_accessor];

            alloc_data := alloc(size_of (Vertex) * pos_acc.count + size_of(u32) * idx_acc.count);
            sm.vertices.data = alloc_data;
            sm.vertices.count = pos_acc.count;
            sm.indices.data = cast (*u32) (sm.vertices.data + sm.vertices.count);
            sm.indices.count = idx_acc.count;

            read_buffer_from_accessor(*data, idx_acc, *sm.indices);
            
            for 0..pos_acc.count {
                sm.vertices[it_index].position = .{positions[it_index * 3 + 0], positions[it_index * 3 + 1], positions[it_index * 3 + 2]};
                if normal_accessor  != -1 { sm.vertices[it_index].normal = .{normals[it_index * 3 + 0], normals[it_index * 3 + 1], normals[it_index * 3 + 2]}; }
                if weights_accessor != -1 { sm.vertices[it_index].weights = .{weights[it_index * 3 + 0], weights[it_index * 3 + 1], weights[it_index * 3 + 2]}; }
                if joints_accessor  != -1 { sm.vertices[it_index].joints[0] = xx joints[it_index * 4 + 0]; sm.vertices[it_index].joints[1] = xx joints[it_index * 4 + 1]; sm.vertices[it_index].joints[2] = xx joints[it_index * 4 + 2]; sm.vertices[it_index].joints[3] = xx joints[it_index * 4 + 3]; }
            }

            array_add(*meshes, sm);
        }
    }

    return true, meshes;
}
