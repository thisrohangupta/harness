terraform {
  required_providers {
    harness = {
      source = "harness/harness"
      version = "0.14.10"
    }
  }
}


resource "harness_platform_service" "service" {
  identifier  = "nginx" ## Service Identifier
  name        = "nginx" ## Service Name to appear in Harness
  description = "sample nginx app created via Harness terraform Provider"  
  org_id      = "default" ## Replace with Harness Org Identifier for the resource
  project_id  = "cdproduct" ## Replace with your Harness Project Identifier
  yaml = <<-EOT
                service:
                  name: nginx 
                  identifier: nginx 
                  serviceDefinition:
                    spec:
                      manifests:
                        - manifest:
                            identifier: nginxManifest
                            type: K8sManifest
                            spec:
                              store:
                                type: Github
                                spec:
                                  connectorRef: <+input> 
                                  gitFetchType: Branch
                                  paths:
                                    - /deploy/
                                  repoName: <+input> 
                                  branch: master
                              skipResourceVersioning: false
                      configFiles:
                        - configFile:
                            identifier: configFile1
                            spec:
                              store:
                                type: Harness
                                spec:
                                  files:
                                    - <+org.description>
                      variables:
                        - name: port
                          type: String
                          value: 8080
                        - name: namespace
                          type: String
                          value: <+service.name>-<+env.name>
                    type: Kubernetes
                  gitOpsEnabled: false
              EOT
}

provider "harness" {
  endpoint = "https://app.harness.io/gateway"
  account_id = "YOUR_HARNESS_ACCOUNT_ID"
  platform_api_key = "YOUR_PAT"
}
