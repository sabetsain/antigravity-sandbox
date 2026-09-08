# Containerized Agent Sandbox (`agy-sandbox`)

> **Zero-friction, ephemeral, privacy-safe container execution environment for Google Antigravity (`agy`) agents with Git worktree isolation and nested rootless Podman.**

---

## Overview

When running autonomous AI coding agents with unrestricted command permissions, developers face two undesirable extremes:
1. **Running directly on the host**: Fast and convenient, but risks accidental file modification, credential leakage, command runaway, and git branch collision when running parallel tasks.
2. **Traditional DevContainers**: Safe, but heavy, slow to launch (often 10–30 seconds), tightly coupled to IDEs, and unable to safely run nested containers without exposing the host's `/var/run/docker.sock`.

**`agy-sandbox`** solves this by pairing **rootless Podman on macOS** with **ephemeral containers** and **Git worktree orchestration**:
- ⚡ **~300ms Container Startup**: Spawns an isolated Ubuntu container instantly.
- 🔋 **0% Idle Overhead**: Ephemeral execution destroys containers on exit (`--rm`), freeing all CPU and RAM.
- 🛡️ **Safe Nested Containers**: Ships with internal rootless Podman aliased to `docker` using `fuse-overlayfs`—no host Docker daemon exposure.
- 🔀 **Multi-Agent Terminal Multiplexing**: Run dozens of parallel agent tasks in separate Herdr or tmux tabs without git index conflicts or merge contention.
- 🔑 **Credential Passthrough**: Automatically mounts Google OAuth tokens (`~/.gemini`), Git author config (`~/.gitconfig`), and SSH keys (`SSH_AUTH_SOCK`) with read-only protections where appropriate.
- 📦 **Standalone & Privacy-Safe**: Completely decoupled from any single project, ready to publish to GitHub as a personal or team template repository.

---

## Quickstart

### 1. Prerequisites (macOS)
Install and start **Podman Desktop** (or the Podman CLI via Homebrew):

```bash
brew install podman
podman machine init --now
```

Verify Podman machine status:
```bash
podman machine list
```

### 2. Installation
Clone or navigate to the sandbox directory and run the installer:

```bash
cd ~/Projects/agy-sandbox
./install.sh
```

This script:
1. Builds the universal `agy-sandbox:latest` container image.
2. Symlinks `bin/agy-sbx` into `~/.local/bin/agy-sbx`.
3. Checks that `~/.local/bin` is in your shell `$PATH`.

Ensure `~/.local/bin` is in your `~/.zshrc` or `~/.bashrc`:
```bash
export PATH="$HOME/.local/bin:$PATH"
```

Verify the CLI is accessible:
```bash
agy-sbx --help
```

---

## Worktree Lifecycle Guide

`agy-sbx` uses Git worktrees to completely isolate agent workspaces. Each task gets its own folder under `.worktrees/<task-name>` and its own branch `agent/<task-name>`.

```
my-project/
├── .git/
├── .worktrees/
│   ├── fix-login/           <-- Agent 1 working here (agent/fix-login)
│   └── migrate-db/          <-- Agent 2 working here (agent/migrate-db)
├── src/                     <-- Your main branch / working tree stays clean!
```

### 1. Start a Sandbox Session
Navigate to any git repository on your machine and simply run:

```bash
cd ~/Projects/my-app
agy-sbx
```
* If you run `agy-sbx` with no arguments, it automatically creates a fresh worktree with a timestamped task name (e.g. `task-0904-1230`) and drops you straight into the sandbox.
* If you provide a task name directly (e.g. `agy-sbx fix-auth`), it automatically re-opens the task if it already exists, or creates it if it is new:

```bash
# Shorthand: opens if exists, creates if new
agy-sbx fix-auth-routing

# Explicit syntax:
agy-sbx new fix-auth-routing
```

To pass an initial prompt or flags directly to the agent:
```bash
agy-sbx fix-auth-routing -- -p "Fix redirect loop on unauthenticated login"
```

### 2. Pause and Re-open
Because the container is ephemeral, you can exit the agent session (`Ctrl+D` or `/exit`) at any time. All your files, commits, and branch state remain safely intact in `.worktrees/fix-auth-routing`.

