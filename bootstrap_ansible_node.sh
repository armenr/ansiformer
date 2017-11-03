#!/bin/bash
# Bootstrap for ansiblized node
# Author: Ravi Bhure <ravibhure@gmail.com>
# Usages: curl -L https://raw.githubusercontent.com/ravibhure/terraform-provisioner-ansible/master/bootstrap_ansible_node.sh | sudo bash
# ANSIBLE_VERSION if not provided, script will install default ansible version which is 2.3.1
ANSIBLE_VERSION=$1


# just to sleep
# sleep 5 ;
if [[ -f /etc/redhat-release ]]; then 
  yum -y update  > /dev/null 2>&1 && \
  yum -q -y install gcc libffi-devel openssl-devel python-devel  > /dev/null 2>&1;
elif [[ -f /etc/debian_version ]]; then
  apt-get -qq update > /dev/null 2>&1 && \
  apt-get -qq -y install build-essential libssl-dev libffi-dev software-properties-common python-dev python-setuptools > /dev/null 2>&1;
elif [[ -f /etc/fedora-release ]]; then
  dnf -y install gcc libffi-devel openssl-devel python-devel python-setuptools > /dev/null 2>&1;
elif [[ -f /etc/SuSE-release ]]; then
  zypper --quiet --non-interactive refresh > /dev/null 2>&1
  zypper --quiet --non-interactive install libffi-devel openssl-devel python-devel python-setuptools > /dev/null 2>&1
else
  echo "Nothing to do"
fi

if hash ansible 2>/dev/null; then
  echo 'Ansible already installed!!' >&2
  echo 'Proceeding with instance provisioning' >&2
  exit 0
else
    echo 'Installing pip, python dependencies, and Ansible' >&2
    echo 'Please stand by' >&2
    easy_install pip > /dev/null 2>&1
    echo 'easy_install pip successful' >&2
    pip -qqq install -U setuptools > /dev/null 2>&1
    echo 'Installed setuptools' >&2
    pip -qqq install -U pip > /dev/null 2>&1
    pip -qqq --log /tmp/pip.log install -U 'ansible' > /dev/null 2>&1
    echo 'Successfully installed Ansible. Provisioning host...' >&2
fi
