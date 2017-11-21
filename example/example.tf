provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region     = "${var.aws_region}"
}

/* start instance with ansible with the version */
resource "aws_instance" "ansible-test" {
  ami           = "ami-d94f5aa0"
  instance_type = "t2.micro"
  key_name      = "ravi"

  provisioner "ansible" {
    connection {
      user        = "ubuntu"
      private_key = "${file("~/.ssh/ravi.pem")}"
    }

    ansible_version = "2.2.1.0"
    playbook        = "playbook.yml"
    plays           = ["terraform"]
    hosts           = ["all"]
    group_vars      = ["terraform"]

    extra_vars = {
      "extra_var" = "terraform"
    }
  }
}

/* without passing the version */
resource "null_resource" "ansible-run" {
  provisioner "ansible" {
    connection {
      user        = "ubuntu"
      private_key = "${file("~/.ssh/ravi.pem")}"
      host        = "${aws_instance.ansible-test.public_ip}"
      type        = "ssh"
    }

    playbook   = "playbook.yml"
    plays      = ["terraform"]
    hosts      = ["all"]
    group_vars = ["terraform"]

    extra_vars = {
      "extra_var" = "terraform"
    }
  }
}
