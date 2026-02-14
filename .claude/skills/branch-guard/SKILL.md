---
description: Verify branch and worktree before making edits
user-invocable: false
---

# Branch Guard

Before editing files, verify:

1. **Current branch**: Run `git rev-parse --abbrev-ref HEAD` and confirm it matches the expected branch for the current task.

2. **Worktree isolation**: Run `git rev-parse --show-toplevel` and confirm edits target the correct worktree directory.

3. **Clean state**: Run `git status --porcelain` and warn if there are uncommitted changes that might conflict.

If any check fails, stop and alert the user before proceeding.
