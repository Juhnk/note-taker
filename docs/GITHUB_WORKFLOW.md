# GitHub Workflow - NoteTaker

## Overview

This document defines the strict Git and GitHub workflow for the NoteTaker project. Following these guidelines ensures clean history, traceable changes, and maintainable code.

---

## Branch Strategy

### Main Branches

**main**
- Production-ready code
- Every commit represents a potentially releasable state
- Protected branch: requires PR and review
- Never commit directly to main
- Tagged for releases (v1.0.0, v1.1.0, etc.)

**develop** (optional for later)
- Integration branch for features
- Use if team grows or for major releases
- For solo development, feature branches merge directly to main

### Supporting Branches

**Feature Branches**
- Format: `feature/short-description`
- Examples:
  - `feature/core-data-setup`
  - `feature/rich-text-editor`
  - `feature/folder-hierarchy`
- Created from: `main`
- Merged back to: `main` via Pull Request
- Deleted after merge

**Bugfix Branches**
- Format: `bugfix/issue-number-description`
- Example: `bugfix/42-sync-crash`
- Created from: `main`
- Merged back to: `main` via Pull Request
- Deleted after merge

**Hotfix Branches**
- Format: `hotfix/critical-issue`
- Example: `hotfix/data-loss-bug`
- Created from: `main`
- Merged back to: `main` immediately
- Used only for critical production issues
- Deleted after merge

---

## Commit Message Convention

### Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Type

Must be one of:
- **feat**: New feature
- **fix**: Bug fix
- **docs**: Documentation only
- **style**: Code style changes (formatting, no logic change)
- **refactor**: Code refactoring (no feature change, no bug fix)
- **perf**: Performance improvement
- **test**: Adding or updating tests
- **chore**: Maintenance tasks (dependencies, build, etc.)

### Scope

Optional. Component affected:
- `core-data`
- `ui`
- `sync`
- `editor`
- `search`
- `folders`

### Subject

- Use imperative mood: "add" not "added" or "adds"
- No capitalization of first letter
- No period at the end
- Maximum 50 characters

### Body

- Optional, but recommended for non-trivial changes
- Explain what and why, not how
- Wrap at 72 characters
- Separate from subject with blank line

### Footer

Optional. References:
- Issues: `Fixes #123` or `Closes #456`
- Breaking changes: `BREAKING CHANGE: description`

### Examples

**Good commits:**
```
feat(core-data): add Note entity with CloudKit sync

Implements Core Data Note entity with attributes for title, content,
dates, and relationships to Folder and Tag entities. Configured
NSPersistentCloudKitContainer for automatic CloudKit synchronization.

Refs #5
```

```
fix(editor): resolve crash when pasting rich text

AttributedString decoding was failing on certain paste operations.
Added error handling and fallback to plain text.

Fixes #42
```

```
docs: update architecture with Core Data models

Replaced all SwiftData references with Core Data. Added detailed
entity schemas and PersistenceController implementation.
```

**Bad commits:**
```
Update files
Fixed bug
WIP
asdf
Changes
```

---

## Pull Request Process

### Creating a Pull Request

1. **Branch up to date**: Ensure your branch is up to date with main
   ```bash
   git checkout main
   git pull origin main
   git checkout feature/your-feature
   git merge main
   # Resolve conflicts if any
   ```

2. **Self-review**: Review your own changes first
   - Read through every line of code changed
   - Remove debug code, console logs
   - Check for TODOs or FIXMEs
   - Verify tests pass

3. **Push branch**:
   ```bash
   git push origin feature/your-feature
   ```

4. **Create PR on GitHub**:
   - Navigate to repository
   - Click "New Pull Request"
   - Select base: `main`, compare: `feature/your-feature`
   - Fill out PR template (see below)

### Pull Request Template

```markdown
## Description

Brief description of what this PR does.

## Type of Change

- [ ] New feature
- [ ] Bug fix
- [ ] Documentation update
- [ ] Refactoring
- [ ] Performance improvement
- [ ] Test additions/updates

## Changes Made

- List of key changes
- Another key change
- Etc.

## Testing

- [ ] Unit tests added/updated (TDD: tests written first)
- [ ] Integration tests added/updated
- [ ] Test coverage ≥ 70% (check component-specific targets)
- [ ] All tests pass locally
- [ ] Pre-commit hook passes
- [ ] Manually tested on iOS simulator
- [ ] Manually tested on macOS
- [ ] Manually tested on physical device
- [ ] Tested with VoiceOver (accessibility)
- [ ] Tested with Dynamic Type
- [ ] Tested in dark mode

## Screenshots (if applicable)

Before | After
--- | ---
screenshot | screenshot

## Checklist

- [ ] Code follows project style guidelines
- [ ] Self-reviewed code
- [ ] Commented complex code
- [ ] Updated PROGRESS.md with completed tasks
- [ ] Updated documentation (if architecture/design changed)
- [ ] No new warnings
- [ ] SwiftLint passes
- [ ] Pre-commit hook passes
- [ ] All tests pass locally
- [ ] Test coverage ≥ 70%
- [ ] No debug print statements
- [ ] Branch is up to date with main
```

