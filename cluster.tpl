nodes:
    user: "${user}" 
    user: "${user}" 
    user: "${user}"
    role: [controlplane]
services:
  etcd:
    snapshot: "${snapshot_flag}" 
    creation: "${snapshot_creation}" 
    retention: "${snapshot_retention}" 

ignore_docker_version: "${ignore_docker_version}" 
