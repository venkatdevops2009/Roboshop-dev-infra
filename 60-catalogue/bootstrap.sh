#!/bin/bash

component=$1 #catalogue
environment=$2 #dev
app_version=$3
dnf install ansible -y
mkdir -p /var/log/roboshop/
chown -R ec2-user:ec2-user /var/log/roboshop
chmod -R 755 /var/log/roboshop
touch /var/log/roboshop/ansible.log

cd /home/ec2-user
git clone https://github.com/daws-90s/roboshop-ansible-v3.git
cd roboshop-ansible-v3
git pull
ansible-playbook -e component=$component -e env=$environment -e app_version=$app_version roboshop.yaml