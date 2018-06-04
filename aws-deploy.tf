provider "aws" {
  region  = "${var.region}"
  profile = "atorres"
}

data "aws_availability_zones" "available" {}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name                 = "jenkins"
  cidr                 = "${var.vpc_cidr}"
  azs                  = ["${data.aws_availability_zones.available.names[0]}"]
  public_subnets       = ["${var.public_subnet_cidr}"]
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Terraform = "True"
  }
}

module "sg-elb" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "Jenkins_ELB"
  description = "Jenkins ELB Security Group"
  vpc_id      = "${module.vpc.vpc_id}"

  ingress_with_cidr_blocks = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      description = "Jenkins Port"
      cidr_blocks = "0.0.0.0/0"
    },
  ]

  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 65535
      protocol    = "all"
      description = "All egress"
      cidr_blocks = "0.0.0.0/0"
    },
  ]

  tags = {
    Name      = "Jenkins Server"
    Terraform = "True"
  }
}

module "sg" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "jenkins-sg"
  description = "Jenkins Security Group"
  vpc_id      = "${module.vpc.vpc_id}"

  ingress_with_cidr_blocks = [
    {
      from_port   = 8080
      to_port     = 8080
      protocol    = "tcp"
      description = "Jenkins Port"
      cidr_blocks = "${var.public_subnet_cidr}"
    },
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      description = "Ssh Port"
      cidr_blocks = "0.0.0.0/0"
    },
  ]

  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 65535
      protocol    = "all"
      description = "All egress"
      cidr_blocks = "0.0.0.0/0"
    },
  ]

  tags = {
    Name      = "Jenkins Server"
    Terraform = "True"
  }
}

module "sg_ssh" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "mongo_sg"
  description = "Mongo Security Group"
  vpc_id      = "${module.vpc.vpc_id}"

  ingress_with_cidr_blocks = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      description = "Ssh Port"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 6443
      to_port     = 6443
      protocol    = "tcp"
      description = "Kubernetes API server"
      cidr_blocks = "${var.public_subnet_cidr}"
    },
    {
      from_port   = 2379
      to_port     = 2380
      protocol    = "tcp"
      description = "etcd server client API"
      cidr_blocks = "${var.public_subnet_cidr}"
    },
    {
      from_port   = 10250
      to_port     = 10250
      protocol    = "tcp"
      description = "Kubelet API"
      cidr_blocks = "${var.public_subnet_cidr}"
    },
    {
      from_port   = 10251
      to_port     = 10251
      protocol    = "tcp"
      description = "kube-scheduler"
      cidr_blocks = "${var.public_subnet_cidr}"
    },
    {
      from_port   = 10252
      to_port     = 10252
      protocol    = "tcp"
      description = "kube-controller-manager"
      cidr_blocks = "${var.public_subnet_cidr}"
    },
    {
      from_port   = 0
      to_port     = 65535
      protocol    = "all"
      description = "All egress"
      cidr_blocks = "${var.public_subnet_cidr}"
    },
    {
      from_port   = 10255
      to_port     = 10255
      protocol    = "tcp"
      description = "Read-only Kubelet API"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 30000
      to_port     = 32767
      protocol    = "tcp"
      description = "NodePort Services"
      cidr_blocks = "${var.public_subnet_cidr}"
    },
  ]

  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 65535
      protocol    = "all"
      description = "All egress"
      cidr_blocks = "0.0.0.0/0"
    },
  ]

  tags = {
    Name      = "Mongo Server"
    Terraform = "True"
  }
}

resource "aws_instance" "jenkins" {
  ami                    = "${lookup(var.amis, var.region)}"
  instance_type          = "${var.instance_type[2]}"
  subnet_id              = "${module.vpc.public_subnets[0]}"
  vpc_security_group_ids = ["${module.sg.this_security_group_id}"]

  count                       = 1
  key_name                    = "${var.key_pair}"
  monitoring                  = false
  associate_public_ip_address = true

  root_block_device = {
    volume_size = 20
  }

  provisioner "local-exec" {
    command = <<EOT
              sleep 120
              ansible-playbook -u ec2-user --private-key=~/.ssh/new-key-pair.pem -i '${aws_instance.jenkins.public_ip},'  ansible/jenkins.yml
              EOT
  }

  tags = {
    Name      = "Jenkins Server"
    Terraform = "True"
  }

  volume_tags = {
    Name      = "Jenkins Server"
    Terraform = "True"
  }
}

