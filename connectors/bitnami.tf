resource "harness_platform_connector_helm" "helm" {
  identifier  = "bitnami"
  name        = "bitnami"
  description = "bitnami helm connector"
  tags        = ["owner:dev"]

  url                = "hhttps://charts.bitnami.com/bitnami"
  delegate_selectors = ["harness-delegate"]
}
