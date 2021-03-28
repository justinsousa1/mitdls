Modules are good containers for terraform code that should stay together. You can further organize that code
by having modules inside of a module. Organizing it this way helps you see the boundaries of the various resources you are
creating in the tf code and helps to avoid having all your terraform code in one giant file.