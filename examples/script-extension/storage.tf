
module "storage" {
  source = "github.com/CloudNationHQ/az-cn-module-tf-sa"

  naming = local.naming

  storage = {
    name          = module.naming.storage_account.name_unique
    location      = module.rg.groups.demo.location
    resourcegroup = module.rg.groups.demo.name

    blob_properties = {
      versioning               = true
      last_access_time         = true
      change_feed              = true
      restore_policy           = true
      delete_retention_in_days = 8
      restore_in_days          = 7

      containers = {
        scripts = {
          access_type = "private"
        }
      }
    }
  }
}

resource "azurerm_role_assignment" "vmss_to_storage" {
  principal_id         = module.vmss.vmss.identity.0.principal_id
  role_definition_name = "Storage Blob Data Contributor"
  scope                = "${module.storage.account.id}/blobServices/default/containers/${module.storage.containers.scripts.name}"
}

resource "azurerm_storage_blob" "install_script" {
  name                   = "createfile"
  storage_account_name   = module.storage.account.name
  storage_container_name = module.storage.containers.scripts.name
  type                   = "Block"
  source                 = "${path.module}/createfile.sh"

  # Ensures that the blob will be updated if the source file changes.
  content_md5 = filemd5("${path.module}/createfile.sh")
}


# https://learn.microsoft.com/en-us/azure/virtual-machines/extensions/custom-script-linux#property-values
resource "azurerm_virtual_machine_scale_set_extension" "script_extension" {
  depends_on = [
    azurerm_storage_blob.install_script
  ]

  name                         = "script-extension"
  virtual_machine_scale_set_id = module.vmss.vmss.id
  publisher                    = "Microsoft.Azure.Extensions"
  type                         = "CustomScript"
  type_handler_version         = "2.1"

  protected_settings = jsonencode({
    "fileUris"         = ["${azurerm_storage_blob.install_script.url}"],
    "commandToExecute" = "mv createfile createfile.sh; chmod +x createfile.sh; sh createfile.sh ; ls -al",
    "managedIdentity" : {}
    }
  )
}
