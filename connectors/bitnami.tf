terraform {
  required_providers {
    harness = {
      source = "harness/harness"
      version = "0.14.10"
    }
  }
}

resource "harness_platform_connector_helm" "helm" {
  identifier  = "bitnami"
  name        = "bitnami"
  description = "bitnami helm connector"
  tags        = ["owner:dev"]

  url                = "hhttps://charts.bitnami.com/bitnami"
  delegate_selectors = ["harness-delegate"]
}

provider "harness" {
  endpoint = "https://app.harness.io/gateway"
  account_id = "YOUR_HARNESS_ACCOUNT_ID"
  platform_api_key = "YOUR_PAT"
}