To resume work later:
```bash
agy-sbx fix-auth-routing     # Shorthand: re-opens automatically!
# or explicitly:
agy-sbx open fix-auth-routing
```

### 3. Inspect Active Worktrees
To see all parallel agent sessions in the current repository, their git status, and recent commits:

```bash
agy-sbx list
```

Output:
```
Active Sandbox Worktrees in my-app:
================================================================================
  • fix-auth-routing [branch: agent/fix-auth-routing]
    Path:   /path/to/my-app/.worktrees/fix-auth-routing
    Status: clean
    Commit: a1b2c3d - Implement cookie validation (10m ago)

  • migrate-db [branch: agent/migrate-db]
    Path:   /path/to/my-app/.worktrees/migrate-db
    Status: dirty (uncommitted changes)
    Commit: e4f5g6h - Add initial schema migration (2h ago)

Total active sandbox worktrees: 2
```

### 4. Complete and Clean Up
Once the task branch is merged or no longer needed, remove the worktree:

```bash
# Keep the git branch:
agy-sbx rm fix-auth-routing

# Or delete the git branch simultaneously:
agy-sbx rm fix-auth-routing --delete-branch
```

### 5. Run Directly in Current Directory
If you want to run an agent in the current repository without creating a new worktree:

```bash
agy-sbx current
```

### 6. Interactive Debugging Shell
To drop into a bash shell inside the container sandbox to test commands manually:

```bash
agy-sbx shell
# Or inside a specific worktree:
agy-sbx shell fix-auth-routing
```

---

## Herdr Integration Recipe

[Herdr](https://github.com) is an AI-first terminal multiplexer designed for running multiple autonomous agents concurrently.

### Recommended Herdr Workflow
1. Create a workspace in Herdr for your project.
2. For each task, open a new Herdr tab and run:
   ```bash
   agy-sbx new <task-name>
   ```
3. Because each tab executes in a separate Git worktree and an isolated ephemeral Podman container:
   - File edits in Tab 1 **cannot overwrite** files in Tab 2.
   - Running test suites concurrently **cannot lock** Git index or collide on temporary files.
   - Nested `podman run` or `docker build` commands inside Tab 1 run within its own rootless overlay filesystem.

---

## Hybrid Image Resolution

`agy-sbx` automatically adapts to your project's specialized requirements:

1. **Project-Local Dockerfile**: If your repository contains `.devcontainer/Dockerfile` or `.sandbox/Dockerfile`, `agy-sbx` builds and runs a project-specific image (`<project>-sandbox:latest`).
2. **Universal Image Fallback**: If no custom Dockerfile is present, it instantly falls back to `agy-sandbox:latest` featuring:
   - **Node.js 22.x LTS** & `npm`
   - **Python 3.12** (`pip`, `venv`)
   - **Git**, **OpenSSH client**, **jq**, **PostgreSQL client**
   - **Rootless Podman** (aliased to `docker`) with `fuse-overlayfs`
   - **Google Antigravity CLI (`agy`)** globally installed in `/usr/local/bin/agy`

### Scaffolding a Custom Project Sandbox
To inspect a project and automatically generate `.devcontainer/Dockerfile` tailored to that project's tech stack, use the repo-local `sandbox-init` skill:
```bash
# Copy the skill into your project's .agent/skills/ or run via Antigravity:
cp -r ~/Projects/agy-sandbox/skills/sandbox-init .agent/skills/
```

---

## Exporting to GitHub

This repository is designed as a standalone, zero-dependency starter template. To publish it to GitHub as your personal or organizational template:

```bash
cd ~/Projects/agy-sandbox

# 1. Initialize Git repository
git init -b main

# 2. Stage and commit files
git add .
git commit -m "Initial commit: containerized agent sandbox template"

# 3. Create repository on GitHub (using GitHub CLI)
gh repo create agy-sandbox --public --source=. --remote=origin --push

# Or push to an existing remote:
# git remote add origin git@github.com:<your-username>/agy-sandbox.git
# git push -u origin main
```

---

## License

Apache 2.0. Free to use, adapt, and distribute across all your development workflows.

