# OCI Network Basic Terraform IaC
This Terraform code deploys a networking scheme in OCI to manage basic deployments. It consists of two subnets, which are divided into the following categories.

- *SUBNET_PUBLIC:* This network is for public purposes, in case it is necessary to deploy a resource that can be used from any point (for example, a VPN).
- *SUBNET_PRIVATE:* This network is for private purposes, in case it is necessary to deploy a resource that can be used internally (for example, a database).

## Tools
[![Tools](https://skillicons.dev/icons?i=github,terraform&theme=dark)](https://registry.terraform.io/providers/oracle/oci/latest/docs)

## Execute Terraform Template
[![Deploy to Oracle Cloud](https://oci-resourcemanager-plugin.plugins.oci.oraclecloud.com/latest/deploy-to-oracle-cloud.svg)](https://cloud.oracle.com/resourcemanager/stacks/create?zipUrl=https://github.com/oci-ht/oci-network-basic-terraform/archive/refs/tags/1.0.zip)