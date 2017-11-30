# Ansiformer - Radical DevOps Simplicity

This plugin - and the included terraform module  - make it easy to provision hosts with Ansible at the time of instance creation.

This pattern seeks to address certain difficulties and issues with the common DevOps workflow around Ansible + Terraform. 

1. Avoid disparity or mismatch between Ansible's inventory and Terraform's State
2. You can dynamically pass resource and module outputs from terraform into cofiguration vars for Ansible from a single contextual plane
    - Example: Terraform creates an RDS instance, or an S3 VPC Endpoint - and you need to pass whatever the computed address of that resource is (IP, DNS, etc) to a configuration parameter in an Ansible playbook by including that as a variable. This makes that a piece of cake.


To install:
run terraform with ``` terraform apply -plugin-dir=PATH```
OR, ```~/.terraform.d/plugins/terraform-provisioner-ansiformer_v1.0.12```
## Contents

* [Quick Start](#quick-start)
* [Examples](https://github.com/serverless/examples)
* [Features](#features)

## <a name="features"></a>Features


## Overview 

Terraform includes the ability to provision resources at creation time through a plugin api. Currently, some builtin [provisioners](https://www.terraform.io/docs/provisioners/) such as **chef** and standard scripts are provided; this provisioner  the ability to provision an instance at creation time with **ansible**.

This provisioner provides the ability to apply **host-groups**, **group vars**, **extra vars**, **plays**, or **roles** against a host at provision time. Ansible is run on the host itself and this provisioner configures and copies over a corresponding dynamic inventory file for that host, on the fly, as resources are created.

**Reasoning** for generating the dynamic inventory file is due to the nature of how ansible runs playbooks on local hosts. From [Ansible's Documentation](http://docs.ansible.com/ansible/latest/playbooks_delegation.html#local-playbooks):
>To run an entire playbook locally, just set the “hosts:” line to “hosts: 127.0.0.1” and then run the playbook like so:
>
>   `ansible-playbook playbook.yml --connection=local`

This is problematic, since users would have to modify their existing playbooks, or create copies of existing playbooks that are mapped to run against 'localhost' rather than maintaining their existing playbooks, in conventional manner. This is unattractive and undesirable. See example below: 

1 - Conventional Ansible approach
```
- hosts: lamp_fullstack
  become: true
  roles:
    - user.mysql
    - user.php
    - user.apache2
```

2 - "Ansible local" approach
```
- hosts: localhost
  become: true
  roles:
    - user.mysql
    - user.php
    - user.apache2
```

I've solved this problem by dynamically templating an inventory file that gets dropped off in /tmp/ of the target instance via the included ansiformer-tf-module

## EVERYTHing BELOW THIS LINE IS WRONG FOR NOW

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

See release notes for changes https://github.com/armenr/ansiformer/releases

## Inspiration - Standing on the shoulders of giants
* This project is based on [ravibhure's]((https://github.com/ravibhure/terraform-provisioner-ansible)) fork of [jonmorehouse](https://github.com/jonmorehouse/terraform-provisioner-ansible) original Ansible plugin for Terraform.
