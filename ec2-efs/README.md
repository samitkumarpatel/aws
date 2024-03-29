# EFS

**Teraform commond**

```sh
terraform init
terraform plan
terraform apply --auto-approve
```

**Ansible to mount efs to ec2**

```sh
ansible-playbook -i inventory.ini playbook.yml
```

Login to EC2 and check if it's been mount or not 

```sh
df -k

```
