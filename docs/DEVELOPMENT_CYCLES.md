# Development Cycles - NoteTaker

## Purpose

Break development into small, manageable cycles to:
1. Avoid AI context overload
2. Maintain high code quality
3. Ensure frequent testing
4. Track progress incrementally
5. Make steady, measurable progress

---

## Cycle Rules

### Maximum Duration
- **2-3 days** per cycle maximum
- If a cycle takes longer, it's too big - break it down

### Maximum Features
- **1-3 features** per cycle
- Focus on completion, not starting many things

### Required Elements
Every cycle MUST include:
1. Feature implementation
2. Unit tests (minimum 70% coverage)
3. Documentation updates
4. Manual testing on iOS and macOS
5. Git commit with conventional message

---

## Cycle Structure

### 1. Planning (15 minutes)
- [ ] Read PROGRESS.md for current sprint
- [ ] Identify 1-3 tasks from sprint
- [ ] Verify prerequisites are complete
- [ ] Check dependencies
- [ ] Estimate time (2-3 days max)

### 2. Implementation (1-2 days)
- [ ] Create feature branch
- [ ] Write failing tests first (TDD)
- [ ] Implement feature
- [ ] Make tests pass
- [ ] Refactor if needed
- [ ] Follow DESIGN_SYSTEM.md
- [ ] Follow ARCHITECTURE.md patterns
- [ ] Add accessibility labels
- [ ] Test manually on iOS
- [ ] Test manually on macOS

### 3. Testing (Half day)
- [ ] Run all unit tests
- [ ] Verify coverage ≥ 70%
- [ ] Run integration tests (if applicable)
- [ ] Run UI tests (if applicable)
- [ ] Test with VoiceOver
- [ ] Test with Dynamic Type
- [ ] Test dark mode
- [ ] Fix any bugs found

### 4. Documentation (1 hour)
- [ ] Update code comments
- [ ] Update PROGRESS.md (check off completed items)
- [ ] Update ARCHITECTURE.md (if architecture changed)
- [ ] Update DESIGN_SYSTEM.md (if UI patterns added)
- [ ] Update README.md (if user-facing changes)

### 5. Review & Commit (30 minutes)
- [ ] Self-review all changes
- [ ] Run SwiftLint
- [ ] Ensure tests pass
- [ ] Commit with conventional message
- [ ] Push to GitHub
- [ ] Create Pull Request
- [ ] Wait for CI/CD to pass

### 6. Reflection (15 minutes)
- [ ] What went well?
- [ ] What could be improved?
- [ ] Any blockers for next cycle?
- [ ] Update cycle size if needed

---

## Example Cycles

### Cycle Example 1: Core Data Setup (2 days)

**Goal**: Set up Core Data with Note and Folder entities

**Day 1**:
- Create .xcdatamodeld file
- Add Note entity with attributes
- Add Folder entity with attributes
- Define relationships
- Generate NSManagedObject subclasses
- Write unit tests for entity creation
- Test saves and fetches

**Day 2**:
- Create PersistenceController
- Configure NSPersistentCloudKitContainer
- Set up CloudKit sync options
- Write integration tests
- Test on iOS and macOS
- Update PROGRESS.md
- Commit and PR

**Tasks Completed**:
- [x] Core Data model created
- [x] Entities defined
- [x] Persistence controller set up
- [x] Tests written (80% coverage)

---

### Cycle Example 2: Rich Text Editor (3 days)

**Goal**: Implement basic rich text editing

**Day 1**:
- Research AttributedString encoding
- Create EditorView with TextEditor
- Write tests for encoding/decoding
- Implement encoding to Data
- Implement decoding from Data
- Test on iOS 18

**Day 2**:
- Save rich text to Core Data
- Load rich text from Core Data
- Test save/load cycle
- Add error handling
- Write integration tests

**Day 3**:
- Create FormattingToolbar
- Add Bold button
- Add Italic button
- Wire up toolbar to editor
- Test formatting on iOS and macOS
- Update PROGRESS.md
- Commit and PR

**Tasks Completed**:
- [x] Rich text encoding/decoding
- [x] Save/load to Core Data
- [x] Basic formatting toolbar
- [x] Tests written (75% coverage)

---

### Cycle Example 3: Search Feature (2 days)

**Goal**: Implement note search functionality

**Day 1**:
- Create SearchService class
- Implement search by title
- Implement search by content
- Write unit tests for SearchService
- Test with sample data

**Day 2**:
- Create SearchBar component
- Add search to HomeView
- Display search results
- Handle empty results
- Test on iOS and macOS
- Write UI tests
- Update PROGRESS.md
- Commit and PR

**Tasks Completed**:
- [x] SearchService implemented
- [x] Search UI added
- [x] Tests written (80% coverage)

---

## Cycle Sizing Guidelines

### Too Small (< 1 day)
Combine with related tasks:
- Adding a single button
- Changing a color
- Fixing a typo

### Just Right (1-3 days)
- Implementing a feature with tests
- Creating a new view with logic
- Adding a service with integration

### Too Large (> 3 days)
Break down into smaller cycles:
- "Implement entire editor" → Split into multiple cycles
- "Add all formatting options" → Do 2-3 at a time
- "Complete folder management" → Split CRUD into separate cycles

---

## Checklist for Starting a Cycle

Before starting any cycle, verify:
- [ ] PROGRESS.md shows what to work on
- [ ] Previous cycle is complete
- [ ] All tests from previous cycle pass
- [ ] CI/CD is green
- [ ] No merge conflicts
- [ ] Development environment is set up
- [ ] Documentation is up to date

---

## Checklist for Completing a Cycle

