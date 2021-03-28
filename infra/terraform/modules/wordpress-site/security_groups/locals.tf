locals {
    name_prefix = "${var.context.environment_name}-wordpress"
    ssh_port = 22
    sftp_port = 22
    postgres_port = 5432
    http_port = 80
    https_port = 443
    ntp_port = 123
    nfs_port = 2049
    smtp_ports = [25, 465, 587]
    tcp_protocol = "tcp"
    udp_protocol = "udp"

    default_tags = {
        environment_name: var.context.environment_name
        environment_type: var.context.environment_type
        terraform_managed = "yes"
    }
}

