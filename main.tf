provider "aws" {
  region = "us-east-1"
  shared_credentials_file = "~/.aws/config"
  profile                 = "default"
}

data "aws_subnet_ids" "private_subnet_ids" {
  vpc_id   = "${var.vpc_id}"
  tags {
    Tier   = "Private"
  }
}

data "aws_subnet" "private_subnets" {
  id    = "${data.aws_subnet_ids.private_subnet_ids.ids[count.index]}"
}

data "aws_subnet_ids" "public_subnet_ids" {
  vpc_id   = "${var.vpc_id}"
  tags {
    Tier   = "Public"
  }
}

data "template_file" "user_data" {
  template = "${file("${path.module}/configure_rancher_nodes.sh")}"
}

resource "aws_security_group" "rancher_control_plane_sg" {
  name        = "rancher_control_plane_sg"
  description = "Rancher control plane security group"
  vpc_id      = "${var.vpc_id}"

  ingress {
    from_port   = 22 
    to_port     = 22 
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 2376
    to_port     = 2376
    protocol    = "TCP"
    cidr_blocks = ["${data.aws_subnet.private_subnets.cidr_block}"]
  }

  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "TCP"
    cidr_blocks = ["${data.aws_subnet.private_subnets.cidr_block}"]
  }
  
  
  ingress {
    from_port   = 8472
    to_port     = 8472
    protocol    = "TCP"
    cidr_blocks = ["${data.aws_subnet.private_subnets.cidr_block}"]
  }  

  ingress {
    from_port   = 9099
    to_port     = 9099
    protocol    = "TCP"
    self        = true
  }  

  ingress {
    from_port   = 10250
    to_port     = 10250
    protocol    = "TCP"
    cidr_blocks = ["${data.aws_subnet.private_subnets.cidr_block}"]
  }    

  ingress {
    from_port   = 10254
    to_port     = 10254
    protocol    = "TCP"
    self        = true
  }  

  ingress {
    from_port   = 30000
    to_port     = 32767
    protocol    = "TCP"
    cidr_blocks = ["${data.aws_subnet.private_subnets.cidr_block}"]
  }  
  
  ingress {
    from_port   = 30000
    to_port     = 32767
    protocol    = "UDP"
    cidr_blocks = ["${data.aws_subnet.private_subnets.cidr_block}"]
  } 
  
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "TCP"
    cidr_blocks = ["${data.aws_subnet.private_subnets.cidr_block}"]
  }

  egress {
    from_port   = 2379
    to_port     = 2380
    protocol    = "TCP"
    cidr_blocks = ["${data.aws_subnet.private_subnets.cidr_block}"]
  }

  egress {
    from_port   = 8472
    to_port     = 8472
    protocol    = "TCP"
    cidr_blocks = ["${data.aws_subnet.private_subnets.cidr_block}"]
  }
  
  
  egress {
    from_port   = 9099
    to_port     = 9099
    protocol    = "TCP"
    self        = true
  } 

  egress {
    from_port   = 10250
    to_port     = 10250
    protocol    = "TCP"
    cidr_blocks = ["${data.aws_subnet.private_subnets.cidr_block}"]
  }  

  egress {
    from_port   = 10254
    to_port     = 10254
    protocol    = "TCP"
    self        = true
  }

  egress {
    from_port   = 80 
    to_port     = 80 
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 443 
    to_port     = 443 
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Owner = "${var.resource_owner}"
    Domain = "${var.resource_domain}"
    Environment = "${var.environment}"
  }

}

resource "aws_security_group" "alb_sg" {
  name        = "alb_sg"
  description = "Application load balancer security group"
  vpc_id      = "${var.vpc_id}"

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "TCP"
    security_groups = ["${aws_security_group.rancher_control_plane_sg.id}"]
  }

  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "TCP"
    security_groups = ["${aws_security_group.rancher_control_plane_sg.id}"]
  }  
  tags = {
    Owner = "${var.resource_owner}"
    Domain = "${var.resource_domain}"
    Environment = "${var.environment}"
  }
}

module "ec2_rancher_control_plane_nodes_1" {
  source                 = "terraform-aws-modules/ec2-instance/aws"
  version                = "1.12.0"
  name                   = "${var.instance_name}"
  instance_count         = "${var.instance_count}"
  ami                    = "${var.ami_id}"
  instance_type          = "${var.instance_type}"
  key_name               = "${var.key_name}"
  monitoring             = true
  associate_public_ip_address = true
  vpc_security_group_ids = ["${aws_security_group.rancher_control_plane_sg.id}"]
  subnet_id = "${element(data.aws_subnet_ids.private_subnet_ids.ids,0)}"
  user_data = "${data.template_file.user_data.rendered}"  
tags = {
    Owner = "${var.resource_owner}"
    Domain = "${var.resource_domain}"
    Environment = "${var.environment}"
  }
}

