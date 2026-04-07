# Tech Stack

## Platform
- GitHub Actions (CI/CD)
- All workflows are YAML-based and triggered via `workflow_call`

## Supported Runtimes / Build Targets
- **.NET** — default SDK `8.0.x`, uses `dotnet` CLI
- **Node.js** — configurable version, uses `npm` + `webpack`

## Key Tools & Integrations
- **GitVersion** (`5.12.0`) — semantic versioning from git history
- **SonarCloud** — static analysis (org: `laboratorio-net`)
- **Docker** — image build/push via `docker/build-push-action`
- **Helm** — Kubernetes deployments (default chart repo: `https://leandro-alves-labs.github.io/helm-charts`)
- **Azure Web Apps** — container deployments via `azure/webapps-deploy`
- **NuGet** — package publishing to `https://api.nuget.org/v3/index.json`

## Common Commands

### .NET
```bash
dotnet restore <solution>.sln
dotnet build <solution>.sln --configuration Release --no-restore
dotnet test <solution>.sln --configuration Release --no-restore --no-build
dotnet pack -p:VersionPrefix=<version> -o ./packages -c Release <solution>.sln
dotnet nuget push <file>.nupkg --source https://api.nuget.org/v3/index.json --api-key <key>
```

### Node.js
```bash
npm install
npx webpack --mode production
```

### Docker
```bash
docker build -t <registry>/<image>:<tag> .
docker push <registry>/<image>:<tag>
```

### Helm
```bash
helm repo add <repo-name> <repo-url>
helm upgrade --install <release> <repo>/<chart> -f deployment/values.yaml --set image.tag=<version>
```
