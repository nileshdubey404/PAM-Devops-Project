# helm-k8s-deployment

A production-grade CI/CD pipeline designed to automate the build, containerization, and orchestration of a modern frontend application. This project demonstrates end-to-end continuous integration and continuous delivery (CI/CD) using Jenkins, AWS Elastic Container Registry (ECR), Kubernetes, and Helm.


## Architecture & Workflow

[1]Continuous Integration (Jenkins): Triggers automated builds upon code pushes, runs tests, and packages the frontend application.

[2]Container Registry (AWS ECR): Securely stores versioned Docker images generated during the pipeline run.

[3]Continuous Delivery & Orchestration (Kubernetes & Helm): Uses Helm charts to manage environment configurations, deployments, and seamless rolling updates on a Kubernetes cluster.
