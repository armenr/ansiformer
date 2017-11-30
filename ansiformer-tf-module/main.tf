// template for generating dynamic inventories unique to each ec2
data "template_file" "ansiformer_inventory" {
  count    = "${length(var.target_hosts_list)}"
  template = "${file("${path.module}/ansiformer_inventory.tmpl")}"

  vars {
    play = "${element(var.target_hosts_list, count.index)}"
  }
}

// magical ansible provisioner begins here
resource "null_resource" "ansiformer" {
  count = "${var.total_instances}"

  /* ansible null_resource provisioner will automatically trigger on changes to: 
    - the unique instance-id of the ec2 it was created for
    - the list of plays you specify for an instance
    This also acts as a roundabout way of tagging each ansiformer null resource with
    metadata about the instance it's paired with so you can easily read that when looking @
    terraform state file
  */

  triggers {
    instance_identifier = "${var.instance_identifiers[count.index]}"
    playlists           = "${join(", ", var.target_hosts_list)}"
  }
  connection {
    user        = "${var.user}"
    private_key = "${var.private_key}"
    host        = "${var.public_ips[count.index]}"
    type        = "ssh"
    timeout     = "12s"
  }
  // render ansible inventory to the filesystem of the target instance
  provisioner "remote-exec" {
    inline = [
      "rm -f /tmp/${var.instance_identifiers[count.index]}-inventory >&2",
      "echo 'Dynamically rendering local inventory to /tmp/${var.instance_identifiers[count.index]}-inventory'",
      "cat > /tmp/${var.instance_identifiers[count.index]}-inventory  <<EOL\n${join("\n", data.template_file.ansiformer_inventory.*.rendered)}EOL",
    ]
  }

  /*
  provision the host via ansible
  TODO: Maybe parameterize inventory file destination path and pass it down to the plugin
  */

  provisioner "ansiformer" {
    playbook    = "${var.playbook}"
    plays       = "${var.plays_lists}"
    hosts       = "${var.target_hosts_list}"
    instance_id = "${var.instance_identifiers[count.index]}"

    // example extra var that does nothing
    extra_vars = {
      "terraform_managed" = "true"
    }
  }
}
