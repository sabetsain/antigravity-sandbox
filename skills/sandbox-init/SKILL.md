---
name: sandbox-init
description: Autonomously inspects repository tech stacks and generates optimized .devcontainer and sandbox configurations.
---

# Autonomous Sandbox Initializer (`sandbox-init`)

This skill enables an autonomous agent to inspect a repository's codebase, detect its complete technology stack, and scaffold customized, production-grade container sandbox configurations (`.devcontainer/Dockerfile`, `.devcontainer/devcontainer.json`, and `.gitignore`).

---

## 1. Inspection Workflow

When invoked on a repository, execute the following steps in order:

### Step 1.1: Tech Stack Discovery
Scan the repository root and subdirectories for key configuration and manifest files:

| Technology / Ecosystem | Manifest / Indicator Files |
| :--- | :--- |
| **Node.js / TypeScript** | `package.json`, `tsconfig.json`, `pnpm-lock.yaml`, `yarn.lock`, `bun.lockb` |
| **Python** | `pyproject.toml`, `requirements.txt`, `Pipfile`, `poetry.lock`, `setup.py` |
| **Rust** | `Cargo.toml`, `Cargo.lock` |
| **Go** | `go.mod`, `go.sum` |
| **Databases / Services** | `docker-compose.yml`, `compose.yaml`, `schema.prisma`, `alembic.ini` |
| **Infrastructure / Tooling** | `Makefile`, `Taskfile.yml`, `Justfile` |

Extract required version constraints (e.g., Python 3.12, Node 20 or 22, PostgreSQL 16) directly from the manifests.

### Step 1.2: Port & Service Mapping
Inspect web framework configuration or `docker-compose.yml` to identify local development ports:
- Frontend dev servers (e.g., Vite on `5173`, Next.js on `3000`, Nuxt on `3000`)
- Backend API servers (e.g., FastAPI on `8000`, Express/Nest on `3001`/`8080`, Django on `8000`)
- Database services (e.g., PostgreSQL on `5432`, Redis on `6379`)

---

## 2. Configuration Generation

### Step 2.1: Generate `.devcontainer/Dockerfile`
Create `.devcontainer/Dockerfile` tailored to the detected stack. The container image **MUST** meet the following architectural guarantees:
1. **Base OS**: `ubuntu:24.04` or Debian 12.
2. **Non-Root User**: User `developer` (UID 1000, GID 1000) with passwordless `sudo` rights.
3. **Rootless Podman Support**:
   - Install `fuse-overlayfs`, `podman`, `uidmap`.
   - Setup `/etc/subuid` and `/etc/subgid` with `developer:100000:65536`.
   - Configure `/etc/containers/storage.conf` using `mount_program = "/usr/bin/fuse-overlayfs"`.
   - Configure `/etc/containers/containers.conf` with `cgroup_manager = "cgroupfs"`.
   - Symlink `/usr/local/bin/docker -> /usr/bin/podman`.
4. **Antigravity CLI**:
   - Install `agy` globally to `/usr/local/bin/agy` via `curl -fsSL https://antigravity.google/cli/install.sh | bash -s -- --dir /usr/local/bin`.
5. **Ecosystem Toolchains**:
   - Install detected languages, package managers, and database client binaries (e.g. `postgresql-client`).

### Step 2.2: Generate `.devcontainer/devcontainer.json`
Generate `.devcontainer/devcontainer.json` specifying:
```json
{
  "name": "Project Sandbox",
  "build": {
    "dockerfile": "Dockerfile",
    "context": ".."
  },
  "runArgs": [
    "--device", "/dev/fuse",
    "--privileged",
    "--userns=keep-id"
  ],
  "containerUser": "developer",
  "remoteUser": "developer",
  "workspaceFolder": "/workspace",
  "forwardPorts": [3000, 8000],
  "customizations": {
    "vscode": {
      "settings": {
        "terminal.integrated.defaultProfile.linux": "bash"
      }
    }
  }
}
```

### Step 2.3: Ensure Git Worktree Scaffolding
Verify `.gitignore` in the repository root. If `.worktrees/` is not present:
- Append `.worktrees/` to `.gitignore` under a `# Git Worktrees / Agent Sandboxes` section.
- This ensures parallel agent sessions do not commit temporary worktree folders to git status.

---

## 3. Verification & Hand-off

After generating the files:
1. Test syntax and formatting of generated JSON and Dockerfile.
2. Provide a clear summary to the user detailing the detected tech stack and the files created.
3. Inform the user they can now run `agy-sbx new <task-name>` to launch an isolated agent container built specifically for this repository.

