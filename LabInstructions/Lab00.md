# Lab CICD00 - Environment Setup

## Objective
Launch the lab environment and configure required resources

## Steps
### Start the Lab
Log into your [qwiklabs](https://qa.qwiklabs.com) account, and click on the classroom tile. Click into the lab, and click the 'Start Lab' button. Once the lab has started, right click the 'console' button and click 'open in incognito/inprivate window'.

### Setup the Environment
Once logged into the cloud console, click the cloud shell icon in the top right. Wait for cloud shell to start, then open the cloud IDE editor as well. Pop the IDE out into a separate window so that you can navigate back and forth between the IDE and the console.

In a new terminal session in the IDE window, clone the lab files:
```bash
git clone https://github.com/qa-tech-training/validation-labs.git
```
Open the explorer pane in the editor and ensure you can see the newly cloned files.

### Edit GCE Metadata
These labs will require SSH access to VMs using self-managed SSH keys. By default, the compute engine in the qwiklabs projects has _oslogin_ enabled, which allows GCP to manage SSH access to VMs via IAM credentials. This will, however, block SSH using self-managed SSH keys, so we will need to disable it.  
In your cloud shell terminal, run the following:
```bash
gcloud config set project <qwiklabs project ID> # ensure project is set, in case cloud shell has not done so
export TF_VAR_gcp_project=$(gcloud config get project) # set this variable now, while we're at it
echo !! | tee -a ~/.bashrc # and set in in bashrc so that it persists
gcloud compute project-info add-metadata --metadata=enable-oslogin=false
```

### Install Ansible
We will need access to ansible on the cloudshell instance in order to complete subsequent setup steps:
```bash
sudo apt-add-repository --update --yes ppa:ansible/ansible
sudo apt-get install ansible
```