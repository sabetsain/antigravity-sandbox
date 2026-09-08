## Context

Autonomous AI coding agents (such as Google Antigravity's `agy` CLI) require full terminal execution capabilities (file editing, testing, compiling, installing dependencies, and running containers) to be effective. Granting unrestricted execution permissions directly on a developer's host machine introduces security risks. Conversely, existing DevContainer workflows are tightly coupled to IDEs, have multi-second startup latency, and do not gracefully handle parallel agents running simultaneously in terminal multiplexers like Herdr.

This design outlines a decoupled, privacy-safe, and universal sandboxing architecture centered around an ephemeral Podman container runtime, Git worktree isolation, and a host orchestrator CLI (`agy-sbx`). The entire system is packaged as an exportable standalone template in `~/Projects/agy-sandbox`.

## Goals / Non-Goals

**Goals:**
- **Zero-Friction Execution**: Ephemeral container startup in ~300ms on macOS using local prebuilt images.
- **Security Sandboxing without Permission Prompts**: Enable full auto-approval (`--dangerously-skip-permissions`) inside the container without risking host file destruction or escape.
- **Safe Nested Containers**: Provide rootless Podman inside the sandbox, aliased to `docker`, without mounting the host's `/var/run/docker.sock`.
- **Multi-Agent Multiplexing**: Isolate parallel agent sessions in separate Git worktrees (`.worktrees/<task>`) to eliminate merge conflicts, git index locking, and file overwrites.
- **Seamless Host Credentials**: Forward host Google OAuth session (`~/.gemini`), Git author config (`~/.gitconfig`), and SSH keys (`SSH_AUTH_SOCK`) without baking credentials into container images.
- **Standalone Template Export**: Maintain the sandbox project in an isolated repository (`~/Projects/agy-sandbox`) ready for publishing to GitHub.

**Non-Goals:**
- Modifying or replacing terminal multiplexers like Herdr or tmux.
- Building a graphical desktop container management tool.
- Replacing project-level CI/CD pipelines.

## Decisions

### 1. Ephemeral Container Lifecycle (`podman run --rm`)
* **Decision**: Each agent session spawns an ephemeral container that automatically destroys itself upon agent exit.
* **Rationale**: Consumes 0% battery and CPU when idle. Ensures clean environment states, isolates child container storage graphs, and cleanly maps 1:1 with Git worktrees.
* **Alternatives considered**: Single background daemon container with `exec`. Rejected due to shared PID namespaces, shared nested container storage, and filesystem pollution across multiple agents.

### 2. Nested Rootless Podman instead of Host Docker Socket
* **Decision**: Install Podman with `fuse-overlayfs` inside the sandbox container and alias `docker=podman`.
* **Rationale**: Mounting `/var/run/docker.sock` exposes the host root filesystem to the agent. Rootless Podman confines all nested containers, builds, and networks inside the sandbox.
* **Alternatives considered**: Docker-in-Docker (DinD). Podman was selected because it runs daemonless and integrates natively with rootless user namespaces.

### 3. Git Worktree Isolation
* **Decision**: Parallel agents run in dedicated worktrees at `.worktrees/<task>` linked to `agent/<task>` branches.
* **Rationale**: Multiple agents running concurrently in Herdr tabs cannot safely share the same working directory. Worktrees allow concurrent edits, independent git staging, and persistent branch state even after containers terminate.
* **Alternatives considered**: Git branches in a single directory (causes conflicts during parallel runs) or full repository clones (wastes disk space and duplicates git history).

### 4. Non-Root User Execution (`developer`, UID 1000)
* **Decision**: The agent runs as user `developer` (UID 1000) with passwordless `sudo` and subuid/subgid mapping.
* **Rationale**: Files created by the agent in mounted worktrees match host user permissions on macOS. Non-root user identity also enables standard rootless Podman namespaces.

### 5. Hybrid Image Resolution Strategy
* **Decision**: `agy-sbx` checks if the active repository contains a `.devcontainer/Dockerfile` or `.sandbox/Dockerfile`. If found, it builds/runs that image; otherwise, it defaults to the prebuilt universal `agy-sandbox:latest` (Node 22 + Python 3.12 + Podman + agy).
* **Rationale**: Combines zero-config instant startup for 95% of projects with flexibility for specialized project requirements.

### 6. Standalone Project Layout (`~/Projects/agy-sandbox`)
* **Decision**: All sandbox source files, Dockerfiles, orchestrator scripts, and skills reside in `~/Projects/agy-sandbox`.
* **Rationale**: Ensures the project is completely privacy-safe, decoupled from `chores`, and immediately ready to be initialized as an independent Git repository and pushed to GitHub.

## Risks / Trade-offs

- **[Risk] Nested Podman requires outer container privileges** → **Mitigation**: The outer container runs inside the macOS Podman VM with no host filesystem mounts outside the target worktree and auth directories.
- **[Risk] Accumulation of stale Git worktrees** → **Mitigation**: `agy-sbx` includes `list` and `rm` commands to inspect and prune worktrees and associated branches.
- **[Risk] Unintended credential exposure via volume mounts** → **Mitigation**: `~/.gitconfig` is mounted read-only (`:ro`). SSH keys are forwarded via unix domain socket (`SSH_AUTH_SOCK`), never copied as raw private key files.

## Migration Plan

1. Scaffold standalone directory `~/Projects/agy-sandbox`.
2. Author Dockerfile, `bin/agy-sbx`, `skills/sandbox-init/SKILL.md`, and `README.md`.
3. Add `.worktrees/` to `.gitignore` in `chores` and any target repository.
4. Symlink `bin/agy-sbx` to `~/.local/bin/agy-sbx`.
5. Build the universal image `agy-sandbox:latest` via Podman.

