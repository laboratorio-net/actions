# Product

This repository is a **reusable GitHub Actions workflow library** — a collection of shared, callable CI/CD pipeline components designed to be referenced by other repositories via `workflow_call`.

## Purpose

Provides standardized, reusable workflows for:
- Building and testing .NET and Node.js applications
- Static code analysis via SonarCloud
- Docker image building and publishing
- Kubernetes deployment via Helm
- Azure Web App deployment
- Semantic versioning via GitVersion
- NuGet package publishing
- Git tag management

## Audience

Internal engineering teams consuming these workflows from their own repositories using GitHub Actions `uses:` references.
