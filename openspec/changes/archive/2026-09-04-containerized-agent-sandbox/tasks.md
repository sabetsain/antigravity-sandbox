## 1. Standalone Template Setup

- [x] 1.1 Scaffold directory structure at `~/Projects/agy-sandbox` (`bin/`, `skills/sandbox-init/`, `.gitignore`).
- [x] 1.2 Author universal `Dockerfile` with Node 22, Python 3.12, Rootless Podman, `fuse-overlayfs`, non-root user `developer` (UID 1000), and global `agy` CLI installation.
- [x] 1.3 Add `.gitignore` to `~/Projects/agy-sandbox` ignoring `.worktrees/`, local caches, and credentials.
- [x] 1.4 Add `.worktrees/` to root `.gitignore` in `chores` repository.

## 2. Orchestrator CLI Implementation

- [x] 2.1 Implement `bin/agy-sbx` CLI skeleton supporting commands `new`, `open`, `list`, `rm`, and `current`.
- [x] 2.2 Implement Git worktree creation and branch tracking logic (`git worktree add .worktrees/<task> -b agent/<task>`).
- [x] 2.3 Implement credential and auth mounting (`~/.gemini`, `~/.gitconfig`, `SSH_AUTH_SOCK`) with ephemeral container execution.
- [x] 2.4 Implement hybrid image resolution (fallback to `agy-sandbox:latest` or build project-local Dockerfile).
- [x] 2.5 Implement worktree inspection (`list`) and cleanup (`rm`) logic.
- [x] 2.6 Ensure `bin/agy-sbx` is executable and verify command routing and help text.

## 3. Autonomous Skill & Project Documentation

- [x] 3.1 Create `skills/sandbox-init/SKILL.md` defining autonomous tech stack inspection and devcontainer configuration generation.
- [x] 3.2 Create comprehensive `README.md` covering Podman Desktop setup, global symlink installation, worktree lifecycle guide, and Herdr integration recipes.
- [x] 3.3 Create convenience installation script `install.sh` for symlinking `bin/agy-sbx` to `~/.local/bin/agy-sbx`.

## 4. Verification and Testing

- [x] 4.1 Build universal image `agy-sandbox:latest` using Podman.
- [x] 4.2 Verify container runtime environment (Node, Python, agy, rootless nested Podman).
- [x] 4.3 Verify `agy-sbx` worktree isolation, Google OAuth persistence, and concurrent multi-agent execution.

