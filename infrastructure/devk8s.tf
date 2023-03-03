

resource "harness_platform_infrastructure" "infrastructure" {
  identifier      = "dev"
  name            = "devk8s"
  org_id          = "default"
  project_id      = "cdproduct"
  env_id          = "dev"
  type            = "KubernetesDirect"
  deployment_type = "Kubernetes"
  yaml            = <<-EOT
        infrastructureDefinition:
         name: dev-k8s
         identifier: devk8s
         description: "development kubernetes cluster"
         tags:
           owner: "devops"
         orgIdentifier: default
         projectIdentifier: cdproduct
         environmentRef: dev
         deploymentType: Kubernetes
         type: KubernetesDirect
         spec:
          connectorRef: devkubernetes
          namespace: dev
          releaseName: release-<+INFRA_KEY>
          allowSimultaneousDeployments: false
      EOT
}


provider "harness" {
  endpoint = "https://app.harness.io/gateway"
  account_id = "YOUR_HARNESS_ACCOUNT_ID"
  platform_api_key = "YOUR_PAT"
}
