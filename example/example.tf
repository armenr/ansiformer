provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region = "${var.aws_region}"
}

resource "aws_instance" "ansible-test" {
  ami = "ami-d94f5aa0"
  instance_type = "t2.micro"
  key_name = "ravi"

  provisioner "ansible" {
    connection {
      user = "ubuntu"
      private_key = "${file("~/.ssh/ravi.pem")}"
    }

    playbook = "playbook.yml"
    plays = ["terraform"]
    hosts = ["all"]
    group_vars = ["terraform"]
    extra_vars = {
      "extra_var"="terraform"
    }
  }
}
