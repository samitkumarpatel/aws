## ansible with ec2

Once you have the `.pem` file in place and if you know the default user name (like for amazon linux it will be `ec2-user`, for ubuntu it's `ubuntu`) then just check if anisble can ping that ec2 instace/instances, To test , use ansible adhoc command line.


```sh
ansible -i "16.171.132.116," 16.171.132.116 -m ping -e ansible_ssh_private_key_file=/path/to/ec2.pem -e ansible_user=ubuntu --become-user ubuntu
```
> Initialy It will ask you to add the trust in your id_rsa file (default ssh thingi...) and you have to accept first time :) .

If it works , the output will look something similar like below in green

```
16.171.132.116 | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "ping": "pong"
}

```

### playbook to install nginx

This playbook is gonna install nginx and add a custom home page to it.
> Before you begin make your you updated the ec2 public Ip in `ansible/inventory.ini` file.

```sh
ansible-playbook -i ansible/inventory.ini ansible/playbook.yml -u ubuntu

[OR]

ansible-playbook -i ansible/inventory.ini ansible/playbook.yml
```