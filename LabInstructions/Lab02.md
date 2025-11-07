# Lab VAL02 - Terraform Validation

## Objective
The aim of this lab is to apply validations to terraform configurations using policy-as-code

## Outcomes
By the end of this lab, you will have:
* Used terrascan to validate that terraform configs adhere to common standards of security
* Created a custom terrascan policy and validated it
* Used Sentinel to implement a custom policy in HCL

## High-Level Steps
* Install terrascan
* Run terrascan with default policies
* Create and validate a custom policy
* install Hashicorp Sentinel
* Define and validate a sentinel policy.

## Detailed Steps

### Install terrascan
1. Terrascan can be installed via the following commands:
```bash
curl -L "$(curl -s https://api.github.com/repos/tenable/terrascan/releases/latest | grep -o -E "https://.+?_Linux_x86_64.tar.gz")" > terrascan.tar.gz
tar -xf terrascan.tar.gz terrascan && rm terrascan.tar.gz
sudo install terrascan /usr/local/bin && rm terrascan
```
2. Confirm the installation:
```bash
terrascan
```
3. Change directory into the lab02 directory: `cd ~/validation-labs/lab02`
4. Review the provided terraform files - they should be familiar to you as we have worked with them in an earlier lab
5. To validate the files against terrascan's default policies, run `terrascan scan`
6. Notice that the scan is successful, but there are several warnings about files not being present. Terrascan is actually a portable policy enforcement tool which supports a wide range of configurations, not just terraform.
7. Re-run the scan command, but this time add `-i terraform` to specify that only terraform validations should be attempted:
```bash
terrascan scan -i terraform
```
8. We can further filter the validations that are applied by using the `-t` flag to specify that we want the validations relevant to a specific provider:
```bash
terrascan scan -i terraform -t gcp
```
9. We can also define our own custom policies for terrascan. To create a terrascan policy we need two things, a rule file and the validation logic. The validation logic is defined using a syntax called 'rego'.
10. Create a new file called ssh_rule.rego, and add the following
```rego
package accurics

tcp_port_22_open[api.id] {
    api := input.google_compute_firewall[_]
    rule := api.config.allow[_]
    port := rule.ports[_]
    contains(lower(port), "22")
    api.config.direction == "INGRESS"
    api.config.source_ranges[_] == "0.0.0.0/0"
}
```
This rego file checks for any firewall rules that expose port 22 (SSH) to all IP addresses - this is something that in the real world you would want to restrict.
10. A rule file is a JSON file that defines metadata about the rule. Create a file called AC_GCP_1000 and add the contents below, which reference the rule file we created:
```json
{
	"name": "nopublicssh",
	"file": "ssh_rule.rego",
	"policy_type": "gcp",
	"resource_type": "google_compute_firewall",
	"severity": "HIGH",
	"description": "It is recommended that no security group allows unrestricted SSH access",
	"category": "NETWORK_SECURITY",
	"version": 1,
	"id": "AC_GCP_1000"
}
```
11. Once you have created both these files, run terrascan again, this time using the -p flag to specify the path to the directory that has the rules in:
```bash
terrascan scan -i terraform -t gcp -p .
```
Note that the output shows only one validation performed this time.

### Policy Enforcement With Sentinel
Hashicorp, the organisation behind terraform, offer their own policy-as-code solution in the form of _Sentinel_. We will compare and contrast with Terrascan
1. Install Sentinel on the cloud shell instance:
```bash
wget https://releases.hashicorp.com/sentinel/0.40.0/sentinel_0.40.0_linux_amd64.zip
unzip sentinel_0.40.0_linux_amd64.zip
sudo cp sentinel /usr/local/bin
sentinel version
``` 
2. Create a new sentinel file called enforce_cidr_restrictions.sentinel, adding the following contents:
```sentinel
import "tfplan/v2"
import "strings"
import "types" 

allowed_source_ranges = [
  "10.0.1.0/24",      # own subnet
  "130.211.0.0/22",   # Specific external network
  "35.191.0.0/16",     # Google Cloud Health Check ranges (important for ingress!)
]

all_firewall_rules_valid = rule {
  allowed_source_ranges contains "10.0.1.0/24"
}

# Enforce the rule
main = rule {
  all_firewall_rules_valid
}
```
3. Sentinel works on terraform plan data, so in order to see this policy in action we have to do a little more work. Generate a plan file by running:
```bash
pip3 install sentinel-mock-plan
terraform plan -json > mock-plan.json
python3 -m sentinel_mock_plan --infile mock-plan.json --outfile mock-tfplan.sentinel
```
4. Now define sentinel configuration settings, in a file called sentinel.hcl:
```
mock "tfplan/v2" {
  module {
    source = "mock-tfplan.sentinel"
  }
}
```
Now when sentinel runs, the generated plan will be picked up as a mock of the data structure that hashicorp cloud feeds into sentinel automatically when using terraform cloud
5. Invoke the policy with sentinel apply:
```bash
sentinel apply enforce_cidr_restrictions.sentinel
```
The policy should pass.
6. Edit enforce_cidr_restrictions, and change "10.0.1.0/24" to "0.0.0.0/0" to the allowed_source_ranges.
<!-- 7. Regenerate the mock plan data with the new config:
```bash
terraform show -json > mock-tfplan.sentinel
```-->
7. Run `sentinel apply enforce_cidr_restrictions.sentinel` again - sentinel should pick up the 'misconfiguration' and fail the validation.

#### Comparison of Sentinel and Terrascan
Considering the differences between Sentinel and Terrascan, Terrascan has the benefits of being usable with other forms of configuration and being easier to get started with out of the box thanks to the default library of policies. Sentinel, however, benefits from strong integration with terraform cloud/enterprise, and the use of HCL means a more familiar syntax for those familiar with terraform already
 
