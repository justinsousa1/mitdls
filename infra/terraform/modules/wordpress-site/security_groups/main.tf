data "aws_vpc" "vpc" {
  id = var.vpc_id
}

# the idea here is all instances would get this rule applied to them
# so rules here have to be safe for all instances.
# things like EFS traffic and/or SSH admin access to all machines
resource "aws_security_group" "common_rules" {
  name = "${local.name_prefix}-common-rules-sg"
  tags = merge({
    Name = "${local.name_prefix}-common-rules-sg"
    subnet_rules_domain = "internal"
  }, local.default_tags, var.additional_tags)
  vpc_id = var.vpc_id
}

resource "aws_security_group" "load_balancer_sg" {
  name = "${local.name_prefix}-load-balancer-sg"
  tags = merge({
    Name = "${local.name_prefix}-load-balancer-sg"
    # this will have rules on it that contain external IPs
    subnet_rules_domain = "external"
  }, local.default_tags, var.additional_tags)
  vpc_id = var.vpc_id
}

resource "aws_security_group" "webserver_sg" {
  name = "${local.name_prefix}-webserver-sg"
  tags = merge({
    Name = "${local.name_prefix}-webservers-sg"
    # if webserver isn't accessed directly from the internet but only through WAF/ALB
    # this sg could have only internal rules attached to it. internal being defined as either internal IPs or other security groups
    subnet_rules_domain = "internal"
  }, local.default_tags)
  vpc_id = var.vpc_id
}

# security group for the efs drives
resource "aws_security_group" "efs_sg" {
  name = "${local.name_prefix}-efs-sg"
  tags = merge({
    Name = "${local.name_prefix}-efs-sg"
    subnet_rules_domain = "internal"
  }, local.default_tags)
  vpc_id = var.vpc_id
}


#

# -- Security Group Rules

# I'm fond of using SSM (or other tools) for managing SSH like access to boxes
# instead of the traditional pattern of having a bastion host and allowing SSH access
# but you could attach a SG rule here to allow SSH from some bastion for example.
resource "aws_security_group_rule" "common_admin_inbound_ssh_access" {
  from_port = local.ssh_port
  protocol = local.tcp_protocol
  security_group_id = aws_security_group.common_rules.id
  to_port = local.ssh_port
  type = "ingress"
  description = "ssh inbound from bastion/admin sg"
  source_security_group_id = "some-admin-sg-id"
//  cidr_blocks = ["or some admin IPs like a bastion host"]
}

resource "aws_security_group_rule" "webserver_efs_access_outbound" {
  from_port = local.nfs_port
  protocol = local.tcp_protocol
  security_group_id = aws_security_group.webserver_sg.id
  to_port = local.nfs_port
  type = "egress"
  description = "nfs traffic outbound to efs SG which is attached to EFS drives"
  source_security_group_id = aws_security_group.efs_sg.id
}

# argument could be made to exclude rules such as this and not allow
# package updates to running systems but instead stand up a newly built instance
# with an AMI that is updated. this is just an example project though so allow http/https out to the world
resource "aws_security_group_rule" "common_allow_https_out" {
  from_port = local.https_port
  protocol = local.tcp_protocol
  security_group_id = aws_security_group.common_rules.id
  to_port = local.https_port
  type = "egress"
  description = "https outbound to all IPs"
  cidr_blocks = ["0.0.0.0/0"]
}

# many yum repos use HTTP instead of https
resource "aws_security_group_rule" "common_allow_http_out" {
  from_port = local.http_port
  protocol = local.tcp_protocol
  security_group_id = aws_security_group.common_rules.id
  to_port = local.http_port
  type = "egress"
  description = "http outbound to all IPs"
  cidr_blocks = ["0.0.0.0/0"]
}


# you can/could also do IP whitelisting at the WAF to restrict access to certain IPs
# in that case, the DNS would still point to the ALB via CNAME/alias but
# the WAF IP blocks would take precedence over any rules set here
resource "aws_security_group_rule" "load_balancer_http_inbound_from_internet" {
  from_port = local.http_port
  protocol = local.tcp_protocol
  security_group_id = aws_security_group.load_balancer_sg.id
  to_port = local.http_port
  type = "ingress"
  description = "http inbound from all IPs"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "load_balancer_https_inbound_from_internet" {
  from_port = local.https_port
  protocol = local.tcp_protocol
  security_group_id = aws_security_group.load_balancer_sg.id
  to_port = local.https_port
  type = "ingress"
  description = "https inbound from all IPs"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "load_balancer_http_outbound_to_webservers" {
  from_port = local.http_port
  protocol = local.tcp_protocol
  security_group_id = aws_security_group.load_balancer_sg.id
  to_port = local.http_port
  type = "egress"
  description = "http outbound from alb to webserver"
  source_security_group_id = aws_security_group.webserver_sg.id
}

resource "aws_security_group_rule" "load_balancer_https_outbound_to_webservers" {
  from_port = local.https_port
  protocol = local.tcp_protocol
  security_group_id = aws_security_group.load_balancer_sg.id
  to_port = local.https_port
  type = "egress"
  description = "https outbound from alb to webserver"
  source_security_group_id = aws_security_group.webserver_sg.id
}

# corresponding rules on webservers to allow ingress from ALB
resource "aws_security_group_rule" "webserver_http_inbound_from_lb" {
  from_port = local.http_port
  protocol = local.tcp_protocol
  security_group_id = aws_security_group.webserver_sg.id
  to_port = local.http_port
  type = "ingress"
  description = "http inbound from load balancer to webservers"
  source_security_group_id = aws_security_group.load_balancer_sg.id
}

resource "aws_security_group_rule" "webserver_https_inbound_from_lb" {
  from_port = local.https_port
  protocol = local.tcp_protocol
  security_group_id = aws_security_group.webserver_sg.id
  to_port = local.https_port
  type = "ingress"
  description = "https inbound from load balancer to webservers"
  source_security_group_id = aws_security_group.load_balancer_sg.id
}
