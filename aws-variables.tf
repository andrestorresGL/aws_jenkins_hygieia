variable "region" {
  default = "us-east-1"
}

variable "amis" {
  default = {
    us-east-1 = "ami-14c5486b"
    us-east-2 = "ami-e97c548c"
    us-west-1 = "ami-ee03078e"
    us-west-2 = "ami-7707a10f"
  }
}

variable "amik8" {
  default = {
    us-east-1 = "ami-6871a115"
    us-east-2 = "ami-e97c548c" //definir amis de Redhat
    us-west-1 = "ami-ee03078e"
    us-west-2 = "ami-7707a10f"
  }
}

variable "vpc_cidr" {
  default = "10.8.0.0/16"
}

variable "public_subnet_cidr" {
  default = "10.8.0.0/24"
}

variable "instance_type" {
  type    = "list"
  default = ["t2.micro", "t2.small", "t2.medium"]
}

variable "key_pair" {
  default = "new-key-pair"
}

variable "private_key_path" {
  default = "/home/atorres/.ssh/new-key-pair.pem"
}

variable "token" {
  default = "501a5t.on7auxtxyq3hfpwq"
}
