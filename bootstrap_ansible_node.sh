#!/bin/bash
# Bootstrap for ansiblized node
# Author: Ravi Bhure <ravibhure@gmail.com>
# Usages: curl -L https://raw.githubusercontent.com/ravibhure/terraform-provisioner-ansible/master/bootstrap_ansible_node.sh | sudo bash

machine=`uname -m`
os=`uname -s`

wait_for() {
    until /usr/bin/curl -sf "$1"
    do
      echo "Waiting for $1"
      sleep 5
    done
    echo ""
}

#wait_for "http://www.ravibhure.com"

# define function to check if program is installed
# courtesy of https://gist.github.com/JamieMason/4761049
function program_is_installed {
    # set to 1 initially
    local return_=1
    # set to 0 if not found
    type $1 >/dev/null 2>&1 || { local return_=0; }
    # return value
    echo $return_
}

# PIP Deps
_pip_deps(){
  pip --quiet install -U setuptools > /dev/null 2>&1
  pip --quiet install -U pip > /dev/null 2>&1
  sleep 1
}

_install_system_packages(){
  if test -f "/etc/lsb-release" && grep -q DISTRIB_ID /etc/lsb-release && ! grep -q wrlinux /etc/lsb-release; then
    platform=`grep DISTRIB_ID /etc/lsb-release | cut -d "=" -f 2 | tr '[A-Z]' '[a-z]'`
    platform_version=`grep DISTRIB_RELEASE /etc/lsb-release | cut -d "=" -f 2`
    if test "x$platform" = "xubuntu" ; then
      apt-get -qq update > /dev/null 2>&1;
      apt-get -qq -y install build-essential curl software-properties-common python-dev python-setuptools python-pip > /dev/null 2>&1;
    fi
  elif test -f "/etc/debian_version"; then
    platform="debian"
    platform_version=`cat /etc/debian_version`
    apt-get -qq update > /dev/null 2>&1;
    apt-get -qq -y install build-essential curl software-properties-common python-dev python-setuptools python-pip > /dev/null 2>&1;
  elif test -f "/etc/redhat-release"; then
    platform=`sed 's/^\(.\+\) release.*/\1/' /etc/redhat-release | tr '[A-Z]' '[a-z]'`
    platform_version=`sed 's/^.\+ release \([.0-9]\+\).*/\1/' /etc/redhat-release`

    # If /etc/redhat-release exists, we act like RHEL by default
    # FIXME: stop remapping fedora to el
    # FIXME: remove client side platform_version mangling and hard coded yolo
    # Change platform version for use below.
    platform_version="6.0"
    yum -y update > /dev/null 2>&1
    yum -q -y install epel-release > /dev/null 2>&1
    yum-config-manager --enable epel > /dev/null 2>&1
    yum repolist all > /dev/null 2>&1
    yum -q -y install python-devel python-pip  > /dev/null 2>&1
    ret=`python -c 'import sys; print("%i" % (sys.hexversion<0x03000000))'`
    if test "x$ret" != "x0" ; then
      yum -q -y install python-argparse python-jinja2 > /dev/null 2>&1
    fi
  elif test -f "/etc/system-release"; then
    platform=`sed 's/^\(.\+\) release.\+/\1/' /etc/system-release | tr '[A-Z]' '[a-z]'`
    platform_version=`sed 's/^.\+ release \([.0-9]\+\).*/\1/' /etc/system-release | tr '[A-Z]' '[a-z]'`
    # amazon is built off of fedora, so act like RHEL
    if test "$platform" = "amazon linux ami"; then
      # FIXME: remove client side platform_version mangling and hard coded yolo, and remapping to deprecated "el"
      platform="el"
      platform_version="6.0"
      yum -y update > /dev/null 2>&1
      yum -q -y install epel-release > /dev/null 2>&1
      yum-config-manager --enable epel > /dev/null 2>&1
      yum repolist all > /dev/null 2>&1
      yum -q -y install python-devel python-pip  > /dev/null 2>&1
      ret=`python -c 'import sys; print("%i" % (sys.hexversion<0x03000000))'`
      if test "x$ret" != "x0" ; then
        yum -q -y install python-argparse python-jinja2 > /dev/null 2>&1
      fi
    fi
  # Apple OS X
  elif test -f "/usr/bin/sw_vers"; then
    platform="mac_os_x"
    # Matching the tab-space with sed is error-prone
    platform_version=`sw_vers | awk '/^ProductVersion:/ { print $2 }' | cut -d. -f1,2`

    # x86_64 Apple hardware often runs 32-bit kernels (see OHAI-63)
    x86_64=`sysctl -n hw.optional.x86_64`
    if test $x86_64 -eq 1; then
      machine="x86_64"
    fi
  elif test -f "/etc/release"; then
    machine=`/usr/bin/uname -p`
    if grep -q SmartOS /etc/release; then
      platform="smartos"
      platform_version=`grep ^Image /etc/product | awk '{ print $3 }'`
    else
      platform="solaris2"
      platform_version=`/usr/bin/uname -r`
    fi
  elif test -f "/etc/SuSE-release"; then
    if grep -q 'Enterprise' /etc/SuSE-release; then
      platform="sles"
      platform_version=`awk '/^VERSION =/ { print $3 }' /etc/SuSE-release`
      zypper --quiet --non-interactive install python-pip python-setuptools python-wheel > /dev/null 2>&1
      zypper --quiet --non-interactive refresh > /dev/null 2>&1
    else
      platform="suse"
      platform_version=`awk '/^VERSION =/ { print $3 }' /etc/SuSE-release`
      zypper --quiet --non-interactive install python-pip python-setuptools python-wheel > /dev/null 2>&1
      zypper --quiet --non-interactive refresh > /dev/null 2>&1
    fi
  elif test "x$os" = "xFreeBSD"; then
    platform="freebsd"
    platform_version=`uname -r | sed 's/-.*//'`
  elif test "x$os" = "xAIX"; then
    platform="aix"
    platform_version="`uname -v`.`uname -r`"
    machine="powerpc"
  elif test -f "/etc/os-release"; then
    . /etc/os-release
    if test "x$CISCO_RELEASE_INFO" != "x"; then
      . $CISCO_RELEASE_INFO
    fi

    platform=$ID
    platform_version=$VERSION
  fi
}

