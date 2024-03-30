# ec2-efs-ansible

Command to see all mount point 

```sh
df -k
```

**Terraform ansible provider**

1. Install ansible

```sh
python3 -m venv .venv
source .venv/bin/activate
pip3 install ansible
```  

2. Install ansible-galaxy collection. want to know [why? read here](https://galaxy.ansible.com/ui/repo/published/cloud/terraform/) ?

> Make sure `Requires Ansible>=2.14.0`
In short: This will help generate dynamic inventory from state file

```sh
ansible-galaxy collection install cloud.terraform
```

3. Make sure you have `ansible_host` resources in your `.tf` file
> main.tf has this example...
```hcl
    ....

    resource "ansible_host" "host" {
        count  =  2
        name   = aws_instance.foo[count.index].public_ip
        groups = ["ec2"]
        variables = {
            ansible_user                  = "ubuntu"
            ansible_ssh_private_key_file  = "~/lenovo.pem"
            ansible_connection            = "ssh"
        }
    }
```

4. Create a `inventory.yml` file and have the below entry on to that file

> Check the inventory.yml file in this folder for example

```yml
---
plugin: cloud.terraform.terraform_provider
```

5. Run terraform

```sh
terraform init
terraform --validate
terraform apply --auto-approve
```

6. Check how your host file looks
```sh
ansible-inventory -i inventory.yml --list --vars
# OR
ansible-inventory -i inventory.yml --graph --vars
```
7. Create a ansible playbook.yml file (check the playbook.yml in this folder)

8. Run ansible

```sh
ansible-playbook -i inventory.yml playbook.yml 
```