terraform {
  required_providers {
    harness = {
      source = "harness/harness"
      version = "0.14.10"
    }
  }
}


resource "harness_platform_secret_text" "secret" {
  identifier  = "github_pat"
  name        = "github pat"
  description = "github personal access token"
  tags        = ["owner:dev"]

  secret_manager_identifier = "harnessSecretManager"
  value_type                = "Inline"
  value                     = "secret"
}


provider "harness" {
  endpoint = "https://app.harness.io/gateway"
  account_id = "YOUR_HARNESS_ACCOUNT_ID"
  platform_api_key = "YOUR_PAT"
}