### PR Review Criteria

Before approving, verify:
- [ ] Code follows DESIGN_SYSTEM.md guidelines
- [ ] No hardcoded values (use Constants.swift)
- [ ] Error handling is present and appropriate
- [ ] No force-unwrapping (!) unless justified
- [ ] Accessibility labels added for new UI
- [ ] Core Data changes include migration if needed
- [ ] CloudKit schema considerations documented
- [ ] Performance impact considered
- [ ] Memory leaks checked (Instruments if needed)
- [ ] No merge conflicts
- [ ] **All tests pass (CI/CD must be green)**
- [ ] **Test coverage ≥ 70%** (component-specific targets apply)
- [ ] **PROGRESS.md updated** with completed tasks
- [ ] No debug print statements
- [ ] SwiftLint passes
- [ ] No emojis in code or UI (unless explicitly required)
- [ ] Pre-commit hook was run (CI/CD verifies this)

### Merging

1. **Squash and merge** (preferred for feature branches):
   - Combines all commits into one
   - Clean history on main
   - Edit commit message to be descriptive

2. **Regular merge** (for hotfixes or when preserving history):
   - Keeps all commits
   - Use when commit history is valuable

3. **After merge**:
   - Delete feature branch on GitHub
   - Delete local branch: `git branch -d feature/your-feature`
   - Pull latest main: `git checkout main && git pull`

---

## Release Process

### Versioning

Follow Semantic Versioning (SemVer): `MAJOR.MINOR.PATCH`

- **MAJOR**: Incompatible API changes
- **MINOR**: New features, backwards-compatible
- **PATCH**: Bug fixes, backwards-compatible

Examples:
- `0.1.0`: MVP release (first usable version)
- `0.2.0`: Added markdown preview feature
- `0.2.1`: Fixed sync bug
- `1.0.0`: First public release

### Creating a Release

1. **Update version number**:
   - In Xcode: Target -> General -> Version
   - Update CHANGELOG.md

2. **Create release commit**:
   ```bash
   git checkout main
   git pull origin main
   git commit -m "chore(release): version 0.1.0"
   git push origin main
   ```

3. **Create Git tag**:
   ```bash
   git tag -a v0.1.0 -m "Release version 0.1.0 - MVP"
   git push origin v0.1.0
   ```

4. **Create GitHub Release**:
   - Go to Releases -> Draft a new release
   - Choose tag: v0.1.0
   - Release title: Version 0.1.0 - MVP
   - Description: List of changes from CHANGELOG.md
   - Attach build artifacts if needed (IPA, etc.)
   - Publish release

### CHANGELOG.md Format

```markdown
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added
### Changed
### Fixed

## [0.1.0] - 2025-XX-XX

### Added
- Core Data setup with Note, Folder, Tag, Attachment entities
- CloudKit sync via NSPersistentCloudKitContainer
- Basic rich text editing
- Folder hierarchy navigation
- Search functionality

### Known Issues
- Markdown preview not yet implemented
- No iOS/macOS keyboard shortcuts
```

---

## Git Workflow Examples

### Starting a New Feature

```bash
# Ensure main is up to date
git checkout main
git pull origin main

# Create feature branch
git checkout -b feature/folder-hierarchy

# Make changes, commit frequently with good messages
git add .
git commit -m "feat(folders): add Folder entity to Core Data model"

# More changes
git add .
git commit -m "feat(folders): implement folder creation and deletion"

# Push to GitHub
git push origin feature/folder-hierarchy

# Create Pull Request on GitHub
# After approval and merge, clean up
git checkout main
git pull origin main
git branch -d feature/folder-hierarchy
```

### Fixing a Bug

