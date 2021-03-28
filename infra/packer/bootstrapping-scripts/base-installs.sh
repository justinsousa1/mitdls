#!/usr/bin/env bash

# typically for simpler steps like package manager installs, these can be thrown in a bash script
# more complex steps are much easier to put into ansible and run those from packer

if [[ "$(whoami)" != "root" ]]; then
    echo "This script needs to be run as root or with sudo"
    exit 1
fi

yum update -y
# a bunch of useful installs including ansible into base system python env
yum install -y git python2-pip libselinux-python jq amazon-efs-utils openssl-devel bind-utils htop
pip2 install pip==20.1.1
pip2 install --upgrade 'ansible<2.10' jinja2 boto3

# uninstall v1 of the aws cli and install v2
yum remove -y awscli
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install
ln -s /usr/local/bin/aws /usr/bin/aws

# aws inspector agent
curl -O https://inspector-agent.amazonaws.com/linux/latest/install
bash ./install

# aws ssm-agent ignore the windows mentioned in the path here
# https://docs.aws.amazon.com/systems-manager/latest/userguide/agent-install-al2.html
yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm

# disable selinux (assume ansible installed elsewhere)
[[ -x "$(command -v ansible)" ]] && ansible localhost -m selinux -a state=disabled --become

# newer feature of amzn2
# https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/al2-live-patching.html#working-with-live-patching
yum install -y binutils
yum install -y yum-plugin-kernel-livepatch
yum kernel-livepatch enable -y
yum install -y kpatch-runtime
systemctl enable kpatch.service
amazon-linux-extras enable livepatch
