terraform {
  required_providers {
    harness = {
      source = "harness/harness"
      version = "0.14.10"
    }
  }
}


resource "harness_platform_project" "project" {
  identifier = "cdproduct"
  name       = "cdproduct"
  org_id     = "default"
  color      = "#0063F7"
}

