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
     helm = {
      source  = "hashicorp/helm"
      version = "2.4.1"
    }
  }
}

provider "azurerm" {
  subscription_id = var.azure-subscription-id
  client_id       = var.azure-client-id
  client_secret   = var.azure-client-secret
  tenant_id       = var.azure-tenant-id

  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = "${var.app-name}-rg"
  location = "Canada Central"
}

resource "azurerm_kubernetes_cluster" "cluster" {
  name                = "${var.app-name}-cluster"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "${var.app-name}Cluster"

  default_node_pool {
    name       = "nodes"
    node_count = "3"
    vm_size    = "standard_d2_v2"
  }

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_postgresql_server" "db" {
  name                = "${var.app-name}-psqlserver"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  administrator_login          = var.postgresql-admin-login
  administrator_login_password = var.postgresql-admin-password

  sku_name   = "GP_Gen5_4"
  version    = "11"

  # storage_mb = 500000
  # backup_retention_days        = 7
  # geo_redundant_backup_enabled = true
  # auto_grow_enabled            = true

  # TODO: Can we disabled public network access and use SSL?
  public_network_access_enabled    = true
  ssl_enforcement_enabled          = false
  # ssl_minimal_tls_version_enforced = "TLS1_2"
}

# Create a PostgreSQL Database
resource "azurerm_postgresql_database" "postgresql-db" {
  name                = "demo_production"
  resource_group_name = azurerm_resource_group.rg.name
  server_name         = azurerm_postgresql_server.db.name
  charset             = "utf8"
  collation           = "English_United States.1252"
}

# Allow everything for now
resource "azurerm_postgresql_firewall_rule" "postgresql-fw-rules" {
  name                = "${var.app-name}-postgresql-fw-rules"
  resource_group_name = azurerm_resource_group.rg.name
  server_name         = azurerm_postgresql_server.db.name
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "255.255.255.255"
}

resource "azurerm_redis_cache" "redis" {
  name                = "${var.app-name}-cache"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  capacity            = 2
  family              = "C"
  sku_name            = "Standard"

  # TODO: Look into SSL
  enable_non_ssl_port = true
  # minimum_tls_version = "1.2"

  redis_configuration {
  }
}

# Allow everything for now
resource "azurerm_redis_firewall_rule" "redis-fw-rules" {
  name                = "${var.app-name}_redis_fw_rules"
  redis_cache_name    = azurerm_redis_cache.redis.name
  resource_group_name = azurerm_resource_group.rg.name
  start_ip            = "0.0.0.0"
  end_ip              = "255.255.255.255"
}

provider "helm" {
  kubernetes {
    host = azurerm_kubernetes_cluster.cluster.kube_config.0.host
    client_certificate = base64decode(azurerm_kubernetes_cluster.cluster.kube_config.0.client_certificate)
    client_key = base64decode(azurerm_kubernetes_cluster.cluster.kube_config.0.client_key)
    cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.cluster.kube_config.0.cluster_ca_certificate)
  }
}

provider "kubernetes" {
    host = azurerm_kubernetes_cluster.cluster.kube_config.0.host
    client_certificate = base64decode(azurerm_kubernetes_cluster.cluster.kube_config.0.client_certificate)
    client_key = base64decode(azurerm_kubernetes_cluster.cluster.kube_config.0.client_key)
    cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.cluster.kube_config.0.cluster_ca_certificate)
}
