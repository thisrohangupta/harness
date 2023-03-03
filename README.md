# Onboarding Automation to Harness via the Harness Terraform Provider

## Introduction

Usually, Harness users leverage the Terraform Provider to help automate scale their adoption and growth within the platform. Harness offers a first-class [Terraform Provider](https://developer.harness.io/docs/platform/terraform/harness-terraform-provider-overview/)

You can navigate to our Terraform Module Offering in the [HashiCorp Terrafrom Registry](https://registry.terraform.io/providers/harness/harness/latest/docs). Select the 'NextGen' Resources drop down to see all the resources we support with our Terraform Provider for the Harness Platform.

For this topic we have provided a [sample repository](https://github.com/thisrohangupta/harness)

## Onboarding Automation

We have some basics to help user's get started with the Harness Terraform Provider covered in our [Terraform Provider Quickstart](https://developer.harness.io/docs/platform/Terraform/harness-terraform-provider). In order to get started with Harness Terraform Provider automation, we recommend user's installing a delegate with the Terraform CLI configured. We will need this to build out the automation pipelines to create the various resources

### Sample Delegate YAML

Please review the Kubernetes [Delegate YAML Quickstart](https://developer.harness.io/docs/first-gen/firstgen-platform/account/manage-delegates/install-kubernetes-delegate/) to install a kubernetes delegate. You will need to download the YAML and make some changes before you apply the delegate yaml to your Kubernetes cluster.

We will be making changes to the `INIT_SCRIPT` field in this YAML. For more details on [INIT_SCRIPTS](https://developer.harness.io/docs/platform/delegates/delegate-reference/common-delegate-profile-scripts/#terraform)

```YAML
apiVersion: v1
kind: Namespace
metadata:
  name: harness-delegate-ng

---

apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: harness-delegate-ng-cluster-admin
subjects:
  - kind: ServiceAccount
    name: default
    namespace: harness-delegate-ng
roleRef:
  kind: ClusterRole
  name: cluster-admin
  apiGroup: rbac.authorization.k8s.io

---

apiVersion: v1
kind: Secret
metadata:
  name: terraform-proxy
  namespace: harness-delegate-ng
type: Opaque
data:
  # Enter base64 encoded username and password, if needed
  PROXY_USER: ""
  PROXY_PASSWORD: ""

---

apiVersion: apps/v1
kind: StatefulSet
metadata:
  labels:
    harness.io/name: terraform
  name: terraform
  namespace: harness-delegate-ng
spec:
  replicas: 1
  podManagementPolicy: Parallel
  selector:
    matchLabels:
      harness.io/name: terraform
  serviceName: ""
  template:
    metadata:
      labels:
        harness.io/name: terraform
    spec:
      containers:
      - image: harness/delegate:latest
        imagePullPolicy: Always
        name: harness-delegate-instance
        ports:
          - containerPort: 8080
        resources:
          limits:
            memory: "2048Mi"
          requests:
            cpu: "0.5"
            memory: "2048Mi"
        readinessProbe:
          exec:
            command:
              - test
              - -s
              - delegate.log
          initialDelaySeconds: 20
          periodSeconds: 10
        livenessProbe:
          exec:
            command:
              - bash
              - -c
              - '[[ -e /opt/harness-delegate/msg/data/watcher-data && $(($(date +%s000) - $(grep heartbeat /opt/harness-delegate/msg/data/watcher-data | cut -d ":" -f 2 | cut -d "," -f 1))) -lt 300000 ]]'
          initialDelaySeconds: 240
          periodSeconds: 10
          failureThreshold: 2
        env:
        - name: JAVA_OPTS
          value: "-Xms64M"
        - name: ACCOUNT_ID
          value: <YOUR ACCOUNT ID> ## Your Account ID will be generated here
        - name: MANAGER_HOST_AND_PORT
          value: https://app.harness.io
        - name: DEPLOY_MODE
          value: KUBERNETES
        - name: DELEGATE_NAME
          value: terraform
        - name: DELEGATE_TYPE
          value: "KUBERNETES"
        - name: DELEGATE_NAMESPACE
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace
        - name: INIT_SCRIPT
          value: | ## Install Terraform Here, You can use the latest version, of Terraform.
                curl -O -L  https://releases.hashicorp.com/terraform/0.12.25/terraform_0.12.25_linux_amd64.zip  
                unzip terraform_0.12.25_linux_amd64.zip  
                mv ./terraform /usr/bin/          
                terraform --version  
        - name: DELEGATE_DESCRIPTION
          value: ""
        - name: DELEGATE_TAGS
          value: ""
        - name: NEXT_GEN
          value: "true"
        - name: DELEGATE_TOKEN
          value: <YOUR DELEGATE TOKEN> ## Your Generated Delegate token will go here
        - name: WATCHER_STORAGE_URL
          value: https://app.harness.io/public/prod/premium/watchers
        - name: WATCHER_CHECK_LOCATION
          value: current.version
        - name: DELEGATE_STORAGE_URL
          value: https://app.harness.io
        - name: DELEGATE_CHECK_LOCATION
          value: delegateprod.txt
        - name: HELM_DESIRED_VERSION
          value: ""
        - name: CDN_URL
          value: "https://app.harness.io"
        - name: REMOTE_WATCHER_URL_CDN
          value: "https://app.harness.io/public/shared/watchers/builds"
        - name: JRE_VERSION
          value: 11.0.14
        - name: HELM3_PATH
          value: ""
        - name: HELM_PATH
          value: ""
        - name: KUSTOMIZE_PATH
          value: ""
        - name: KUBECTL_PATH
          value: ""
        - name: POLL_FOR_TASKS
          value: "false"
        - name: ENABLE_CE
          value: "false"
        - name: PROXY_HOST
          value: ""
        - name: PROXY_PORT
          value: ""
        - name: PROXY_SCHEME
          value: ""
        - name: NO_PROXY
          value: ""
        - name: PROXY_MANAGER
          value: "true"
        - name: PROXY_USER
          valueFrom:
            secretKeyRef:
              name: terraform-proxy
              key: PROXY_USER
        - name: PROXY_PASSWORD
          valueFrom:
            secretKeyRef:
              name: terraform-proxy
              key: PROXY_PASSWORD
        - name: GRPC_SERVICE_ENABLED
          value: "true"
        - name: GRPC_SERVICE_CONNECTOR_PORT
          value: "8080"
      restartPolicy: Always

---

apiVersion: v1
kind: Service
metadata:
  name: delegate-service
  namespace: harness-delegate-ng
spec:
  type: ClusterIP
  selector:
    harness.io/name: terraform
  ports:
    - port: 8080

```

Once you make these changes to the delegate yaml, please connect to the Kubernetes Cluster to install. You will need to run:

```SH
kubectl apply -f harness-delegate.yaml
```

To verify if the Terraform CLI was successfully installed please run the command:

```SH
kubectl logs <HARNESS_DELEGATE_POD_NAME> -n harness-delegate-ng
```

You can then search for "Terraform" to see if the CLI was installed successfully or not.

### Setup a Github Repo to host the Harness Configuration

We recommend user's to create a new Github Repo to store and manage the Harness Configuration. Please see Github's tutorial on [creating a new Github Repo](https://docs.github.com/en/get-started/importing-your-projects-to-github/importing-source-code-to-github/adding-locally-hosted-code-to-github#adding-a-local-repository-to-github-using-git). User's can also leverage an existing repo to manage the Harness Configuration.

We propose a management folder structure like below:

```md
service/
-- backend-service.tf
-- frontend-service.tf
-- transformer.tf

environments/
-- dev.tf
-- qa.tf
-- prod.tf 

infrastructure/
-- dev_k8s.tf
-- qa_k8s.tf
-- prod_k8s.tf 
```

### Store the automation pipeline

Harness recommends storing the automation pipeline to create and manage resources in a common project that many teams can access. You can create a project called "Onboarding" and users can leverage this to run the pipeline to create a service, environment, infrastructure definition, secret, etc.

The other alternative is to create pipeline templates that teams can use in their project. This lets a central team manage the pipelines for onboarding and distribute them to the app teams to leverage and onboard.

## Sample Pipeline to Setup

Below is the flow to get the automation setup in Harness:

1. Create a Pipeline
2. Create a Trigger for a Git based source
3. Create a terraform resource file of a Harness object
4. Commit the object
5. See the Pipeline execute
6. Look in the Harness account where resource was configured to be created.

### For Building a Pipeline

For help building Pipelines, Harness offers a starter guide in our developer hub to build a pipeline in our Product User Interface.

- [Pipeline Building Starter Guide](https://developer.harness.io/docs/continuous-delivery/onboard-cd/cd-quickstarts/kubernetes-cd-quickstart/)

### For Stage Configuration

- [Custom Stage](https://developer.harness.io/docs/platform/pipelines/add-a-custom-stage/)
- [Terraform Plan Step](https://developer.harness.io/docs/continuous-delivery/cd-advanced/terraform-category/run-a-terraform-plan-with-the-terraform-plan-step/)
- [Terraform Apply Step](https://developer.harness.io/docs/continuous-delivery/cd-advanced/terraform-category/run-a-terraform-plan-with-the-terraform-apply-step)

The Terraform Plan step will fetch the terraform resource from git and Harness will initiate a terraform plan on the files collected.

The Terraform Plan Step can be configured like so:

![Terraform Plan](https://github.com/thisrohangupta/changelog/blob/master/terraform-provider/assets/terraformplan.png)

Harness will pass the Terraform plan to that was generated based off the Harness Terraform Resource file and will pass it into the Apply Step. The Terraform Apply Step can Inherit the plan and create or update the service resource by selecting "Inherit from Plan". You need to make sure the Terraform Plan step is configured before the Apply.

![Terraform Apply](https://github.com/thisrohangupta/changelog/blob/master/terraform-provider/assets/terraformapply.png)


### Sample Trigger Setup

Below is a sample trigger to fire off the pipeline. We recommend using the [Github Webhook](https://developer.harness.io/docs/platform/pipelines/w_pipeline-steps-reference/triggers-reference/) trigger because you can make changes in Github and based of a branch condition, push, pull request, issue comment, etc. you can fire off the pipeline to make changes. The trigger doesn't need to be Github.

We support:

- Github
- Gitlab
- Bitbucket

For more information on triggers please see our [docs](https://developer.harness.io/docs/platform/triggers/trigger-pipelines-using-custom-payload-conditions/)

```YAML
trigger:
  name: Create and Update Service
  identifier: Create_and_Update_Service
  enabled: true
  encryptedWebhookSecretIdentifier: ""
  description: ""
  tags: {}
  orgIdentifier: default
  projectIdentifier: cdproduct
  pipelineIdentifier: Deploy_Sample_Pipeline
  source:
    type: Webhook
    pollInterval: "0"
    webhookId: ""
    spec:
      type: Github
      spec:
        type: Push
        spec:
          connectorRef: ProductManagementRohan ## Replace this with your Connector
          autoAbortPreviousExecutions: false
          payloadConditions:
            - key: targetBranch
              operator: Equals
              value: main
          headerConditions: []
          repoName: harness
          actions: []
  inputYaml: |
    pipeline: {}

```


## Onboarding a Service

For onboarding a Service onto Harness you will need to use the [Harness Terraform Resource](https://registry.terraform.io/providers/harness/harness/latest/docs/resources/platform_service). In Harness, you can create a [service](https://developer.harness.io/docs/continuous-delivery/onboard-cd/cd-concepts/services-and-environments-overview/) at the project, organization or account level.

Your will need to create this YAML and store it in your Github Repository.

```YAML
resource "harness_platform_service" "service" {
  identifier  = "nginx" ## Service Identifier
  name        = "nginx" ## Service Name to appear in Harness
  description = "sample nginx app created via Harness terraform Provider"  
  org_id      = "default" ## Replace with Harness Org Identifier for the resource, optional if creating at account level
  project_id  = "cdproduct" ## Replace with your Harness Project Identifier, optional if creating at org or account level. This project is where the service will be created
  yaml = <<-EOT
                service:
                  name: nginx ## Service Name (same as above)
                  identifier: nginx ## Service Identifier, needs to be same as above
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
                                  connectorRef: <+input> ## This is a connector in your account, project or Org to fetch source code
                                  gitFetchType: Branch
                                  paths:
                                    - /deploy/
                                  repoName: <+input> ## For an account level git connector, you can provide the Repo Name
                                  branch: master
                              skipResourceVersioning: false
                      configFiles: ## This block is optional, this is for config files like a python script or json file you want to attach to the service
                        - configFile:
                            identifier: configFile1
                            spec:
                              store:
                                type: Harness
                                spec:
                                  files:
                                    - <+org.description>
                      variables: ## These are service variables you can define
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
```

When you define your Service via Terraform, it's a one way sync. You are defining the Service in Git via Terraform, and on a commit of a change we will trigger a Harness Pipeline to provision the changes for your account. The pipeline will end up creating a service for you. Any changes you do via Git will propagate to the UI via this Pipeline which will fetch the service Terraform file definition.

Any changes done in the UI will need to be reconciled and updated in the YAML in order to protect against configuration mismatch. We recommend when using the terraform provider to manage services, you should use Git only to make your changes. We can have [RBAC](https://developer.harness.io/docs/platform/role-based-access-control/rbac-in-harness/) in place to prevent the editting and creation of services in the Harness UI.

When you run an automation pipeline to create service, you will see the service created in the UI like so:

![Service](https://github.com/thisrohangupta/changelog/blob/master/terraform-provider/assets/service.png)

### Sample Pipeline Setup for Service Creation

Below is a sample pipeline to create the nginx service and manage it via Git automation. You will also need to configure a Github Webhook Trigger to initiate updates to the service and automate the pipeline execution to update and create services.

```YAML
pipeline:
  name: Onboarding Service
  identifier: Deploy_Sample_Pipeline
  projectIdentifier: Rohan
  orgIdentifier: default
  tags: {}
  stages:
    - stage:
        name: Create and Update Service
        identifier: Create_and_Update_Service
        description: Create and update a service from Github
        type: Custom
        spec:
          execution:
            steps:
              - step:
                  type: TerraformPlan
                  name: Service Create and Update Plan
                  identifier: Service_Create_and_Update_Plan
                  spec:
                    configuration:
                      command: Apply
                      configFiles:
                        store:
                          type: Github
                          spec:
                            gitFetchType: Branch
                            connectorRef: ProductManagementRohan
                            branch: main
                            folderPath: service/nginx.tf
                            repoName: harness
                        moduleSource:
                          useConnectorCredentials: true
                      secretManagerRef: harnessSecretManager
                    provisionerIdentifier: service
                  timeout: 10m
              - step:
                  type: TerraformApply
                  name: Create and Update Service
                  identifier: Create_and_Update_Service
                  spec:
                    configuration:
                      type: InheritFromPlan
                    provisionerIdentifier: service
                  timeout: 10m
        tags: {}
  description: This Pipeline is dedicated to onboarding services in Harness

```
The overall pipeline will look something like below:

![Pipeline](https://github.com/thisrohangupta/changelog/blob/master/terraform-provider/assets/Pipeline.png)

## Onboarding an Environment

For onboarding an Environment, we recommend using the environment resource in our [Harness Terraform Provider](https://registry.terraform.io/providers/harness/harness/latest/docs/resources/platform_environment). In Harness, you can create an [Environment](https://developer.harness.io/docs/continuous-delivery/onboard-cd/cd-concepts/services-and-environments-overview/) at the Project, Organization and Account Level.

Your will need to create this YAML and store it in your Github Repository.

```YAML
resource "harness_platform_environment" "environment" {
  identifier = "dev" ## Define Environment Identifier, this is unique to the project, org or account - where the environment will be created
  name       = "dev" ## This will be the name of the environment that you will see in Harness UI
  org_id     = "default" ## Optional if your creating at Account level
  project_id = "cdproduct" ## optional if your creating at Org or Acount
  tags       = ["status:nonregulated", "owner:devops"]
  type       = "PreProduction"
  yaml = <<-EOT
    environment:
         name: dev ## Name of the environment, similar to above
         identifier: dev ## Name of the environment
         orgIdentifier: default  
         projectIdentifier: cdproduct ## optional if your creating at Org or Acount, this is where the environment will be created
         type: PreProduction
         tags:
           status: nonregulated
           owner: devops
         variables: ## You can configure global environment variable overides here
           - name: port
             type: String
             value: 8080
             description: "Default Port for Dev Environment"
           - name: db_url
             type: String
             value: "https://postrges:8080"
             description: "postgress url"
         overrides: ## You can configure global environment overrides here
           manifests:
             - manifest:
                 identifier: valuesDev
                 type: Values
                 spec:
                   store:
                     type: Git
                     spec:
                       connectorRef: <+input>
                       gitFetchType: Branch
                       paths:
                         - /dev/dev-values.yaml
                       repoName: <+input>
                       branch: master
           configFiles: ## You can configure configuration file overrides here.
             - configFile:
                 identifier: configFileEnv
                 spec:
                   store:
                     type: Harness
                     spec:
                       files:
                         - account:/Add-ons/svcOverrideTest
                       secretFiles: []
      EOT
}
```

When you run an automation pipeline to create environments, you will see the environment created in the UI like so:

![Environment](https://github.com/thisrohangupta/changelog/blob/master/terraform-provider/assets/environment.png)

### Sample Pipeline to Onboard Environments

```YAML
pipeline:
  name: Onboarding Environments
  identifier: Create_Environment_Pipeline
  projectIdentifier: cdproduct
  orgIdentifier: default
  tags: {}
  stages:
    - stage:
        name: Create and Update Environment
        identifier: Create_and_Update_Environment
        description: Create and update a environment from Github
        type: Custom
        spec:
          execution:
            steps:
              - step:
                  type: TerraformPlan
                  name: Environment Create and Update Plan
                  identifier: Environment_Create_and_Update_Plan
                  spec:
                    configuration:
                      command: Apply
                      configFiles:
                        store:
                          type: Github
                          spec:
                            gitFetchType: Branch
                            connectorRef: <+input>
                            branch: main
                            folderPath: environments/dev.tf
                        moduleSource:
                          useConnectorCredentials: true
                      secretManagerRef: harnessSecretManager
                    provisionerIdentifier: environment
                  timeout: 10m
              - step:
                  type: TerraformApply
                  name: Create and Update Environment
                  identifier: Create_and_Update_Environment
                  spec:
                    configuration:
                      type: InheritFromPlan
                    provisionerIdentifier: environment
                  timeout: 10m
        tags: {}
  description: This Pipeline is dedicated to onboarding environments in Harness
```

## Onbarding an Infrastructure Definition

For onboarding an Environment, we recommend using the infrastructure definition in our [Harness Terraform Provider](https://registry.terraform.io/providers/harness/harness/latest/docs/resources/platform_environment). In Harness, you can create an [Infrastructure Definition](https://developer.harness.io/docs/continuous-delivery/onboard-cd/cd-concepts/services-and-environments-overview/) at the Project, Organization and Account Level.

```YAML
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
          connectorRef: devkubernetes ### Replace with your connector
          namespace: dev
          releaseName: release-<+INFRA_KEY>
          allowSimultaneousDeployments: false
      EOT
}
```

Infrastructure Definitions are associated with the environment, so you will need to create an environment before creating the infrastructure definition.

When you run your automation pipeline and apply the terraform for the infrastructure definition you will see it appear in the UI like so:

![Infrastructure Definition](https://github.com/thisrohangupta/changelog/blob/master/terraform-provider/assets/infrastructure.png)

### Sample Pipeline to Onboard Infrastructure Definitions

```YAML
pipeline:
  name: Onboarding Infrastructure Definition
  identifier: Create_Infrastructure_Pipeline
  projectIdentifier: cdproduct
  orgIdentifier: default
  tags: {}
  stages:
    - stage:
        name: Create and Update Infrastructure
        identifier: Create_and_Update_Infrastructure
        description: Create and update a Infrastructure from Github
        type: Custom
        spec:
          execution:
            steps:
              - step:
                  type: TerraformPlan
                  name: Infrastructure Create and Update Plan
                  identifier: Infrastructure_Create_and_Update_Plan
                  spec:
                    configuration:
                      command: Apply
                      configFiles:
                        store:
                          type: Github
                          spec:
                            gitFetchType: Branch
                            connectorRef: <+input>
                            branch: main
                            folderPath: infrastructure/devk8s.tf
                        moduleSource:
                          useConnectorCredentials: true
                      secretManagerRef: harnessSecretManager
                    provisionerIdentifier: infra
                  timeout: 10m
              - step:
                  type: TerraformApply
                  name: Create and Update Infrastructure
                  identifier: Create_and_Update_Infrastructure
                  spec:
                    configuration:
                      type: InheritFromPlan
                    provisionerIdentifier: infra
                  timeout: 10m
        tags: {}
  description: This Pipeline is dedicated to onboarding environments in Harness
```

## Best Practices

We recommend starting out in the Harness User Interface to get familiar with all the constructions. Once you understand the relationships and the heirarchy you can then begin to automate the creation and management of these resources.

Please review these topics to get familiar with the Harness constructs:

- [Harness Key Concepts](https://developer.harness.io/docs/getting-started/learn-harness-key-concepts)
- [Projects, Orgs, Account](https://developer.harness.io/docs/platform/organizations-and-projects/projects-and-organizations/)
- [Service, Environments](https://developer.harness.io/docs/continuous-delivery/onboard-cd/cd-concepts/services-and-environments-overview/)

### Create a project for resource automation

We recommend two approaches:

1. Creating a centralized project that you can give your end user developers access to onboard their own services and resources

2. Create 1 Project that has a centralized platform team manage and onboard the app team services, environments and  other configurations.

You should get started by creating a centralized project like below:

![Project](https://github.com/thisrohangupta/changelog/blob/28b85395f7f70b01749e3de3da9078c7930b265d/terraform-provider/assets/project.png)

You can also create this via the Terraform Provider and manage it via the Terraform Provider in code

```YAML
resource "harness_platform_project" "project" {
  identifier = "cdproduct"
  name       = "cdproduct"
  org_id     = "default"
  color      = "#0063F7"
}
```

### Get the Delegate operationalized

- We recommend for production grade delegate installation, to build your own delegate image and deploy it
- When you build your own delegate image, you get to customize all the tooling you want installed on it.
- [Harness offers Instructions to build your own delegate image](https://developer.harness.io/docs/platform/Delegates/customize-delegates/build-custom-delegate-images-with-third-party-tools)

Tooling you should install:

- `kubectl`
- `helm`
- `terraform`

These options are all available in the [Harness Docs](https://developer.harness.io/docs/platform/Delegates/customize-delegates/build-custom-delegate-images-with-third-party-tools)


### Create the Connectors and Secrets first

 Make sure the [connectors](https://developer.harness.io/docs/first-gen/firstgen-platform/account/manage-connectors/harness-connectors/) are created in Harness. You can create them and manage them via the [Terraform Provider](https://registry.terraform.io/providers/harness/harness/latest/docs/resources/platform_connector_github) or in the UI.

![Connector](https://github.com/thisrohangupta/changelog/blob/master/terraform-provider/assets/connector.png)

Below is a sample snippet for creating a connector via the Terraform Provider:

```YAML
resource "harness_platform_connector_helm" "helm" {
  identifier  = "bitnami"
  name        = "bitnami"
  description = "bitnami helm connector"
  tags        = ["owner:dev"]

  url                = "hhttps://charts.bitnami.com/bitnami"
  delegate_selectors = ["harness-delegate"]
}
```

 These connectors will require [secrets](https://developer.harness.io/docs/platform/Security/harness-secret-manager-overview) to be configured because connectors are access objects that provide the Harness delegate access to a particular resource. You can create the connectors via the [Terraform Provider](https://registry.terraform.io/providers/harness/harness/latest/docs/resources/platform_secret_text) or in the Harness UI.

![Secret](https://github.com/thisrohangupta/changelog/blob/master/terraform-provider/assets/secret.png)

Below is a sample snippet for creating a secret text via the Terraform Provider:

```YAML
resource "harness_platform_secret_text" "secret" {
  identifier  = "github_pat"
  name        = "github pat"
  description = "github personal access token"
  tags        = ["owner:dev"]

  secret_manager_identifier = "harnessSecretManager"
  value_type                = "Inline"
  value                     = "secret"
}
```


