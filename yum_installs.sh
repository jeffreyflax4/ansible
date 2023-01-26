#!/bin/bash
yum install ansible -y
yum install python-boto -y
yum install -y pip
pip install boto boto3
pip install --upgrade requests==2.20.1