Before marking a cycle complete:
- [ ] Feature works on iOS
- [ ] Feature works on macOS
- [ ] All new code has tests
- [ ] Test coverage ≥ 70%
- [ ] All tests pass locally
- [ ] SwiftLint passes
- [ ] Dark mode tested
- [ ] VoiceOver tested
- [ ] Documentation updated
- [ ] PROGRESS.md updated
- [ ] Code committed
- [ ] Pull request created
- [ ] CI/CD passes
- [ ] Code reviewed (if not solo)
- [ ] Merged to main
- [ ] Feature branch deleted

---

## Handling Blockers

### If Stuck (> 2 hours)
1. Document the blocker in PROGRESS.md
2. Try a different approach
3. Research the issue
4. Simplify the solution
5. Ask for help (forums, Stack Overflow)
6. Consider deferring to later cycle

### If Cycle Taking Too Long
1. Stop and assess
2. Identify what can be cut
3. Complete minimum viable version
4. Defer additional features to next cycle
5. Update PROGRESS.md with learnings

---

## Context Management for AI

### To Avoid AI Overload

**Do**:
- Keep cycles small (2-3 days)
- Focus on 1-3 related tasks
- Provide clear context each cycle
- Reference specific documentation files
- Break large features into sub-cycles

**Don't**:
- Try to implement entire features at once
- Mix unrelated tasks
- Assume AI remembers previous context
- Skip documentation references
- Work on too many files simultaneously

### Context Refresh Pattern

At the start of each cycle:
1. Read PROGRESS.md to see current sprint
2. Read relevant section of ARCHITECTURE.md
3. Read relevant section of DESIGN_SYSTEM.md
4. Provide brief summary of what was done last cycle
5. State clearly what this cycle will accomplish

Example:
"Last cycle we implemented Core Data setup. This cycle we're implementing rich text encoding/decoding. See ARCHITECTURE.md section on 'AttributedString encoding' for technical approach."

---

## Progress Tracking

### Update PROGRESS.md After Each Cycle

```markdown
### Sprint 1.1: Core Data Setup
- [x] Create Note entity in Core Data model
- [x] Create Folder entity in Core Data model
- [x] Define relationships between Note and Folder
- [x] Create PersistenceController with NSPersistentCloudKitContainer
- [x] Configure CloudKit sync options
- [x] Set up merge policies for conflict resolution
- [x] Write unit tests for Core Data setup
- [x] Test Core Data saves and fetches
- [x] Verify CloudKit container creation

**Status**: Completed
**Actual Time**: 2 days
**Coverage**: 82%
**Notes**: Went smoothly, tests all passing
```

### Weekly Summary

Every Friday, add a weekly summary to PROGRESS.md:

```markdown
### Week 2 (Jan 8-14, 2025)
- [x] Completed Sprint 1.1 (Core Data Setup)
- [x] Completed Sprint 1.2 (Basic CRUD Operations)
- [ ] Started Sprint 1.3 (Basic UI Shell) - 50% done

**Accomplishments**:
- Core Data fully set up with CloudKit sync
- All CRUD operations working with 80%+ test coverage
- Started UI implementation

**Blockers**: None

**Next Week Goals**:
- Complete Sprint 1.3 (Basic UI Shell)
- Start Sprint 1.4 (ViewModels)
```

---

## Cycle Templates

### New Feature Cycle

```markdown
## Cycle: [Feature Name]

**Goal**: [One sentence description]

**Estimated Time**: [1-3 days]

**Prerequisites**: [What must be complete first]

**Tasks**:
- [ ] Task 1
- [ ] Task 2
- [ ] Task 3
- [ ] Write tests
- [ ] Manual testing
- [ ] Update docs

**Acceptance Criteria**:
- Feature works on iOS and macOS
- Tests pass with 70%+ coverage
- Documented in PROGRESS.md

**Status**: Not Started | In Progress | Complete
```

### Bug Fix Cycle

```markdown
## Cycle: Fix [Bug Description]

**Issue**: #[number] - [brief description]

**Root Cause**: [What's causing the bug]

**Estimated Time**: [0.5-1 day]

**Tasks**:
- [ ] Write failing test that reproduces bug
- [ ] Fix bug
- [ ] Verify test passes
- [ ] Manual verification
- [ ] Update relevant docs

**Status**: Not Started | In Progress | Complete
```

---

## Anti-Patterns

### Don't Do This

**Too Ambitious**:
- "This cycle I'll implement the entire editor with all formatting options, search, and sync"
- Problem: 2+ weeks of work, AI context overload, no incremental progress

**Too Vague**:
- "Work on notes feature"
- Problem: No clear goal, can't measure completion

**Skipping Tests**:
- "I'll add tests later in a separate cycle"
- Problem: Tests never get added, coverage drops

**No Documentation**:
- "I'll update docs when everything is done"
- Problem: Docs never get updated, knowledge lost

### Do This Instead

**Right-Sized**:
- "This cycle I'll implement bold and italic formatting with tests"
- Result: Achievable in 1-2 days, clear completion criteria

**Specific**:
- "Implement CoreDataService with create, read, update, delete methods"
- Result: Clear scope, measurable progress

**Test First**:
- "Write tests for CRUD operations, then implement each one"
- Result: High coverage, confident code

**Document As You Go**:
- "Update PROGRESS.md and ARCHITECTURE.md after each cycle"
- Result: Docs stay current, easy to resume later

---

## Summary

- **2-3 days maximum** per cycle
- **1-3 features** per cycle
- **Test everything** (70%+ coverage)
- **Update PROGRESS.md** after each cycle
- **Small, focused cycles** prevent AI overload
- **Clear goals** enable measurable progress
- **Frequent commits** track incremental progress

Following this cycle approach ensures steady progress, high quality, and maintainable development pace.
