# export ARM_CLIENT_ID=<insert the appId from above>
# export ARM_SUBSCRIPTION_ID=<insert your subscription id>
# export ARM_TENANT_ID=<insert the tenant from above>
# export ARM_CLIENT_SECRET=<insert the password from above>

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.90.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = "demoResourceGroup"
  location = "Canada Central"
}

resource "azurerm_kubernetes_cluster" "cluster" {
  name                = "democluster"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "democluster"

  default_node_pool {
    name       = "default"
    node_count = "2"
    vm_size    = "standard_d2_v2"
  }

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_kubernetes_cluster_node_pool" "mem" {
 kubernetes_cluster_id = azurerm_kubernetes_cluster.cluster.id
 name                  = "mem"
 node_count            = "1"
 vm_size               = "standard_d11_v2"
}
