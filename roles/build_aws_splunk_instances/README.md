build_aws_splunk_instances
=========

########################################
BUILD ANSIBLE CONTROLLER NODE IN AWS GUI
########################################

1.) Launch a standard AWS Free Tier instance (It might be smart to create a Launch Template for the Ansible Controller Node and in the Advanced Settings of the Launch Template you can also add the IAM Role to your instance as well, skipping steps 2e-2g)
2.) Create an IAM Role
	   a. Go to IAM > Roles > Create Role
	   b. AWS service and EC2 are Selected, Click Next
	   c. Search for AmazonEC2FullAccess and Select it, Click Next
	   d. Name the Role and Click Create Role
	   e. Go to EC2 > Instances page, and select your controller node
	   f. Click Actions > Security > Modify IAM Role
	   g. Select your named IAM role from above and click Update IAM Role
3.) Create an IAM User Group (for example Admin) and then add that group to a newly created IAM User (for example - ansible-test)reate an Access Key and Secret Key
       a. Go to IAM > User Groups > Create Group
       b. Enter group name and select the appropriate permissions policy (For this purpose, we selected AdministratorAccess, thought this may be overkill)
       c. Then select Create Group
       d. Go to IAM > Users > Add users
       e. Enter User Name, Click Next
       f. Select your Group Name from step (b.) and click Next
       g. Then review and click Create User
4.) Next, create a Access Key and Secret Key for your user and save that file locally

#####################################
BUILD ANSIBLE CONTROLLER NODE VIA CLI
#####################################

5.) Log into your Ansible Controller Node AWS instance and run the initial steps
    # sudo ssh -i github.pem ec2-user@1.2.3.4
    # sudo su
    # adduser ansible
    # amazon-linux-extras install epel -y
    # yum install git -y
6.) In this setup, we will use /opt as the working directory, and we want the ansible user to have write permissions for that directory
    # setfacl -R -m u:ansible:rwx /opt
    # su ansible
7.) Create SSH Key-Pair
    # cd ~
    # ssh-keygen # Just hit enter until the process completed
    # cat .ssh/id_rsa.pub
8.) Copy the entire contents of the Public Key and add it to the GitHub you are using
    # Settings > SSH and GPG Keys > New SSH key (Give the key a name and paste)
9.) Clone your GIT repository
    # cd /opt
    # git clone git@github.com:jeffreyflax4/ansible.git
    # Set GIT username and email
    # git config --global user.email "you@example.com"
    # git config --global user.name "Your Name"
10.) Run yum_installs bash script
    # exit (you are now operating as the root user)
    # cd /opt/ansible
    # sh yum_installs.sh (this will take a few minutes)
11.) Make sure that Ansible is running python3
    # ansible --version (looking for python version)
    # vi /usr/bin/ansible
    # On the first line, change #!/usr/bin/python2 to #!/usr/bin/python3
    # ansible --version (you should now see 3.x for the python version)
10.) Install Amazon.AWS Collection, as ansible user
    # su ansible
    # cd /opt/ansible
    # ansible-galaxy collection install -r roles/requirements.yml

################################################
SETUP AND RUN PLAYBOOK TO BUILD SPLUNK INSTANCES
################################################

11.) Update defaults/main.yml in the role to apply any settings changes
    # vi roles/build_aws_splunk_instances/default/main.yml
12.) Create aws_secrets file with AWS Access Key and AWS Secret Key
    # cd /opt
    # mkdir secrets
    # cd secrets
    # ansible-vault create aws_secrets.yml
    # Set up a password, and then create a file with two lines (use keys from Step 4 above)
    	aws_access_key: <ACCESS_KEY>
	aws_secret_key: <SECRET_KEY>
13.) Run playbook.yml to create the desired instances
    # cd /opt/ansible
    # ansible-playbook --ask-vault-pass playbook.yml

##################
DYNAMIC INVENTORY
##################

Make sure you see your new hosts in your dynamic inventory

1.) Run a command to test that you can see your inventory
    # ansible-inventory -i splunk_aws_ec2.yml --graph

##################
PASSWORDLESS SSH
##################

Set up passwordless SSH from the Ansible Controller node to the remote EC2 instances

1.) Copy the private key file from your local machine to the controller node
    # sudo scp -r -i Downloads/github.pem github.pem ec2-user@1.2.3.4:/var/tmp
    # That command is run locally on your own machine, where you have the private key file saved
2.) Give the key file proper permissions and move it to the ~/.ssh directory
    # Back on your Ansible Controller Node - make sure you are operating as root
    # cd /var/tmp
    # chown -R ansible:ansible github.pem
    # su ansible
    # cd /var/tmp
    # mv github.pem ~/.ssh/
    # chmod 600 ~/.ssh/github.pem
3.) Now, you will need to run the add_key.yml playbook
    # ansible-playbook -i splunk_aws_ec2.yml add-key.yml --key-file ~/.ssh/github.pem
4.) Run a command to test that you can now successfully ping the remote EC2 instances
    # ansible -i splunk_aws_ec2.yml full -m ping -u ec2-user 

###########################
ADD ANSIBLE-ROLE-FOR-SPLUNK
###########################

You are now ready to move to your buildout of the Splunk application on your new AWS infrastructure.  After you run the following commands, the README file for this role will no longer be of service

1.) Clone the ansible-role-for-splunk git repository (make sure you are still the 'ansible' user on the Ansible Controller Node
    # cd /opt
    # git clone git@github.com:jeffreyflax4/ansible-role-for-splunk.git 

Requirements
------------
Role Variables
--------------
Dependencies
------------
Example Playbook
----------------
There are a few playbooks that are used in this role:
    playbook.yml -  This playbook is the main playbook to build the splunk instances

    add_key.yml - This playbook is used to set up passwordless SSH for your AWS Splunk instances to be sent commands from the Ansible Controller Node
License
-------
BSD
Author Information
------------------
Jeff Flax - August Schell