# Help me
print_usage() {
    echo "Usage: $0 [-av] ansible_version [-h]"
    exit 1
}

# Make sure the correct number of command line
# arguments have been supplied

# Grab the command line arguments
while test -n "$1"; do
    case "$1" in
        -av|--ansible_version)
            ANSIBLE_VERSION=$2
            # ANSIBLE_VERSION if not provided, script will install default ansible version which is 2.3.1
            if [ ! -z $ANSIBLE_VERSION ] ;then
              echo "Installing ansible version $ANSIBLE_VERSION"
              _install_system_packages
              sleep 1
              _pip_deps
              pip --quiet install -U ansible==$ANSIBLE_VERSION > /dev/null 2>&1
              if [ $(program_is_installed "ansible") -eq 0 ] ; then
                sleep 1
                pip --quiet install -U ansible==$ANSIBLE_VERSION > /dev/null 2>&1
              fi
            else
              echo "Installing ansible latest version"
              _install_system_packages
              sleep 1
              _pip_deps
              # https://goo.gl/ZWr5WF
              pip --quiet install -U 'ansible>=2.3.1,<2.4.0' > /dev/null 2>&1
              if [ $(program_is_installed "ansible") -eq 0 ] ; then
                sleep 1
                pip --quiet install -U ansible==$ANSIBLE_VERSION > /dev/null 2>&1
              fi
            fi
            ;;
        -h|--help)
            print_usage
            ;;
    esac
    shift
done
