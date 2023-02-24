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

1.) Log into your Ansible Controller Node AWS instance and run the initial steps
    # sudo ssh -i github.pem ec2-user@1.2.3.4
    # sudo su
    # adduser ansible
    # amazon-linux-extras install epel -y
    # yum install git -y
2.) In this setup, we will use /opt as the working directory, and we want the ansible user to have write permissions for that directory
    # setfacl -R -m u:ansible:rwx /opt
    # su ansible
3.) Create SSH Key-Pair
    # cd ~
    # ssh-keygen # Just hit enter until the process completed
    # cat .ssh/id_rsa.pub
4.) Copy the entire contents of the Public Key and add it to the GitHub you are using
    # Settings > SSH and GPG Keys > New SSH key (Give the key a name and paste)
5.) Clone your GIT repository
    # cd /opt
    # git clone git@github.com:jeffreyflax4/ansible.git
    # Set GIT username and email
    # git config --global user.email "you@example.com"
    # git config --global user.name "Your Name"
6.) Run yum_installs bash script
    # exit (you are now operating as the root user)
    # cd /opt/ansible
    # sh yum_installs.sh (this will take a few minutes)
7.) Make sure that Ansible is running python3
    # ansible --version (looking for python version)
    # vi /usr/bin/ansible
    # On the first line, change #!/usr/bin/python2 to #!/usr/bin/python3
    # ansible --version (you should now see 3.x for the python version)
8.) Install Amazon.AWS Collection, as ansible user
    # su ansible
    # cd /opt/ansible
    # ansible-galaxy collection install -r roles/requirements.yml

################################################
SETUP AND RUN PLAYBOOK TO BUILD SPLUNK INSTANCES
################################################

1.) Update defaults/main.yml in the role to apply any settings changes
    # vi roles/build_aws_splunk_instances/default/main.yml
2.) Create aws_secrets file with AWS Access Key and AWS Secret Key
    # cd /opt
    # mkdir secrets
    # cd secrets
    # ansible-vault create aws_secrets.yml
    # Set up a password, and then create a file with two lines (use keys from Step 4 above)
    	aws_access_key: <ACCESS_KEY>
	aws_secret_key: <SECRET_KEY>
3.) Run playbook.yml to create the desired instances
    # cd /opt/ansible
    # ansible-playbook --ask-vault-pass playbook.yml

##################
DYNAMIC INVENTORY
##################

Make sure you see your new hosts in your dynamic inventory

1.) Run a command to test that you can see your inventory
    # ansible-inventory -i splunk_aws_ec2.yml --graph

##################################
PASSWORDLESS SSH AND MOUNT VOLUMES
##################################

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
3.) Now, you will need to run the add_key-mount-volumes.yml playbook to add the SSH key, and mount the volumes created above to the /opt directory
    # ansible-playbook -i splunk_aws_ec2.yml add-key-mount-volumes.yml --key-file ~/.ssh/github.pem
4.) Run a command to test that you can now successfully ping the remote EC2 instances
    # ansible -i splunk_aws_ec2.yml full -m ping -u ec2-user ## confirm you can successfully ping each instance
    # ansible -i splunk_aws_ec2.yml full -m shell -a "df -h" -u ec2-user ## check to see that the /opt directory was mounted and has desired storage amounts

###########################
ADD ANSIBLE-ROLE-FOR-SPLUNK
###########################

You are now ready to move to your buildout of the Splunk application on your new AWS infrastructure. Start by cloning the git repository for the ansible-role-for-splunk and updating the appropriate variables

1.) Clone the ansible-role-for-splunk git repository (make sure you are still the 'ansible' user on the Ansible Controller Node
    # cd /opt
    # git clone git@github.com:jeffreyflax4/ansible-role-for-splunk.git 
2.) Edit the approrpiate variables based on the updated Public IPv4 DNS names of your AWS instances
    # vi /opt/ansible-role-for-splunk/roles/splunk/defaults/main.yml
    # Update the splunk_uri_ds, splunk_uri_lm, and the splunk_uri_cm
    # vi /opt/ansible-role-for-splunk/environments/production/group_vars/all.yml
    # Update the splunk_uri_lm

