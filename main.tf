provider "azurerm" {
  version = "=2.5.0"
  features {}
}

resource "random_password" "password" {
  length = 16
  special = true
  override_special = "_%@"
}

resource "azurerm_resource_group" "minecraft" {
  name     = "lauriecraft"
  location = "West Europe"
}

resource "azurerm_storage_account" "minecraft" {
  name                     = "lauriecrafttf"
  resource_group_name      = azurerm_resource_group.minecraft.name
  location                 = azurerm_resource_group.minecraft.location
  account_tier             = "Standard"
  account_replication_type = "GRS"

  tags = {
    environment = "production"
    sideproject = "lauriecraft"
  }
}

resource "azurerm_storage_share" "minecraft_world" {
  name = "world"
  storage_account_name = azurerm_storage_account.minecraft.name
  quota = 5
}

resource "azurerm_storage_share" "minecraft_config" {
  name                 = "config"
  storage_account_name = azurerm_storage_account.minecraft.name
  quota                = 1
}

resource "azurerm_container_group" "minecraft" {
  name                = "minecraft"
  location            = azurerm_resource_group.minecraft.location
  resource_group_name = azurerm_resource_group.minecraft.name
  ip_address_type     = "public"
  dns_name_label      = "lauriecrafttf"
  os_type             = "Linux"

  container {
    name   = "studio"
    image = "hashicraft/minecraft:v1.12.2"
    cpu = "1"
    memory = "1"

    # Main minecraft port
    ports {
      port     = 25565
      protocol = "TCP"
    }

    volume {
      name = "world"
      mount_path = "/minecraft/world"
      storage_account_name = azurerm_storage_account.minecraft.name
      storage_account_key = azurerm_storage_account.minecraft.primary_access_key
      share_name = azurerm_storage_share.minecraft_world.name  
    }

    volume {
      name = "config"
      mount_path = "/minecraft/config"
      storage_account_name = azurerm_storage_account.minecraft.name
      storage_account_key = azurerm_storage_account.minecraft.primary_access_key
      share_name = azurerm_storage_share.minecraft_config.name  
    }

    environment_variables = {
      JAVA_MEMORY="1G",
      MINECRAFT_MOTD="LaurieCraft",
      WHITELIST_ENABLED=true,
      RCON_ENABLED=true,
      RCON_PASSWORD=random_password.password.result
    }
  }
}

output "fqdn" {
  value = azurerm_container_group.minecraft.fqdn
}

output "rcon_password" {
  value = random_password.password.result
}
