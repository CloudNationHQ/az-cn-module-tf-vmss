# Virtual Machine Scale Sets

This terraform module enables flexible and efficient management of virtual machine scale sets on azure through customizable configuration options.

## Goals

The main objective is to create a more logic data structure, achieved by combining and grouping related resources together in a complex object.

The structure of the module promotes reusability. It's intended to be a repeatable component, simplifying the process of building diverse workloads and platform accelerators consistently.

A primary goal is to utilize keys and values in the object that correspond to the REST API's structure. This enables us to carry out iterations, increasing its practical value as time goes on.

A last key goal is to separate logic from configuration in the module, thereby enhancing its scalability, ease of customization, and manageability.

## Features

- the capability to handle multiple SSH keys.
- the inclusion of multiple network interfaces.
- the support for multiple data disks.
- the flexibility to incorporate multiple extensions
- utilization of terratest for robust validation.
- autoscaling capabilities with the use of multiple rules.

The below examples shows the usage when consuming the module:

## Usage: simple

```hcl
module "vmss" {
  source = "github.com/cloudnationhq/az-cn-module-tf-vmss"

  vmss = {
    name           = module.naming.virtual_machine_scale_set.name
    location       = module.rg.groups.demo.location
    resource_group = module.rg.groups.demo.name
    keyvault       = module.kv.vault.id

    interfaces = {
      internal = {
        subnet  = module.network.subnets.internal.id
        primary = true
      }
    }

    ssh_keys = {
      adminuser = {
        public_key = module.kv.tls_public_keys.vmss.value
      }
    }
  }
}
```

## Usage: network interfaces

```hcl
module "vmss" {
  source = "github.com/cloudnationhq/az-cn-module-tf-vmss"

  vmss = {
    name           = module.naming.virtual_machine_scale_set.name
    location       = module.rg.groups.demo.location
    resource_group = module.rg.groups.demo.name
    keyvault       = module.kv.vault.id

    interfaces = {
      internal = { subnet = module.network.subnets.internal.id, primary = true }
      mgmt     = { subnet = module.network.subnets.mgmt.id }
    }

    ssh_keys = {
      adminuser = {
        public_key = module.kv.tls_public_keys.vmss.value
      }
    }
  }
}
```

## Usage: data disks

```hcl
module "vmss" {
  source = "github.com/cloudnationhq/az-cn-module-tf-vmss"

  vmss = {
    name           = module.naming.virtual_machine_scale_set.name
    location       = module.rg.groups.demo.location
    resource_group = module.rg.groups.demo.name
    keyvault       = module.kv.vault.id

    data_disks = {
      disk1 = { lun = 10, caching = "ReadWrite" }
      disk2 = { lun = 11, caching = "ReadWrite" }
    }

    interfaces = {
      internal = { subnet = module.network.subnets.internal.id, primary = true }
      mgmt     = { subnet = module.network.subnets.mgmt.id }
    }

    ssh_keys = {
      adminuser = {
        public_key = module.kv.tls_public_keys.vmss.value
      }
    }
  }
}
```

## Usage: extensions

```hcl
module "vmss" {
  source = "github.com/cloudnationhq/az-cn-module-tf-vmss"

  vmss = {
    name           = module.naming.virtual_machine_scale_set.name
    location       = module.rg.groups.demo.location
    resource_group = module.rg.groups.demo.name
    keyvault       = module.kv.vault.id

    interfaces = {
      internal = { subnet = module.network.subnets.internal.id, primary = true }
      mgmt     = { subnet = module.network.subnets.mgmt.id }
    }

    extensions = {
      DAExtension = {
        publisher            = "Microsoft.Azure.Monitoring.DependencyAgent"
        type                 = "DependencyAgentLinux"
        type_handler_version = "9.5"
      }
    }

    ssh_keys = {
      adminuser = {
        public_key = module.kv.tls_public_keys.vmss.value
      }
    }
  }
}
```

## Usage: autoscale

