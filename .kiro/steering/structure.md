# Project Structure

```
.github/
  workflows/
    pipeline.yaml              # Main CI entry point (triggers on push/PR to main)
    git-version.yaml           # Semantic versioning via GitVersion
    create-tag.yaml            # Creates and pushes a git tag
    build-dotnet.yaml          # Build, test, analyze, and pack .NET solutions
    build-nodejs.yaml          # Build Node.js apps with webpack
    docker-build-publish.yaml  # Build and push Docker images
    helm-deploy.yaml           # Deploy to Kubernetes via Helm
    azure-deploy.yaml          # Deploy container to Azure Web App
    nuget-deploy.yaml          # Publish NuGet packages
```

## Conventions

- Every workflow file uses `workflow_call` — they are reusable components, not standalone pipelines
- `pipeline.yaml` is the only orchestrating workflow; all others are called as jobs within it or from consuming repos
- Inputs are always explicitly typed and documented with `description` fields
- Secrets are declared at the workflow level and passed down — never hardcoded
- Deployment jobs guard against unintended runs using: `if: github.ref == 'refs/heads/main' || contains(github.ref, inputs.prefix-allowed-branch)`
- Versioning follows SemVer; branch builds append build metadata (e.g. `1.2.3.0004`)
- NuGet packages are filtered to only include files matching the solution name before publishing
- Helm values file defaults to `deployment/values.yaml` in the consuming repo
- Docker image tag format: `<registry>/<image>:<version>` or `<username>/<image>:<version>` when no registry is set

## Adding a New Workflow

1. Create a new `.yaml` file in `.github/workflows/`
2. Use `on: workflow_call` with typed `inputs` and `secrets`
3. Provide `description` for all required inputs
4. Include a `runs-on` input defaulting to `ubuntu-latest` for flexibility
5. Reference it from `pipeline.yaml` or document how consuming repos should call it
