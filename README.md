## Terraform initialization

Pick proper one from below. Command should be run AFTER S3 bucket for state is created.
```
terraform init -backend-config=backend_dev.conf
terraform init -backend-config=backend_test.conf
terraform init -backend-config=backend_prod.conf
```

# Apply the change

Depending on the stage:

```
terraform apply -var-file=vars_dev.tfvars
terraform apply -var-file=vars_test.tfvars
terraform apply -var-file=vars_prod.tfvars
```