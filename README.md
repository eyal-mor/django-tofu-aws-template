# Terraform Module for Running Django with Open Tofu

This project provides a Terraform module for deploying a Django application with Open Tofu. It includes examples of using Terragrunt, Docker, and GitHub Actions.

## Overview

This module deploys a Django application using Open Tofu, a lightweight and flexible framework for building web applications. The module is designed to be used with AWS, but can be adapted for other cloud providers.

## Features

- **Terraform**: Infrastructure as Code (IaC) tool for managing and provisioning cloud resources.
- **Terragrunt**: A thin wrapper for Terraform that provides extra tools for working with multiple Terraform modules.
- **Docker**: Containerization platform used to package the Django application and its dependencies into a single, standalone unit.
- **GitHub Actions**: CI/CD tool for automating build, test, and deploy workflows.

## Usage

To use this module, you'll need to have Terraform and Terragrunt installed. You'll also need an AWS account and your AWS credentials set up.

```hcl
module "django_open_tofu" {
  source = "git::https://github.com/eyal-mor/django-tofu-aws-template"

  # ... other variables ...
}
```

Then, run `terragrunt apply` to create the resources.

## Examples

This project includes several examples:

- **Terragrunt**: See the `terragrunt.hcl` file for an example of how to use Terragrunt with this module.
- **Docker**: See the `Dockerfile` for an example of how to containerize a Django application.
- **GitHub Actions**: See the `.github/workflows` directory for examples of GitHub Actions workflows.

## Contributing

Contributions to this project are welcome! Please submit a pull request or open an issue if you have something to contribute.

## License

This project is licensed under the MIT License. See the [`LICENSE`](./LICENSE) file for more details.