```bash
git checkout main
git pull origin main

git checkout -b bugfix/23-search-crash

# Fix bug
git add .
git commit -m "fix(search): prevent crash when query is empty

Added guard clause to check for empty search query before
executing NSFetchRequest.

Fixes #23"

git push origin bugfix/23-search-crash

# Create PR, merge, clean up
```

### Updating Your Branch with Latest Main

```bash
# Your feature branch has diverged from main
git checkout feature/your-feature

# Option 1: Merge (preserves history)
git merge main

# Option 2: Rebase (cleaner history, rewrites commits)
git rebase main
# If conflicts, resolve and: git rebase --continue

git push origin feature/your-feature --force-with-lease
```

---

## Protected Branch Rules

Configure on GitHub (Settings -> Branches -> main):

- [ ] Require pull request before merging
  - [ ] Require approvals: 1 (if working with others)
  - [ ] Dismiss stale approvals
- [ ] Require status checks to pass
  - [ ] Tests (when CI/CD set up)
  - [ ] Build succeeds
- [ ] Require branches to be up to date
- [ ] Include administrators (enforce for everyone)
- [ ] Restrict who can push (optional: only you)

---

## Git Best Practices

### Do

- Commit early and often
- Write descriptive commit messages
- Keep commits focused (one logical change per commit)
- Review your own changes before pushing
- Pull before pushing
- Test before committing
- Use meaningful branch names
- Delete branches after merge
- Tag releases

### Don't

- Commit broken code
- Mix unrelated changes in one commit
- Commit secrets, API keys, passwords
- Commit commented-out code
- Commit debug print statements
- Force push to main (ever)
- Rewrite public history
- Leave branches unmerged for weeks

### .gitignore Reminders

Already configured, but verify:
- No Xcode user data (`xcuserdata/`)
- No build artifacts (`build/`, `DerivedData/`)
- No .DS_Store files
- No API keys or secrets

---

## Pre-Commit Hooks

### Setup

Run once to install pre-commit hooks:

```bash
./scripts/setup-hooks.sh
```

This installs:
- Pre-commit hook that runs before every commit
- SwiftLint for code quality
- .swiftlint.yml configuration

### Pre-Commit Hook Checks

The pre-commit hook automatically runs before EVERY commit (~30 seconds) and blocks the commit if:

- [ ] SwiftLint fails (code quality issues)
- [ ] Debug print statements found (with user confirmation)
- [ ] Syntax errors detected

**Fast feedback in ~30 seconds.**

**What's NOT in pre-commit** (happens in CI/CD instead):
- ❌ Full iOS/macOS builds (too slow: 2-5 min each)
- ❌ Full test suites (too slow: 1-3 min each)
- ❌ Code coverage checks (too slow: ~2 min)

**Total time: ~30 seconds vs 6-16 minutes** ⚡

This design prioritizes "maximum simplicity" and supports small 2-3 day cycles with multiple commits per day.

### Bypassing Pre-Commit Hook

**NOT RECOMMENDED**, but if absolutely necessary:

```bash
git commit --no-verify -m "message"
```

Note: CI/CD will still run and may reject your PR.

### Pre-Commit Hook Benefits

- Catches errors before they reach GitHub
- Ensures tests are always passing
- Maintains code quality standards
- Prevents broken code in history
- Saves time by catching issues early

---

## Continuous Integration (CI/CD)

### GitHub Actions Workflows

Two workflows run automatically:

**1. CI/CD Pipeline** (`.github/workflows/ci.yml`)
- Runs on: Every PR and push to main
- Runner: macOS-15 (Xcode 16.4)
- Jobs:
  - SwiftLint (code quality)
  - Test iOS (build + tests + coverage)
  - Test macOS (build + tests + coverage)
  - Build iOS Release
  - Build macOS Release
- Blocks merge if any job fails
- **Progressive coverage requirements** (see docs/TESTING.md):
  - Sprint 0: Disabled
  - Sprint 1-2: 40% minimum
  - Sprint 3-5: 50% minimum
  - Sprint 6-9: 60% minimum
  - Sprint 10+: 70% minimum

**2. PR Validation** (`.github/workflows/pr-checks.yml`)
- Runs on: Every PR
- Checks:
  - PR title follows conventional commits
  - Commit messages follow conventional commits
  - No TODOs without issue numbers
  - Accessibility labels in new UI code
  - PROGRESS.md updated for feature/fix PRs
  - No debug print statements
  - PR size warnings (> 20 files or > 1000 lines)
  - Documentation updated for code changes

### CI/CD Requirements

**All checks must pass before merging:**