//Provisioning MongoDB
resource "aws_instance" "mongo" {
  ami                    = "${lookup(var.amis, var.region)}"
  instance_type          = "${var.instance_type[0]}"
  subnet_id              = "${module.vpc.public_subnets[0]}"
  vpc_security_group_ids = ["${module.sg_ssh.this_security_group_id}"]

  count                       = 1
  key_name                    = "${var.key_pair}"
  monitoring                  = false
  associate_public_ip_address = true

  root_block_device = {
    volume_size = 20
  }

  provisioner "local-exec" {
    command = <<EOT
              sleep 120
              ansible-playbook -u ec2-user --private-key=~/.ssh/new-key-pair.pem -i '${aws_instance.mongo.public_ip},'  ansible/mongo.yml
              EOT
  }

  tags = {
    Name      = "Mongo Server"
    Terraform = "True"
  }

  volume_tags = {
    Name      = "Mongo Server"
    Terraform = "True"
  }
}

//Provisioning K8 Master

resource "aws_instance" "k8-master" {
  ami                    = "${lookup(var.amik8, var.region)}"
  instance_type          = "${var.instance_type[1]}"
  subnet_id              = "${module.vpc.public_subnets[0]}"
  vpc_security_group_ids = ["${module.sg_ssh.this_security_group_id}"]

  count                       = 1
  key_name                    = "${var.key_pair}"
  monitoring                  = false
  associate_public_ip_address = true

  root_block_device = {
    volume_size = 20
  }

  provisioner "local-exec" {
    command = <<EOT
                sleep 120
                ansible-playbook -u ec2-user --private-key=~/.ssh/new-key-pair.pem -i '${aws_instance.k8-master.public_ip},'  ansible/k8_install.yml
                sleep 60
                ansible-playbook -u ec2-user --private-key=~/.ssh/new-key-pair.pem -i '${aws_instance.k8-master.public_ip},'  ansible/k8_master.yml --extra-vars "k8s_token=${var.token} k8_cidr=${var.public_subnet_cidr}"
                EOT
  }

  tags = {
    Name      = "K8 Master"
    Terraform = "True"
  }

  volume_tags = {
    Name      = "K8 Master"
    Terraform = "True"
  }
}

resource "aws_instance" "k8-worker" {
  ami                         = "${lookup(var.amik8, var.region)}"
  instance_type               = "${var.instance_type[1]}"
  subnet_id                   = "${module.vpc.public_subnets[0]}"
  vpc_security_group_ids      = ["${module.sg_ssh.this_security_group_id}"]
  depends_on                  = ["aws_instance.k8-master"]
  count                       = 3
  key_name                    = "${var.key_pair}"
  monitoring                  = false
  associate_public_ip_address = true

  root_block_device = {
    volume_size = 20
  }

  provisioner "local-exec" {
    command = <<EOT
                sleep 120
                ansible-playbook -u ec2-user --private-key=~/.ssh/new-key-pair.pem -i '${self.public_ip},'  ansible/k8_install.yml
                sleep 60
                ansible-playbook -u ec2-user --private-key=~/.ssh/new-key-pair.pem -i '${self.public_ip},'  ansible/k8_worker.yml --extra-vars "k8s_token=501a5t.on7auxtxyq3hfpwq private_ip=${aws_instance.k8-master.private_ip}"
                EOT
  }

  tags = {
    Name      = "K8 worker"
    Terraform = "True"
  }

  volume_tags = {
    Name      = "K8 worker"
    Terraform = "True"
  }
}

resource "aws_elb" "prodapp-elb" {
  name = "ATApp-terraform-elb"

  #availability_zones = ["us-west-2a", "us-west-2b", "us-west-2c"] 
  security_groups = ["${module.sg-elb.this_security_group_id}"]
  subnets         = ["${module.vpc.public_subnets[0]}"]

  listener {
    instance_port     = 8080
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "tcp:8080"
    interval            = 30
  }

  instances = ["${aws_instance.jenkins.id}"]

  tags {
    Name        = "ATApp-terraform-elb"
    Environment = "Production"
  }
}
