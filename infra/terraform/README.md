Some terraform code broken out into modules and then instantiations of the modules in accounts.
This setup has worked well at my current company. For one repo in particular, we've been using terragrunt as a wrapper around
calling terraform. It has worked really well for that repo, but I think the overhead of having to learn another tool can sometimes
be a bit much for development teams and it requires being really disciplined in your IaC writing.

For some of the base AWS infra like a vpc I've used the aws provided/managed modules like this one [here](https://github.com/terraform-aws-modules/terraform-aws-vpc).
That stuff is straightforward enough that it's fine to use those modules, but for app specific code you should write your own
modules. For this case I'll assume that the VPCs/subnets/gateways are all taken care of.

tfenv is useful for supporting different terraform versions and works similarly to the more widely known pyenv
