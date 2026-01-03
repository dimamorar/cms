---
title: Development Workflow & Agent Protocol
description: Workflow rules, code quality standards, and agent protocol from AGENTS.md
tags: [workflow, code-quality, validation, commits]
priority: high
---

# Development Workflow & Agent Protocol

## Work Style

- **Telegraph style**: Noun-phrases ok; drop grammar; min tokens
- **Communication**: Brief, direct responses unless expansion requested
- **Documentation**: Only create docs when explicitly requested

## Code Quality Standards

### File Size Limits

- **Keep files <~500 LOC**: Split/refactor as needed
- If file exceeds limit, suggest splitting into logical modules

### Code Validation

**After modifying code, always validate:**

1. **TypeScript correctness**:
   ```bash
   tsc --noEmit
   ```

2. **Generate import maps** (after creating/modifying components):
   ```bash
   npm run generate:importmap
   ```

3. **Generate types** (after schema changes):
   ```bash
   npm run generate:types
   ```

### Commit Conventions

Use [Conventional Commits](https://www.conventionalcommits.org/):

- `feat`: New feature
- `fix`: Bug fix
- `refactor`: Code refactoring
- `build`: Build system changes
- `ci`: CI/CD changes
- `chore`: Maintenance tasks
- `docs`: Documentation only
- `style`: Code style (formatting, no logic change)
- `perf`: Performance improvements
- `test`: Adding/updating tests

**Examples:**
```bash
git commit -m "feat: add code block HTML converter"
git commit -m "fix: resolve unknown Lexical node rendering"
git commit -m "refactor: split large collection config into modules"
```

## Critical Thinking

1. **Fix root cause, not band-aid**: Address underlying issues, not symptoms
2. **Unsure?**: Read more code; if still stuck, ask with short options
3. **Unrecognized changes**: Assume other agent; keep going; focus your changes
4. **If issues arise**: Stop and ask user before continuing
5. **Leave breadcrumb notes**: Document decisions in code comments when helpful

## Git Workflow

- **Safe by default**: Check `git status/diff/log` before making changes
- **Push only when asked**: Never push commits unless user explicitly requests
- **Review changes**: Always review what will be committed

## Project-Specific Rules

### Payload CMS Specific

- **Type Generation**: Always run `generate:types` after schema changes
- **Import Maps**: Always run `generate:importmap` after component changes
- **Type Validation**: Run `tsc --noEmit` after code modifications
- **Access Control**: Ensure roles exist when modifying collections/globals with access controls

### File Organization

- Keep collections in separate files
- Extract access control to `access/` directory
- Extract hooks to `hooks/` directory
- Use reusable field factories for common patterns
- Document complex access control with comments

## Before Completing Tasks

1. ✅ Run `tsc --noEmit` to verify TypeScript correctness
2. ✅ Run `npm run generate:types` if schema changed
3. ✅ Run `npm run generate:importmap` if components changed
4. ✅ Check for linter errors
5. ✅ Verify changes work as expected

