# Lab VAL03 - Monitoring With Zabbix

## Objective
Deploy a set of resources with Zabbix deployed for monitoring

## Outcomes
By the end of this lab, you will have:
* Deployed infrastructure with Terraform and configured Zabbix on the infrastructure using Ansible

## High-Level Steps
* Provision infrastructure
* Configure with ansible
* Configure Host in Zabbix UI

## Detailed Steps

### Provision the Infrastructure
1. Change directory into the lab folder:
```bash
cd ~/validation-labs/lab03
```
2. Begin by reviewing the configuration - much of it should be familiar by now, but there is some new configuration, namely the use of `docker` to deploy the Zabbix components.
3. Switch into the terraform directory, which contains the config needed to build the infra.
4. Generate an SSH key pair:
```bash
ssh-keygen -t ed25519 -f ./ansible_key -q
```
5. Export the information that Terraform needs as environment variables:
```bash
export TF_VAR_gcp_project=$(gcloud config get project)
export TF_VAR_pubkey_path=$(pwd)/ansible_key.pub
```
6. Run a terraform init and apply:
```bash
terraform init
terraform apply
```
7. Wait for the resources to be provisioned

### Configure the Servers
1. Now we need to configure our servers. Install ansible:
```bash
sudo apt-get install -y software-properties-common
sudo apt-add-repository ppa:ansible/ansible
sudo apt-get install -y ansible
```
2. Update the project ID in the inventory template:
```bash
ansible 127.0.0.1 -m template -a "src=$(pwd)/inventory_template.yml dest=$(pwd)/inventory.gcp_compute.yml" -e "project_id=${TF_VAR_gcp_project}"
```
3. Execute the playbook:
```bash
ansible-playbook -i inventory.gcp_compute.yml playbook.yml
```
4. It will take a few minutes to fully configure all resources

### Log into Zabbix UI and Configure Hosts
1. Although the Zabbix agent is running on the servers being monitored, Zabbix will not register them automatically, so we will need to configure host entries in Zabbix itself.
2. Navigate to the external IP of your Zabbix server, and you should be confronted by a login screen (note: as with AWX, some errors during the initialisation process are normal, so wait a few minutes until the server is ready)
3. The default superuser credentials for zabbix are username: Admin, password: zabbix, so log in with these credentials
4. Once you are logged in, from the side menu navigate to Data Collection > Hosts, and add a new host. Provide as the hostname the IP of one of your appserver instances, and create a new host group called appservers
5. Repeat for your second app server, adding it to the now already-existing appservers group
6. Configure a third host for the proxy server - for this, create another new host group called 'proxies'
7. There should now be communication between the zabbix server and agents. It will take some time for the first data to start being populated, so wait and see what data you get.
8. Try increasing the load on the servers by spamming the proxy with curl requests from your cloudshell:
```bash
while true; do wget -O- http://<proxy-ip>; done
``` 
See if you notice any evidence of the work the servers are doing in the Zabbix dashboard.