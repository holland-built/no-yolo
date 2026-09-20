# hooks

## pre-commit: block a commit that contains a secret

Runs [gitleaks](https://github.com/gitleaks/gitleaks) over what is staged. A hit
refuses the commit, so the secret never enters history. Without gitleaks
installed the hook does nothing, so install it first.

```bash
# the scanner the hook calls
brew install gitleaks          # macOS
# or: apk add gitleaks / apt install gitleaks

# point git at this folder for every repo on the machine, then make it runnable
git config --global core.hooksPath ~/AI/no-yolo/hooks
chmod +x ~/AI/no-yolo/hooks/pre-commit
```

Check it works: stage a file holding a fake key such as `AKIA` followed by 16
capitals, and the commit is refused. Real emergencies skip it with
`git commit --no-verify`.

Note that gitleaks ignores documentation samples on purpose, so the published
`AKIAIOSFODNN7EXAMPLE` key will not trigger it.
