Note: this is not running code. serves as a framework for a discussion

Task:
- standup a wordpress site w/ efs drives for static content

IaC tooling: Use your choice of Ansible, Terraform, CloudFormation, etc...
Assumptions: 
- 2 separate VPCs are created, one for staging and one for prod and all routing is taken care of re: IGW/NatGateway etc.
- starting from base AMIs (I'll assume Amazon Linux 2)
