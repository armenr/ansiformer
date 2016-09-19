#!/bin/bash
# Bootstrap for ansiblized node
# Author: Ravi Bhure <ravibhure@gmail.com>
# Usages: curl -L https://raw.githubusercontent.com/ravibhure/terraform-provisioner-ansible/master/bootstrap_ansible_node.sh | sudo bash

machine=`uname -m`
os=`uname -s`

if test -f "/etc/lsb-release" && grep -q DISTRIB_ID /etc/lsb-release && ! grep -q wrlinux /etc/lsb-release; then
  platform=`grep DISTRIB_ID /etc/lsb-release | cut -d "=" -f 2 | tr '[A-Z]' '[a-z]'`
  platform_version=`grep DISTRIB_RELEASE /etc/lsb-release | cut -d "=" -f 2`
elif test -f "/etc/debian_version"; then
  platform="debian"
  platform_version=`cat /etc/debian_version`
  apt-get -qq update
  apt-get -qq -y install software-properties-common
  apt-add-repository -y ppa:ansible/ansible
  apt-get -qq update
  apt-get -qq install ansible
elif test -f "/etc/redhat-release"; then
  platform=`sed 's/^\(.\+\) release.*/\1/' /etc/redhat-release | tr '[A-Z]' '[a-z]'`
  platform_version=`sed 's/^.\+ release \([.0-9]\+\).*/\1/' /etc/redhat-release`

  # If /etc/redhat-release exists, we act like RHEL by default
  # FIXME: stop remapping fedora to el
  # FIXME: remove client side platform_version mangling and hard coded yolo
  # Change platform version for use below.
  platform_version="6.0"
  yum -y update
  yum -q -y install epel-release
  yum -q -y install ansible
elif test -f "/etc/system-release"; then
  platform=`sed 's/^\(.\+\) release.\+/\1/' /etc/system-release | tr '[A-Z]' '[a-z]'`
  platform_version=`sed 's/^.\+ release \([.0-9]\+\).*/\1/' /etc/system-release | tr '[A-Z]' '[a-z]'`
  # amazon is built off of fedora, so act like RHEL
  if test "$platform" = "amazon linux ami"; then
    # FIXME: remove client side platform_version mangling and hard coded yolo, and remapping to deprecated "el"
    platform="el"
    platform_version="6.0"
	yum -y update
    yum -q -y install epel-release
    yum -q -y install ansible
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
  if grep -q 'Enterprise' /etc/SuSE-release;
  then
      platform="sles"
      platform_version=`awk '/^VERSION =/ { print $3 }' /etc/SuSE-release`
	  if test "x$platform_version" = "x10"
        zypper --quiet --non-interactive ar http://download.opensuse.org/repositories/systemsmanagement/SLE_10_SDK/systemsmanagement.repo
	  elif test "x$platform_version" = "x11"
	    zypper --quiet --non-interactive ar http://download.opensuse.org/repositories/systemsmanagement/SLE_11_SP4/systemsmanagement.repo
	  elif test "x$platform_version" = "x12"
	    zypper --quiet --non-interactive ar http://download.opensuse.org/repositories/systemsmanagement/SLE_12/systemsmanagement.repo
	  fi
	  zypper --quiet --non-interactive refresh
	  zypper --quiet --non-interactive install ansible
  else
      platform="suse"
      platform_version=`awk '/^VERSION =/ { print $3 }' /etc/SuSE-release`
	  if test "x$platform_version" = "x10"
        zypper --quiet --non-interactive ar http://download.opensuse.org/repositories/systemsmanagement/SLE_10_SDK/systemsmanagement.repo
	  elif test "x$platform_version" = "x11"
	    zypper --quiet --non-interactive ar http://download.opensuse.org/repositories/systemsmanagement/SLE_11_SP4/systemsmanagement.repo
	  elif test "x$platform_version" = "x12"
	    zypper --quiet --non-interactive ar http://download.opensuse.org/repositories/systemsmanagement/SLE_12/systemsmanagement.repo
	  fi
	  zypper --quiet --non-interactive refresh
	  zypper --quiet --non-interactive install ansible
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

