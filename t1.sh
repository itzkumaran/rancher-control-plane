 provisioner "local-exec" {
    command = "cat > test_output.json <<EOL
	                                  nodes:
	                                     ${join("  - address: ", "${ec2_rancher_control_plane_nodes_1.public_ip}")}
                                             ${join("    internal_address: ", "${ec2_rancher_control_plane_nodes_1.private_ip}")}
                                             ${join("    user: ", "${var.user}")}
                                             ${join("    role: ", "${var.role_list}")}
                                             ${join("  - address: ", "${ec2_rancher_control_plane_nodes_2.public_ip}")}
                                             ${join("    internal_address: ", "${ec2_rancher_control_plane_nodes_2.private_ip}")}

                                             ${join("    user: ", "${var.user}")}
                                             ${join("    role: ", "${var.role_list}")}
                                             ${join("  - address: ", "${ec2_rancher_control_plane_nodes_3.public_ip}")}
                                             ${join("    internal_address: ", "${ec2_rancher_control_plane_nodes_3.private_ip}")}

                                             ${join("    user: ", "${var.user}")}
                                             ${join("    role: ", "${var.role_list}")}

                                          services:
                                             ${join("  - etcd: ", data.template_file.test.*.rendered)}
                                             ${join("    snapshot: ", "${var.snapshot_flag}")}
                                             ${join("    creation: ", "${var.snapshot_creation}")}
                                             ${join("    retention: ", "${var.snapshot_retention}")}
                                          ignore_docker_version: true
			               EOL"
  }
