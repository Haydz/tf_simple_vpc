# tf_simple_vpc
This is a simple vpc created in Terraform. This allows quick and easy access to a VPC for testing and learning. The VPC creates a Public subnet with internet access and a private subnet.

## Please Note: 
### SSH key
Upon creation of the EC2 servers SSH keys are added. These are added from AWS itself, meaning from the console. There should be a saved user SSH key within AWS (normally made when launching an EC2 for the first time).

Within `variables.tf` edit the `SSHkey` variable to add your own.

### SSM Role
Each instance upon creation has an SSM role applied. This is a custom role. Please remove for whatever yole you need. This can be found in `variables.tf` in the `ssm_profile` variable


## Systems Created
2 Amazon Linux EC2s

## Networks
1 Public Subnet
1 Private Subnet

## Update Script supplied
A simple update script is supplied to show adding user data with Terraform



Diagram below shows simple VPC created:

![Network Diagram](https://github.com/Haydz/tf_simple_vpc/blob/main/network.png)