```hcl
module "vmss" {
  source = "github.com/cloudnationhq/az-cn-module-tf-vmss"

  vmss = {
    name           = module.naming.virtual_machine_scale_set.name
    location       = module.rg.groups.demo.location
    resource_group = module.rg.groups.demo.name
    keyvault       = module.kv.vault.id

    autoscaling = {
      enable = true
      profile = {
        scale_min = 1
        scale_max = 5
        rules = {
          increase = { metric_name = "Percentage CPU", time_grain = "PT1M", statistic = "Average", time_window = "PT5M", time_aggregation = "Average", operator = "GreaterThan", threshold = 80, direction = "Increase", value = 1, cooldown = "PT1M", type = "ChangeCount" }
          decrease = { metric_name = "Percentage CPU", time_grain = "PT1M", statistic = "Average", time_window = "PT5M", time_aggregation = "Average", operator = "LessThan", threshold = 20, direction = "Decrease", value = 1, cooldown = "PT1M", type = "ChangeCount" }
        }
      }
    }

    interfaces = {
      internal = { subnet = module.network.subnets.internal.id, primary = true }
      mgmt     = { subnet = module.network.subnets.mgmt.id }
    }

    ssh_keys = {
      adminuser = {
        public_key = module.kv.tls_public_keys.vmss.value
      }
    }
  }
}
```

## Resources

| Name | Type |
| :-- | :-- |
| [azurerm_resource_group](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) | resource |
| [random_string](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |
| [tls_private_key](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) | resource |
| [azurerm_key_vault_secret](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_secret) | resource |
| [azurerm_linux_virtual_machine_scale_set](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_virtual_machine_scale_set) | resource |

## Inputs

| Name | Description | Type | Required |
| :-- | :-- | :-- | :-- |
| `vmss` | contains all virtual machine scaleset config | object | yes |
| `naming` | contains naming convention	| string | yes |

## Outputs

| Name | Description |
| :-- | :-- |
| `vmss` | contains all virtual machine scale sets |

## Testing

The github repository utilizes a Makefile to conduct tests to evaluate and validate different configurations of the module. These tests are designed to enhance its stability and reliability.

Before initiating the tests, please ensure that both go and terraform are properly installed on your system.

The [Makefile](Makefile) incorporates three distinct test variations. The first one, a local deployment test, is designed for local deployments and allows the overriding of workload and environment values. It includes additional checks and can be initiated using the command ```make test_local```.

The second variation is an extended test. This test performs additional validations and serves as the default test for the module within the github workflow.

The third variation allows for specific deployment tests. By providing a unique test name in the github workflow, it overrides the default extended test, executing the specific deployment test instead.

Each of these tests contributes to the robustness and resilience of the module. They ensure the module performs consistently and accurately under different scenarios and configurations.

## Notes

Using a dedicated module, we've developed a naming convention for resources that's based on specific regular expressions for each type, ensuring correct abbreviations and offering flexibility with multiple prefixes and suffixes

Full examples detailing all usages, along with integrations with dependency modules, are located in the examples directory

## Authors

Module is maintained by [these awesome contributors](https://github.com/cloudnationhq/az-cn-module-tf-vmss/graphs/contributors).

## License

<<<<<<< HEAD
MIT Licensed. See [LICENSE](https://github.com/cloudnationhq/az-cn-module-tf-vmss/blob/main/LICENSE) for full details.
=======
MIT Licensed. See [LICENSE](https://github.com/cloudnationhq/az-cn-module-tf-kv/blob/main/LICENSE) for full details.
>>>>>>> 08930e6e30b9259c1e7d7ca3ed056ecf99234e44

## Reference

- [Documentation](https://learn.microsoft.com/en-us/azure/virtual-machine-scale-sets/)
- [Rest Api](https://learn.microsoft.com/en-us/rest/api/compute/virtual-machine-scale-sets)
- [Rest Api Specs](https://github.com/Azure/azure-rest-api-specs/blob/main/specification/compute/resource-manager/Microsoft.Compute/ComputeRP/stable/2023-03-01/virtualMachineScaleSet.json)
<<<<<<< HEAD
=======

>>>>>>> 08930e6e30b9259c1e7d7ca3ed056ecf99234e44
