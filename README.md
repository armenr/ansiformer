# terraform-provisioner-ansible
> Provision terraform resources with ansible

## Overview

**[Terraform](https://github.com/hashicorp/terraform)** is a tool for automating infrastructure. Terraform includes the ability to provision resources at creation time through a plugin api. Currently, some builtin [provisioners](https://www.terraform.io/docs/provisioners/) such as **chef** and standard scripts are provided; this provisioner introduces the ability to provision an instance at creation time with **ansible**.

This provisioner provides the ability to apply **host-groups**, **plays** or **roles** against a host at provision time. Ansible is run on the host itself and this provisioner configures a dynamic inventory on the fly as resources are created.

The ansible terraform provisioner configures Ansible to run on the machine by Terraform from local Playbook and Role files. Playbooks and Roles can be uploaded from your local machine to the remote machine. Ansible is run in [local mode](https://docs.ansible.com/ansible/playbooks_delegation.html#local-playbooks) via the ansible-playbook command.

**terraform-provisioner-ansible** is shipped as a **Terraform** [module](https://www.terraform.io/docs/modules/create.html). To include it, simply download the binary and enable it as a terraform module in your **terraformrc**.

## Installation

**terraform-provisioner-ansible** ships as a single binary and is compatible with **terraform**'s plugin interface. Behind the scenes, terraform plugins use https://github.com/hashicorp/go-plugin and communicate with the parent terraform process via RPC.

To install, download and un-archive the binary and place it on your path.

```bash
$ https://github.com/ravibhure/terraform-provisioner-ansible/releases/download/terraform-provisioner-ansible-0.0.6.tar.gz

$ tar -xvf terraform-provisioner-ansible-0.0.6.tar.gz /usr/local/bin
```

Once installed, a `~/.terraformrc` file is used to _enable_ the plugin.

```bash
providers {
    ansible = "/usr/local/bin/terraform-provisioner-ansible"
}
```

## Usage

Once installed, you can provision resources by including an `ansible` provisioner block.

NOTE: If not provided `ansible_version`, by default this will install latest ansible version.

The following example demonstrates a configuration block to apply a host group's plays to new instances. You can specify a list of hostgroups and a list of plays to specify which ansible tasks to perform on the host.

Additionally, `group_vars` and `extra_vars` are accessible to resolve variables and group the new host in ansible.

```
{
  resource "aws_instance" "ansible" {
    ami = "ami-408c7f28"
    instance_type = "t1.micro"

    provisioner "ansible" {
      connection {
        user = "ubuntu"
      }

      ansible_version = "2.2.1.0"
      playbook = "ansible/playbook.yml"
      group_vars = ["all"]
      hosts = ["terraform"]
      extra_vars = {
        "env"="terraform"
      }
    }
  }
}
```

Check out [example](example/) for a more detailed walkthrough of the provisioner and how to provision resources with **ansible**.

## History

See release notes for changes https://github.com/ravibhure/terraform-provisioner-ansible/releases

## Inspiration

* This is forked from ravibhure (https://github.com/ravibhure/terraform-provisioner-ansible/)
* ...Which is a fork of this project, originally written by [jonmorehouse](https://github.com/jonmorehouse/terraform-provisioner-ansible)