####################################
INSTALL SPLUNK AND DEPLOY SH CLUSTER
####################################

1.) First, install Splunk
    # cd /opt/ansible-role-for-splunk/playbooks
    # ansible-playbook --ask-vault-pass splunk_install_or_upgrade.yml
2.) You should now be able to log into the splunk_mgmt host via SplunkWeb
    # http://<splunk_mgmt>:8000
3.) Go to Settings > Forwarder Management and make sure you have your CM, Deployer, and any UFs/HFs (be a little patient as it may take a few minutes for these to check in)
4.) If any of those are missing, repeat step 1 and check again (sometimes the UF does not get installed properly on the first time through)
5.) Next, Deploy the Search Head Cluster
    # cd /opt/ansible-role-for-splunk/playbooks
    # ansible-playbook --ask-vault-pass splunk_shc_deploy.yml
6.) When this finishes, you can log into any of your Search Heads, and you should then be able to go to the Settings > Search Head Clustering page

########################
SET UP DEPLOYMENT SERVER
########################

Now it is time to build out the proper Splunk environment using the Deployment SServer functionality

1.) Clone the ansible-role-for-splunk git repository (make sure you are still the 'ansible' user on the Ansible Controller Node
    # cd /opt
    # git clone git@github.com:jeffreyflax4/deployment-apps.git
2.) Make all appropriate edits to the following files:
    # in apps/ folder
        # ansible_all_forwarder_outputs - Update server list in outputs.conf (indexers)
        # ansible_cluster_indexer_base - Update manager_uri setting in server.conf (cluster manager)
        # ansible_cluster_search_base - Update manager_uri setting in server.conf (cluster manager)
        # ansible_full_license_server - Update mananger_uri setting in server.conf (splunk_mgmt)

    # in cluster_master_apps/ folder
        # ansible_all_forwarder_outputs - Copy file from apps/ folder over
        # ansible_cluster_search_base - Update manager_uri setting in server.conf (cluster manager)
        # ansible_full_license_server - Copy file from apps/ folder over
        # ansible_manager_deploymentclient - Update target_uri setting in deploymentclient.conf (deployment server)

    # in deployer_apps/ folder
        # ansible_all_forwarder_outputs - Copy file from apps/ folder over
        # ansible_deployer_deploymentclient - Update target_uri setting in deploymentclient.conf (deployment server)
        # ansible_full_license_server - Copy file from apps/ folder over

    # in playbooks/configure_deployment_server.yml file
        # Update the Target URI for the SH Cluster Bundle push command (can be any SH URI)

    # in serverclass.conf
        # serverClass:All_Forwarders - Blacklist the Cluster Master Private IP addr
        # serverClass:Deployer - Whitelist the Deployer Private IP addr
        # serverClass:Cluster Manager - Whitelist the Cluster Manager Private IP addr
        # serverClass:Heavy_Forwarders - Whitelist the Heavy Forwarder(s) Private IP addr

####################################
INSTALL SPLUNK AND DEPLOY SH CLUSTER
####################################

1.) Run the playbook first to fix some issues with the ansible-role-for-splunk
    # cd /opt/deployment-apps/playbooks
    # ansible-playbook fix_splunk_issues.yml
2.) Then, run the playbook to configure the Deployment Server functionality
    # ansible-playbook --ask-vault-pass configure_deployment_server.yml
3.) Next, run two playbooks (after a minute or two), to push out the newest bundles
    # ansible-playbook --ask-vault-pass idx_cluster_bundle_push.yml
    # ansible-playbook --ask-vault-pass deployer_bundle_push.yml
4.) After the playbook runs, there are a few validation steps you can take
    # Log into a search head and run a search
    # index="internal" | stats count by host
    # Confirm that 14 hosts have sent their internal logs
    # index=linux
    # Check that you can now see the linux logs being collected from the Linux hosts
    # Go to the Deployment Server and see that your serverclasses are set up and functioning
    # Go to the Cluster Master Splunk Web and go to Settings > Indexer Clustering to see that your clustering is set up and working

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