module "ec2_rancher_control_plane_nodes_2" {
  source                 = "terraform-aws-modules/ec2-instance/aws"
  version                = "1.12.0"
  name                   = "${var.instance_name}"
  instance_count         = "${var.instance_count}"
  ami                    = "${var.ami_id}"
  instance_type          = "${var.instance_type}"
  key_name               = "${var.key_name}"
  monitoring             = true
  associate_public_ip_address = true
  vpc_security_group_ids = ["${aws_security_group.rancher_control_plane_sg.id}"]
  subnet_id = "${element(data.aws_subnet_ids.private_subnet_ids.ids,1)}"
  user_data = "${data.template_file.user_data.rendered}"
  tags = {
    Owner = "${var.resource_owner}"
    Domain = "${var.resource_domain}"
    Environment = "${var.environment}"
  }
}

module "ec2_rancher_control_plane_nodes_3" {
  source                 = "terraform-aws-modules/ec2-instance/aws"
  version                = "1.12.0"
  name                   = "${var.instance_name}"
  instance_count         = "${var.instance_count}"
  ami                    = "${var.ami_id}"
  instance_type          = "${var.instance_type}"
  key_name               = "${var.key_name}"
  monitoring             = true
  associate_public_ip_address = true
  vpc_security_group_ids = ["${aws_security_group.rancher_control_plane_sg.id}"]
  subnet_id = "${element(data.aws_subnet_ids.private_subnet_ids.ids,2)}"
  user_data = "${data.template_file.user_data.rendered}"
  tags = {
    Owner = "${var.resource_owner}"
    Domain = "${var.resource_domain}"
    Environment = "${var.environment}"
  }
}

module "elb_rancher" {
  source  = "terraform-aws-modules/alb/aws"
  version = "3.5.0"
  load_balancer_name = "${var.alb_name}" 
  security_groups = ["${aws_security_group.alb_sg.id}"]
  subnets  = ["${data.aws_subnet_ids.public_subnet_ids.ids}"]
  vpc_id   = "${var.vpc_id}"
  logging_enabled               = false
  tags = {
    Owner = "${var.resource_owner}"
    Domain = "${var.resource_domain}"
    Environment = "${var.environment}"
  }
}

resource "aws_lb_target_group" "rancher_https_tg" {
  name        = "rancher-https-tg"
  port        = 443
  protocol    = "HTTPS"
  target_type = "instance"
  vpc_id      = "${var.vpc_id}"
  tags = {
    Owner = "${var.resource_owner}"
    Domain = "${var.resource_domain}"
    Environment = "${var.environment}"
  }
}

resource "aws_lb_target_group_attachment" "tg_attach_1" {
  target_group_arn = "${aws_lb_target_group.rancher_https_tg.arn}"
  target_id        = "${element(module.ec2_rancher_control_plane_nodes_1.id,0)}"
  port             = 443 
}

resource "aws_lb_target_group_attachment" "tg_attach_2" {
  target_group_arn = "${aws_lb_target_group.rancher_https_tg.arn}" 
  target_id        = "${element(module.ec2_rancher_control_plane_nodes_2.id,0)}" 
  port             = 443
}

resource "aws_lb_target_group_attachment" "tg_attach_3" {
  target_group_arn = "${aws_lb_target_group.rancher_https_tg.arn}" 
  target_id        = "${element(module.ec2_rancher_control_plane_nodes_1.id,0)}" 
  port             = 443
}

resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = "${module.elb_rancher.load_balancer_id}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "https_listener" {
  load_balancer_arn = "${module.elb_rancher.load_balancer_id}"
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2015-05"
  certificate_arn   = "${var.alb_ssl_cert_arn}"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.rancher_https_tg.arn}"
  }
}

data "template_file" "cluster_template" {
    template = "${file("cluster.tpl")}"
    vars {
        private_ip_1 = "${local.private_ip_1}" 
        user        = "${var.user}"
        snapshot_flag = "${var.snapshot_flag}"
        snapshot_retention = "${var.snapshot_retention}"
        snapshot_creation = "${var.snapshot_creation}"
        ignore_docker_version = "${var.ignore_docker_version}"
    }
}

resource "null_resource" "export_rendered_template" {
  provisioner "local-exec" {
    command = "cat > cluster.yaml <<EOL\n${join(",\n", data.template_file.cluster_template.*.rendered)}\nEOL"
  }
}

locals {
  private_ip_1 = "${module.ec2_rancher_control_plane_nodes_1.private_ip}" 
}