- ✅ SwiftLint passes
- ✅ iOS build succeeds
- ✅ macOS build succeeds
- ✅ iOS tests pass (100%)
- ✅ macOS tests pass (100%)
- ✅ Code coverage meets progressive target (Sprint 0: disabled, Sprint 1+: see table above)
- ✅ PR title is conventional commit format
- ✅ All commit messages are conventional format

**Current Coverage Target**: Sprint 0 = Disabled (update in `.github/workflows/ci.yml` when advancing sprints)

### Viewing CI/CD Results

1. Open your Pull Request on GitHub
2. Scroll to "Checks" section at the bottom
3. Click "Details" on any failed check
4. Review logs to identify issue
5. Fix and push - CI/CD will re-run automatically

### CI/CD Failure Examples

**SwiftLint Failure:**
```
❌ SwiftLint
Line 45: Force unwrapping is not allowed
```
Fix: Remove force unwraps (!)

**Test Failure:**
```
❌ Test iOS
NotesViewModelTests.testCreateNote failed:
Expected 1, got 0
```
Fix: Fix the failing test

**Coverage Failure:**
```
❌ Check code coverage
ERROR: Code coverage is below 40% (got 35%)  # Sprint 1-2 minimum
```
Fix: Add more tests to meet progressive target (see docs/TESTING.md)

---

## Code Review Guidelines

### For Authors

- Keep PRs small (< 400 lines changed ideally)
- Provide context in PR description
- Respond to feedback professionally
- Don't take criticism personally
- Fix requested changes promptly

### For Reviewers

- Review within 24 hours
- Be constructive and specific
- Explain the "why" behind feedback
- Approve when requirements met
- Use "Request changes" only for serious issues

### Review Checklist

```markdown
## Functionality
- [ ] Code does what PR describes
- [ ] Edge cases handled
- [ ] Error handling appropriate

## Code Quality
- [ ] Follows style guide
- [ ] No code duplication
- [ ] Functions are small and focused
- [ ] Naming is clear

## Testing
- [ ] Tests included
- [ ] Tests pass
- [ ] Coverage adequate

## Documentation
- [ ] Code comments where needed
- [ ] README updated if needed
- [ ] Architecture docs updated if needed

## Performance
- [ ] No obvious performance issues
- [ ] Database queries optimized
- [ ] Image loading efficient

## Security
- [ ] No hardcoded secrets
- [ ] Input validated
- [ ] SQL injection prevented (Core Data handles this)
```

---

## Troubleshooting

### Merge Conflicts

```bash
# When merge conflict occurs
git checkout feature/your-feature
git merge main

# Git will mark conflicts in files
# Open files, look for:
<<<<<<< HEAD
your changes
=======
main branch changes
>>>>>>> main

# Resolve manually, then:
git add resolved-file.swift
git commit -m "merge: resolve conflicts with main"
git push origin feature/your-feature
```

### Accidentally Committed to Main

```bash
# If not pushed yet
git reset HEAD~1  # Undo last commit, keep changes
git checkout -b feature/oops
git add .
git commit -m "feat: proper commit"

# If already pushed (BAD, avoid this)
# Contact team, may need force push (dangerous)
```

### Lost Work

```bash
# Find lost commits
git reflog

# Recover
git checkout <commit-hash>
git checkout -b recovered-work
```

---

## Summary

- Always work on feature branches
- Write clear, conventional commit messages
- **Write tests FIRST** (TDD approach, progressive coverage targets)
- **Pre-commit hook is FAST** (~30 seconds: lint, syntax only)
- **CI/CD blocks merges without passing tests**
- Create descriptive Pull Requests
- Self-review before requesting review
- **Update PROGRESS.md** after completing tasks
- Keep main branch protected and clean
- Tag releases following SemVer
- Delete branches after merge
- Document decisions in commit messages

Following this workflow ensures high code quality, clear history, and smooth collaboration (even when solo).

**Key Quality Gates:**
1. **Pre-commit hook** (local, ~30 sec) - Fast syntax and style checks
2. **CI/CD pipeline** (GitHub) - Full validation, prevents bad merges
3. **Progressive coverage** (40% → 70%) - Practical quality improvement
4. **Progress tracking** (PROGRESS.md) - Maintains visibility

**Philosophy**:
- Pre-commit = Fast feedback loop (supports "maximum simplicity")
- CI/CD = Quality enforcement (blocks bad code)
- Progressive coverage = Practical approach (not perfectionism)
