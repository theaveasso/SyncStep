Joint_Sample :: struct {
    local_position      : Vector3;
    local_orientation   : Quaternion;
    local_scale         : Vector3;
}

Joint_Animation :: struct {
    name    : string;
    samples : []Joint_Sample;
}

Skeleton_Pose :: struct {
    Joint :: struct {
        parent : *Joint;
        #as using sample : Joint_Sample;
        model_space_transform := Matrix4_Identity;
    }

    skeleton : *Skeleton;
    joints : []Joint;
    skinning_matrices : []Matrix4;
}

Sampled_Animation :: struct {
    sample_count    : s64;
    joints          : []Joint_Animation;
}