## ADDED Requirements

### Requirement: Tech Stack Inspection and Analysis
The `sandbox-init` skill SHALL explore the repository to detect programming languages, dependency managers, framework types, and database services from repository files.

#### Scenario: Detecting fullstack Node and Python repository
- **WHEN** the skill is invoked in a repository containing `pyproject.toml`, `package.json`, and `docker-compose.yml`
- **THEN** it SHALL identify Python, Node.js, and PostgreSQL service requirements.

### Requirement: Automated DevContainer Configuration Generation
The `sandbox-init` skill SHALL autonomously generate or update `.devcontainer/Dockerfile` and `.devcontainer/devcontainer.json` tailored to the inspected project stack.

#### Scenario: Generating tailored devcontainer files
- **WHEN** the skill completes its tech stack inspection
- **THEN** it SHALL write a `.devcontainer/Dockerfile` with appropriate runtime versions and tools, and a `.devcontainer/devcontainer.json` with matching port forwardings.

### Requirement: Worktree Gitignore Scaffolding
The `sandbox-init` skill SHALL ensure `.worktrees/` is present in the repository's `.gitignore`.

#### Scenario: Updating gitignore for worktrees
- **WHEN** `.worktrees/` is missing from `.gitignore`
- **THEN** the skill SHALL append `.worktrees/` to prevent worktree directory pollution.

