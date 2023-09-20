provider "azurerm" {
  features {}
}

module "naming" {
  source = "github.com/cloudnationhq/az-cn-module-tf-naming"

  suffix = ["demo", "dev"]
}

module "rg" {
  source = "github.com/cloudnationhq/az-cn-module-tf-rg"

  groups = {
    demo = {
      name   = module.naming.resource_group.name
      region = "westeurope"
    }
  }
}

module "network" {
  source = "github.com/cloudnationhq/az-cn-module-tf-vnet"

  naming = local.naming

  vnet = {
    name          = module.naming.virtual_network.name
    location      = module.rg.groups.demo.location
    resourcegroup = module.rg.groups.demo.name
    cidr          = ["10.18.0.0/16"]

    subnets = {
      internal = { cidr = ["10.18.1.0/24"] }
    }
  }
}

module "kv" {
  source = "github.com/cloudnationhq/az-cn-module-tf-kv"

  naming = local.naming

  vault = {
    name          = module.naming.key_vault.name_unique
    location      = module.rg.groups.demo.location
    resourcegroup = module.rg.groups.demo.name

    secrets = {
      tls_keys = {
        vmss = {
          algorithm = "RSA"
          rsa_bits  = 2048
        }
      }
    }
  }
}

module "vmss" {
  source = "../../"

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
      internal = { subnet = module.vnet.network.internal.id, primary = true }
      mgmt     = { subnet = module.vnet.network.mgmt.id }
    }

    ssh_keys = {
      adminuser = {
        public_key = module.kv.tls_public_keys.vmss.value
      }
    }
  }
}
