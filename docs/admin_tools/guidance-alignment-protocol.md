# AI Guidance Alignment Protocol

This protocol defines the standard operating procedure for aligning a project's `docs/ai_guidance` directory with the canonical source of truth, ensuring that local improvements are contributed back to the global standard.

## 1. Context & Scope
- **Target**: `docs/ai_guidance/` (or `docs/` if mapped differently) within the current project.
- **Source of Truth**: `/Users/andreangelantoni/Sites/ai_guidance`
- **Goal**: Bidirectional alignment. Pull global updates and contribute local improvements upstream.

## 2. Deterministic Comparison
Before proposing changes, perform a full deterministic comparison:
1. Run `diff -rq [Target] [Source] --exclude='.git'` to identify ALL differences.
2. **Mandatory Reporting**: List EVERY file that is out of sync. Do not use snippets or summaries.
3. For files with content differences, run a detailed `diff` to understand the nature of the change.

## 3. Inference & Strategy
Analyze the differences using the following logic:
- **New Local Items**: If a file exists in the project but not in the Source of Truth, suggest **pushing it upstream** to `~/Sites/ai_guidance`. The default assumption is that all documentation improvements should be shared globally.
- **Global Updates (Source to Target)**: If a file is missing or outdated compared to the Source of Truth, suggest **pulling/updating** it locally.
- **Diverged Files**: If both have been edited, identify if the local edits should be merged into the global standard or if the local version should be updated from the global standard.

## 4. User Interaction Protocol
Present the findings to the user in a numbered list with bidirectional options:

### Out-of-Sync Items:
1. `[Filename]`
   - [ ] **Option A (Pull)**: Overwrite local with canonical source.
   - [ ] **Option B (Push)**: Update canonical source with local version.
   - [ ] **Option C (Merge)**: Combine changes (specify logic).

### Required Decision:
**How should we proceed? (Apply all suggestions [all] / Select individual options [provide # then `<pull|push|merge|skip>`])**

## 5. Execution
Based on the user's choice:
- **Pull/Update Local**: Perform a `git subtree pull` or `cp` from Source to Target.
- **Push/Update Upstream**: Copy changes from Target to Source (`~/Sites/ai_guidance`) and commit them in the source repo.
- **Merge**: Use a merge tool or manual editing to combine changes before applying to both/either.

---
*Updated by Antigravity on 2026-04-24*
