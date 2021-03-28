An instantiation of the environment/codebase dedicated to a single developer. Requires a
unique name be available to all resources created by the terraform code. This can be done by using the
environment_name in the context variable that is in each module. Local scripts and terraform workspaces
can create a unique context with the environment_type = dev but environment_name = some unique identifier for the environment. 
This pattern has worked well at my current company. 