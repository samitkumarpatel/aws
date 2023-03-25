# aws
- [initial setup](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

Generate the Access Key and Secrets from IAM than make that avilable on your shell / bash

```sh
vi ~/.filename
export AWS_ACCESS_KEY_ID="anaccesskey"
export AWS_SECRET_ACCESS_KEY="asecretkey"
Esc , wq!

source ~/.filename

```


```sh
EC2 (draft)
- vpc
- Route Table (vpcCIDR - local, 0.0.0.0/0 - Internet Gateway) / attach your expected subnet
- Internet Gateway (attach this gateway with the VPC you want)

- network-interface
    - private ipv4
    - security-group
    - subnet
        - publicIp = true/false based that It will assign a public ipv4
```

- CIDR 

Possible subnet CIDR for vpc with CIDR 10.0.0.0/24

- 10.0.0.0/25 (128 IP addresses)
- 10.0.0.128/25 (128 IP addresses)
- 10.0.0.0/26 (64 IP addresses)
- 10.0.0.64/26 (64 IP addresses)
- 10.0.0.128/26 (64 IP addresses)
- 10.0.0.192/26 (64 IP addresses)
- 10.0.0.0/27 (32 IP addresses)
- 10.0.0.32/27 (32 IP addresses)
- 10.0.0.64/27 (32 IP addresses)
- 10.0.0.96/27 (32 IP addresses)
- 10.0.0.128/27 (32 IP addresses)
- 10.0.0.160/27 (32 IP addresses)
- 10.0.0.192/27 (32 IP addresses)
- 10.0.0.224/27 (32 IP addresses)
