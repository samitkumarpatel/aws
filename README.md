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

- network-interface
    - private ipv4
    - security-group
    - subnet
        - public ipv4
```