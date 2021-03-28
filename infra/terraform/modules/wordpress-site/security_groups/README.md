I find that creating the security groups in a standalone module and exposing those as outputs to other modules as needed has worked well. 
Consumers of the security groups (SGs) can then attach those SGs as they need. I've also found that in a few cases it helps
to manage the rules on SGs separate from the creation of the SGs themselves. In situations where the rules may change more
frequently than the attachments of the SGs to different resources, the model of having a different set of code to manage the
rules has worked well. This really makes a bit more sense for external rules though whereas rules for
traffic internal to the vpc/between app components should really be managed in the terraform code using them. I like to label the
SG rules and sometimes the SGs themselves as having a rule_domain of "internal" or "external". Where internal is for machine
to machine/ app to app communication that often stays within the vpc /aws account. External is for traffic reaching out of the 
vpc or coming into the vpc from the internet/VPNs.
