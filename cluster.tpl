nodes:
  - address: "${private_ip_1}" 
    internal_address: "1.2.3.4" 
    user: "${user}" 
    role: [controlplane] 
  - address: "2.3.4.5" 
    internal_address: "2.3.4.5" 
    user: "${user}" 
    role: [controlplane]
  - address: "3.4.5.6" 
    internal_address: "3.4.5.6" 
    user: "${user}" 
    role: [controlplane]

services:
  etcd:
    snapshot: "${snapshot_flag}" 
    creation: "${snapshot_creation}" 
    retention: "${snapshot_retention}" 

ignore_docker_version: "${ignore_docker_version}" 
