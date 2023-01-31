#!/bin/bash
amazon-linux-extras install epel -y
yum install ansible -y
pip3 install ansible
/bin/su -c "pip3 install boto3 --user" - ansible
