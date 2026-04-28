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
6.  Add your ssh key using ```ssh-add``` if you use passphrase to lock the private key

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
2.  Add Credentials -> Username with password
3.  Add your Docker Hub username and password (Personal Access Token), then ID as ```dockerhub-credentials``` -> Create
4.  Connect to your jenkins instance then run ```cat ~/.ssh/id_ed25519```, and copy the result (This is your SSH private key)
5.  Add Credentials -> SSH Username with private key
6.  Add username as ec2-user and for private key paste the result from step 4, then ID as ```k8s-ssh-key``` -> Create

Configure Jenkins environment variables:
1.  Open Manage Jenkins -> System
2.  On Global properties -> Check Environment variables
3.  Add environment variable with:
    -   Name: ```DOCKER_IMAGE```, Value: \<your docker image name\>
    -   Name: ```DOCKER_TAG```,
    Value: \<your docker tag name\>
    -   Name:
    ```K8S_MASTER_IP```, Value: \<your k8s master ip address\>
4.  Apply and Save

Create Jenkins job:
1.  Create a job -> Item name fill accordingly -> Item type Pipeline -> Ok
2.  On Triggers -> Check Github hook trigger for GITScm polling
3.  On Pipeline Definition -> Change to Pipeline script from SCM
4.  Select SCM using Git -> Repository URL using your GitHub repository fork url -> Branch to buiild change to ```*/main```

Create webhook for Jenkins job:
1.  Go to your GitHub repository fork -> Settings -> Webhooks
2.  Add webhook -> Verify your account if asked
3.  Payload URL use the default jenkins url then add /github-webhook (http://\<your jenkins url\>/github-webhook/)
4.  Content type use application/json
5.  Disable SSL verification (We don't setup SSL certificate here)
6.  Add webhook

## Test Pipeline

This part is to test the pipeline

Steps:
1.  Make a change in your local repository.
2.  ```git add .``` to add your change to staging.
3.  ```git commit -m "<your message>"``` to commit your change.
4.  ```git push -u origin main``` to push your change to remote repository.
5.  Watch the build and deployment from jenkins dashboard.
6.  After the previous steps completes, go to the k8s master node and check if the application actually deployed.