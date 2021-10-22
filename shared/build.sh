useradd -m -p 123456 ec2-user
ssh-keygen -s /shared/host_ca/host_ca -I 'master_node_host_ca' -h -V -1d:+1w -n 'worker_node,worker_node2' /etc/ssh/ssh_host_rsa_key.pub

