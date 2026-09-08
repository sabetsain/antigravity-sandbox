## ADDED Requirements

### Requirement: Fullstack Multi-Language Runtime Environment
The sandbox container image SHALL provide Node.js 22, npm, Python 3.12, pip, venv, Git, OpenSSH client, and PostgreSQL client binaries pre-installed and available in the system PATH.

#### Scenario: Running Node and Python toolchains
- **WHEN** a command inside the container executes `node --version`, `npm --version`, `python3 --version`, or `git --version`
- **THEN** each tool SHALL return successfully with exit code 0.

### Requirement: Global Antigravity CLI Installation
The sandbox container image SHALL install the `agy` CLI binary globally into `/usr/local/bin/agy` with execute permissions for non-root users.

#### Scenario: Executing agy as non-root developer user
- **WHEN** the non-root `developer` user executes `agy --version` or `agy --help`
- **THEN** the command SHALL execute successfully without requiring root or sudo elevation.

### Requirement: Rootless Nested Podman Execution
The container image SHALL configure rootless Podman with `fuse-overlayfs` and provide a symlink or alias for `docker` pointing to `podman`.

#### Scenario: Building and running nested containers
- **WHEN** an agent executes `podman run --rm alpine echo hello` or `docker run --rm alpine echo hello` inside the sandbox
- **THEN** the command SHALL execute the nested container entirely within the sandbox without connecting to the host Docker daemon.

### Requirement: Non-Root User Identity and Permissions
The sandbox container SHALL run with a default non-root user `developer` (UID 1000, GID 1000) configured with passwordless sudo rights and subuid/subgid mapping.

#### Scenario: File creation matches host user ownership
- **WHEN** an agent creates or modifies files in the mounted `/workspace` directory
- **THEN** the files SHALL be owned by UID 1000, matching standard macOS host user permissions.

