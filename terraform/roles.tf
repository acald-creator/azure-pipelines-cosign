data "azurerm_subscription" "primary" {}

resource "azurerm_role_assignment" "kv-crypto-officer-role" {
  scope                = data.azurerm_subscription.primary.id
  role_definition_name = "Key Vault Crypto Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}