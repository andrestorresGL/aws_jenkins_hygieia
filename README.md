# aws_jenkins_hygieia

**Prerequisites**

* Terraform >= 0.11.7
* Ansible = 2.7.0.dev0

**Installation Process**

* Configure your `AWS_ACCESS_KEY_ID` and your `AWS_SECRET_ACCESS_KEY`
```
 export AWS_ACCESS_KEY_ID=XXXXXXXXX
 export AWS_SECRET_ACCESS_KEY=XXXXXXXXX

```
* Configure your Key file on the `aws-variables.tf`
```
variable "key_pair" {
  default = "new-key-pair"
}

variable "private_key_path" {
  default = "/home/atorres/.ssh/new-key-pair.pem"
}
```
* Execute `terraform plan`
* Execute `terraform apply`

* Jenkins User and password are located at `ansible/roles/jenkins/files/basic-security.groovy`
