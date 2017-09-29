#!/bin/bash
# Bootstrap for ansiblized node
# Author: Ravi Bhure <ravibhure@gmail.com>
# Usages: curl -L https://raw.githubusercontent.com/ravibhure/terraform-provisioner-ansible/master/bootstrap_ansible_node.sh | sudo bash
# ANSIBLE_VERSION if not provided, script will install default ansible version which is 2.3.1
ANSIBLE_VERSION=$1

_pip_deps(){
  easy_install pip > /dev/null 2>&1;
  pip --quiet install -U setuptools > /dev/null 2>&1
  pip --quiet install -U pip > /dev/null 2>&1
}
# just to sleep
sleep 10 ;
if [[ -f /etc/redhat-release ]];then 
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
  echo "nothing to do"
fi
# main program starts ;)
if [ ! -z $ANSIBLE_VERSION ] ; then
  _pip_deps
  pip --quiet --log /tmp/pip.log install -U ansible==$ANSIBLE_VERSION
else
  _pip_deps
  pip --quiet --log /tmp/pip.log install -U 'ansible>=2.3.1,<2.4.0'
fi
