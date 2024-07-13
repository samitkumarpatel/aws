# ec2-lab

### SSH to the machine
```sh
ssh -i id_rsa.pem -o StrictHostKeyChecking=no ubuntu@1.1.185.5

```

### Install docker

```sh
curl -fsSL https://get.docker.com | sudo sh -
sudo usermod -aG docker $USER

```