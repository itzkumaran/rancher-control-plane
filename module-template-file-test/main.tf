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

data "template_file" "cluster_template" {
    template = "${file("cluster.tpl")}"
    vars {
        private_ip_1 = "${module.ec2_rancher_control_plane_nodes_1.private_ip[0]}"
        private_ip_2 = "${module.ec2_rancher_control_plane_nodes_2.private_ip[0]}"
        private_ip_3 = "${module.ec2_rancher_control_plane_nodes_3.private_ip[0]}"
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
