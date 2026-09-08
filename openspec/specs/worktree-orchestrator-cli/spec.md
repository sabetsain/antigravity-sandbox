# Worktree Orchestrator CLI Specification

### Requirement: Task Worktree Creation and Branch Mapping
The `agy-sbx new <task>` command SHALL create a new Git worktree at `.worktrees/<task>` linked to a dedicated branch named `agent/<task>`.

#### Scenario: Creating a new isolated agent worktree
- **WHEN** the user or multiplexer runs `agy-sbx new fix-auth-routing`
- **THEN** a branch `agent/fix-auth-routing` SHALL be created from the current HEAD
- **AND** a worktree directory `.worktrees/fix-auth-routing` SHALL be created and mounted to `/workspace` in an ephemeral container.

### Requirement: Re-attaching to Existing Worktrees
The `agy-sbx open <task>` command SHALL locate an existing worktree at `.worktrees/<task>` and start a new container session attached to it.

#### Scenario: Resuming work on an existing task
- **WHEN** the user runs `agy-sbx open fix-auth-routing`
- **THEN** the CLI SHALL launch a container mounted to `.worktrees/fix-auth-routing` without re-creating the worktree or resetting branch state.

### Requirement: Worktree Listing and Cleanup
The CLI SHALL provide `list` to enumerate active worktrees and `rm <task>` to remove a worktree and optionally prune its branch.

#### Scenario: Listing active worktrees
- **WHEN** the user runs `agy-sbx list`
- **THEN** the CLI SHALL output all active worktrees under `.worktrees/` along with their associated branch names and status.

#### Scenario: Removing a completed worktree
- **WHEN** the user runs `agy-sbx rm fix-auth-routing`
- **THEN** the worktree directory SHALL be removed from disk and pruned from git worktree records.

### Requirement: Direct Current Directory Execution
The `agy-sbx current` command SHALL launch an ephemeral sandbox container mounted directly to the current working directory without creating a worktree.

#### Scenario: Running sandbox in current directory
- **WHEN** the user runs `agy-sbx current`
- **THEN** the CLI SHALL mount the current working directory as `/workspace` inside the container.

### Requirement: Credential Passthrough and Auto-Approval
The CLI SHALL mount `$HOME/.gemini` (read-write), `$HOME/.gitconfig` (read-only), and forward `$SSH_AUTH_SOCK` into the container, passing `--dangerously-skip-permissions` to `agy` by default while forwarding trailing arguments.

#### Scenario: Automatic authentication and auto-approved execution
- **WHEN** `agy-sbx` launches a container
- **THEN** the agent inside the container SHALL inherit Google OAuth session tokens, git commit author identity, and SSH push permissions without interactive prompts.

