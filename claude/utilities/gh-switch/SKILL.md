---
name: gh-switch
description: Switch between GitHub accounts (itayshmool/work and ishmool/personal) in the current session
user_invocable: true
---

# GitHub Account Switcher

Switch the active GitHub account and git identity for this Claude Code session.

## Accounts

| Alias    | GitHub User   | Git Name      | Git Email              |
|----------|---------------|---------------|------------------------|
| work     | itayshmool    | itays         | itays@wix.com          |
| personal | ishmool       | itay shmool   | itay.shmool@gmail.com  |

## Instructions

1. Parse the user's input to determine which account they want. Accept: `work`, `personal`, `itayshmool`, `ishmool`, or just the account name. If no argument is given, show the current active account and ask which one to switch to.

2. Run the following commands to switch:

```bash
# Switch gh CLI active account
gh auth switch --user <github_username>

# Switch git identity for this session (use --global)
git config --global user.name "<git_name>"
git config --global user.email "<git_email>"
```

3. Verify the switch worked:

```bash
gh auth status
git config --global user.name
git config --global user.email
```

4. Report the result: which account is now active, and the git identity in use.
