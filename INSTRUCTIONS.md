# INSTRUCTION TO RUN THIS PROJECT

## Preparation

This part is to prepare environment to run this project.

Make sure you have the following:
1.  GitHub account
2.  Amazon Web Service (AWS) Console account
3.  Docker Hub account
4.  ```git```, ```aws-cli```, ```ansible```, ```terraform```, ```openssh``` installed

Steps:
1.  Fork this repository to your own
2.  Clone your from your fork using ```git clone```
3.  ```cd``` to the source code directory that has just been cloned
4.  Configure Git so that it has access to your fork
5.  Login to AWS Console using ```aws login```

## Scaffold AWS EC2 K8S and Jenkins Instances

This part is to scaffold AWS EC2 instances for 2 k8s node (master and worker) and 1 jenkins node to build the docker image later.

Steps:
1.  ```cd``` to ```/terraform``` directory
2.  ```terraform init``` to initialize terraform
3.  ```terraform plan``` to check will be changed when the scaffolding began
4.  ```terraform apply``` to apply the infrastructure configuration

Ansible are also invoked as part of this scaffolding to configure the environment of the bare EC2 instance.

## Configure Jenkins

This part is to configure Jenkins for build and deploy pipeline with trigger from GitHub Webhook and deploy target to k8s cluster.

First Setup:
1.  SSH to jenkins-instace -> ```ssh -i <your-ssh-private-key> ec2-user@<your-jenkins-instance-public-dns-or-ip>```
2.  Open Jenkins dashboard on the jenkins-instance -> ```http://<your-jenkins-instance-public-dns-or-ip>:8080```
3.  Get the initial admin password using ```sudo cat /var/lib/jenkins/secrets/initialAdminPassword``` and copy it
4.  Paste the password into the "Administrator password" field and continue
5.  Choose "Select plugins to install", add the GitHub plugin, then install
6.  Create first admin user (fill accordingly), then save and continue
7.  Use default jenkins url, then save and finish

Configure Jenkins Nodes:
1.  Open Manage Jenkins -> Nodes -> Configure Monitors
2.  Checks all "Don't mark agents temporarily offline" (We actually had just enough resource, but Jenkins still flagged it below threshold), then apply and save
3. Back to Manage Jenkins -> Nodes, then open the built in node
4. Press the "Bring this node back online" button

Configure Jenkins Credentials:
1.  Open Manage Jenkins -> Credentials
