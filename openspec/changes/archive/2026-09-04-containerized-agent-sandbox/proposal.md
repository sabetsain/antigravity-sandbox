## Why

Running AI coding agents with full command execution permissions on a host machine poses security risks of accidental file system disruption, credential exposure, or command runaway. Conversely, standard container environments introduce high startup latency, lack support for nested container workloads, and cause race conditions when multiple agents run concurrently in terminal multiplexers like Herdr. This change creates an isolated, exportable container sandbox architecture and orchestrator CLI (`agy-sbx`) enabling zero-startup-latency, multi-agent worktree-isolated, credential-preserved, and nested-Podman-capable execution.

## What Changes

- **Universal Sandbox Runtime**: A container definition featuring Node 22, Python 3.12, Git, OpenSSH, PostgreSQL client, Rootless Podman, and `agy` running as a non-root `developer` user (UID 1000).
- **Host Orchestrator CLI (`agy-sbx`)**: A standalone CLI that manages Git worktrees (`.worktrees/<task>`), mounts host Google OAuth tokens and Git credentials, and spawns ephemeral container instances in ~300ms.
- **Herdr Multiplexing Compatibility**: Worktree-level isolation allowing multiple parallel agents to run simultaneously without filesystem collision or git index locking.
- **Standalone Template Exportability**: Standalone project layout (`~/Projects/agy-sandbox`) isolated from the chores repository, ready to be version-controlled and pushed to GitHub as a private or public starter template.
- **Autonomous Scaffolding Skill (`sandbox-init`)**: A repo-local skill template for exploring project codebases and scaffolding customized container configurations automatically.
- **Documentation**: Comprehensive guide covering Podman Desktop on macOS, worktree lifecycle (re-opening, inspecting, and pruning), and Herdr pane recipes.

## Capabilities

### New Capabilities
- `agent-sandbox-environment`: Container image specification with fullstack toolchain (Node, Python), rootless nested Podman support, global `agy` installation, and non-root user permissions.
- `worktree-orchestrator-cli`: Host CLI (`agy-sbx`) providing lifecycle commands (`new`, `open`, `list`, `rm`, `current`), credential mounting, and ephemeral container execution.
- `autonomous-sandbox-skill`: Antigravity skill specification (`sandbox-init`) enabling agents to autonomously inspect tech stacks and scaffold project `.devcontainer` configurations.

### Modified Capabilities
None. (This tooling does not modify existing chore-tracking business domain specifications.)

## Impact

- **Codebase Impact**: Adds `.worktrees/` to root `.gitignore` in `chores` to prevent untracked worktrees from polluting git status.
- **External Dependencies**: Requires Podman Desktop (or Podman machine) installed on the macOS host.
- **System Footprint**: Project files for the sandbox are isolated to `~/Projects/agy-sandbox` and symlinked via `~/.local/bin/agy-sbx`.

