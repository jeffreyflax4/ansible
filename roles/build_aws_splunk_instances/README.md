build_aws_splunk_instances
=========

These steps should be visible in GIT. Some of them are executed manually prior to starting to use this role.

1.) Launch a standard AWS Free Tier instance (It might be smart to create a Launch Template for the Ansible Controller Node)
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

NEXT, you want to make sure you set up your dynamic inventory

1.) Run aws configure, to enter in AWS credentials
    # aws configure (then enter details for the following)
        AWS Access Key ID [None]: <ACCESS KEY>
        AWS Secret Access Key [None]: <SECRET KEY>
        Default region name [None]: us-east-1
        Default output format [None]: json
2.) Run a command to test that you can see your inventory
    # ansible-inventory -i aws_ec2.yml --graph

Requirements
------------

Any pre-requisites that may not be covered by Ansible itself or the role should be mentioned here. For instance, if the role uses the EC2 module, it may be a good idea to mention in this section that the boto package is required.

Role Variables
--------------

A description of the settable variables for this role should go here, including any variables that are in defaults/main.yml, vars/main.yml, and any variables that can/should be set via parameters to the role. Any variables that are read from other roles and/or the global scope (ie. hostvars, group vars, etc.) should be mentioned here as well.

Dependencies
------------

A list of other roles hosted on Galaxy should go here, plus any details in regards to parameters that may need to be set for other roles, or variables that are used from other roles.

Example Playbook
----------------

Including an example of how to use your role (for instance, with variables passed in as parameters) is always nice for users too:

    - hosts: servers
      roles:
         - { role: username.rolename, x: 42 }

License
-------

BSD

Author Information
------------------

An optional section for the role authors to include contact information, or a website (HTML is not allowed).
