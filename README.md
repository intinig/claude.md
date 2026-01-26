# Development Guidelines for AI-Assisted Programming

**Comprehensive CLAUDE.md guidelines + enforcement agents for Test-Driven Development, TypeScript strict mode, Go best practices, Rust idioms, C# conventions, Unity patterns, and functional programming.**

[![Watch me use my CLAUDE.md file to build a real feature](https://img.youtube.com/vi/rSoeh6K5Fqo/0.jpg)](https://www.youtube.com/watch?v=rSoeh6K5Fqo)

👆 [**Watch a real coding session**](https://www.youtube.com/watch?v=rSoeh6K5Fqo) showing how CLAUDE.md guides AI pair programming in Claude Code.

---

## Table of Contents

- [What This Is](#what-this-is)
- [CLAUDE.md: The Development Framework](#-claudemd-the-development-framework)
- [Claude Code Agents: Automated Enforcement](#-claude-code-agents-automated-enforcement)
- [How to Use This in Your Projects](#-how-to-use-this-in-your-projects)
- [Documentation](#-documentation)
- [Who This Is For](#-who-this-is-for)
- [Philosophy](#-philosophy)
- [Continuous Improvement](#-continuous-improvement)
- [Contributing](#-contributing)
- [Contact](#-contact)

---

## What This Is

A comprehensive **development framework for AI-assisted programming** with Claude Code.

This repository provides:

- **[CLAUDE.md](claude/.claude/CLAUDE.md)** - Core development principles (~200 lines)
- **[Skills](claude/.claude/skills/)** - 25 auto-discovered skill patterns loaded on-demand
- **[Thirteen enforcement agents](claude/.claude/agents/)** - Automated quality enforcement

---

## 📘 CLAUDE.md: The Development Framework

[**→ Read the full CLAUDE.md file**](claude/.claude/CLAUDE.md)

CLAUDE.md is a **living document** that defines development principles, patterns, and anti-patterns. It transforms abstract concepts into actionable decision frameworks.

### Core Philosophy

- **TDD is non-negotiable** - Every line of production code must be test-driven
- **Behavior over implementation** - Tests verify what code does, not how it does it
- **Immutability by default** - Pure functions and immutable data structures
- **Schema-first with nuance** - Runtime validation at trust boundaries, types for internal logic
- **Semantic refactoring** - Abstract based on meaning, not structure
- **Explicit documentation** - Capture learnings while context is fresh

### What Makes It Different

Unlike typical style guides, CLAUDE.md provides:

- **Decision frameworks** - Concrete questions to answer before taking action
- **Priority classifications** - Objective severity levels (Critical/High/Nice/Skip)
- **Quality gates** - Verifiable checklists before commits
- **Anti-pattern catalogs** - Side-by-side good/bad examples
- **Git verification methods** - How to audit compliance retrospectively

### Key Sections

| Section | What It Provides | Detailed Patterns |
|---------|-----------------|-------------------|
| **Testing Principles** | Behavior-driven testing, 100% coverage strategy, factory patterns | [→ skills/testing](claude/.claude/skills/testing/SKILL.md) |
| **Mutation Testing** | Test effectiveness verification, mutation operators, weak test detection | [→ skills/mutation-testing](claude/.claude/skills/mutation-testing/SKILL.md) |
| **Front-End Testing** | DOM Testing Library patterns, accessibility-first queries, userEvent best practices (framework-agnostic) | [→ skills/front-end-testing](claude/.claude/skills/front-end-testing/SKILL.md) |
| **React Testing** | React Testing Library patterns for components, hooks, context, and forms | [→ skills/react-testing](claude/.claude/skills/react-testing/SKILL.md) |
| **TypeScript Guidelines** | Schema-first decision framework, type vs interface clarity, immutability patterns | [→ skills/typescript-strict](claude/.claude/skills/typescript-strict/SKILL.md) |
| **Go Guidelines** | Error handling, small interfaces, context propagation, concurrency patterns | [→ skills/go-strict](claude/.claude/skills/go-strict/SKILL.md) |
| **Rust Guidelines** | Ownership patterns, error handling with Result, traits, async/await concurrency | [→ skills/rust-strict](claude/.claude/skills/rust-strict/SKILL.md) |
| **C# Guidelines** | Nullable reference types, records, constructor injection, async patterns | [→ skills/csharp-strict](claude/.claude/skills/csharp-strict/SKILL.md) |
| **Unity Guidelines** | MonoBehaviour lifecycle, component caching, event cleanup, pooling | [→ skills/unity-strict](claude/.claude/skills/unity-strict/SKILL.md) |
| **TDD Process** | RED-GREEN-REFACTOR cycle, quality gates, anti-patterns | [→ skills/tdd](claude/.claude/skills/tdd/SKILL.md) |
| **Refactoring** | Priority classification, semantic vs structural framework, DRY decision tree | [→ skills/refactoring](claude/.claude/skills/refactoring/SKILL.md) |
| **Functional Programming** | Immutability violations catalog, pure functions, composition patterns | [→ skills/functional](claude/.claude/skills/functional/SKILL.md) |
| **Expectations** | Learning capture guidance, documentation templates, quality criteria | [→ skills/expectations](claude/.claude/skills/expectations/SKILL.md) |
| **Planning** | Small increments, three-document model (PLAN/WIP/LEARNINGS), commit approval | [→ skills/planning](claude/.claude/skills/planning/SKILL.md) |

---

## 📖 Skills Guide

**v3.3 Architecture:** Skills are auto-discovered patterns loaded on-demand when relevant. This reduces always-loaded context from ~3000+ lines to ~200 lines.

### Quick Navigation by Problem

**"I'm struggling with..."** → **Go here:**

| Problem | Skill | Key Insight |
|---------|-------|-------------|
| Tests that break when I refactor | [testing](claude/.claude/skills/testing/SKILL.md) | Test behavior through public APIs, not implementation |
| 100% coverage but bugs still slip through | [mutation-testing](claude/.claude/skills/mutation-testing/SKILL.md) | Coverage measures execution, mutation testing measures detection |
| Tests break when refactoring UI components | [front-end-testing](claude/.claude/skills/front-end-testing/SKILL.md) | Query by role (getByRole), not implementation (framework-agnostic) |
| Testing React components, hooks, or context | [react-testing](claude/.claude/skills/react-testing/SKILL.md) | renderHook for hooks, wrapper for context, test components as functions |
| Don't know when to use schemas vs types | [typescript-strict](claude/.claude/skills/typescript-strict/SKILL.md) | 5-question decision framework |
| Code that "looks the same" - should I abstract it? | [refactoring](claude/.claude/skills/refactoring/SKILL.md) | Semantic vs structural abstraction guide |
| Refactoring everything vs nothing | [refactoring](claude/.claude/skills/refactoring/SKILL.md) | Priority classification (Critical/High/Nice/Skip) |
| Understanding what "DRY" really means | [refactoring](claude/.claude/skills/refactoring/SKILL.md) | DRY = knowledge, not code structure |
| Accidental mutations breaking things | [functional](claude/.claude/skills/functional/SKILL.md) | Complete immutability violations catalog |
| Writing code before tests | [tdd](claude/.claude/skills/tdd/SKILL.md) | TDD quality gates + git verification |
| Losing context on complex features | [expectations](claude/.claude/skills/expectations/SKILL.md) | Learning capture framework (7 criteria) |
| Planning significant work | [planning](claude/.claude/skills/planning/SKILL.md) | Three-document model (PLAN/WIP/LEARNINGS), commit approval |
| Ownership/borrowing confusion in Rust | [rust-strict](claude/.claude/skills/rust-strict/SKILL.md) | Work with the borrow checker, not against it |
| unwrap() causing panics in Rust | [rust-error-handling](claude/.claude/skills/rust-error-handling/SKILL.md) | Use Result, ?, and proper error types |
| Async/concurrency issues in Rust | [rust-concurrency](claude/.claude/skills/rust-concurrency/SKILL.md) | Fearless concurrency through ownership |
| Nullable reference confusion in C# | [csharp-strict](claude/.claude/skills/csharp-strict/SKILL.md) | Enable nullable, never return null for non-nullable |
| async void causing exceptions | [csharp-concurrency](claude/.claude/skills/csharp-concurrency/SKILL.md) | Return Task, use CancellationToken everywhere |
| Unity GetComponent performance | [unity-strict](claude/.claude/skills/unity-strict/SKILL.md) | Cache in Awake, never in Update loops |
| Memory leaks from events in Unity | [unity-patterns](claude/.claude/skills/unity-patterns/SKILL.md) | Subscribe OnEnable, unsubscribe OnDisable |
| GC spikes in Unity games | [unity-performance](claude/.claude/skills/unity-performance/SKILL.md) | Pool objects, avoid allocations in hot paths |

### How Skills Work

Skills are **auto-discovered** by Claude when relevant:
- Writing TypeScript? → `typescript-strict` skill loads automatically
- Writing Go? → `go-strict` skill loads automatically
- Writing Rust? → `rust-strict` skill loads automatically
- Writing C#? → `csharp-strict` skill loads automatically
- Working in Unity? → `unity-strict` + all C# skills load automatically
- Running tests? → `testing` skill provides factory patterns
- After GREEN tests? → `refactoring` skill assesses opportunities
- Reviewing test effectiveness? → `mutation-testing` skill identifies weak tests

**No manual invocation needed** - Claude detects when skills apply.

---

### 🧪 Testing Principles → [skills/testing](claude/.claude/skills/testing/SKILL.md)

**Problem it solves:** Tests that break on every refactor, unclear what to test, low coverage despite many tests

**What's inside:**
- Behavior-driven testing principles with anti-patterns
- Factory function patterns for test data (no `let`/`beforeEach`)
- Achieving 100% coverage through business behavior (not implementation)
- React component testing strategies
- Validating test data with schemas

**Concrete example from the docs:**

```typescript
// ❌ BAD - Implementation-focused test (breaks on refactor)
it("should call validateAmount", () => {
  const spy = jest.spyOn(validator, 'validateAmount');
  processPayment(payment);
  expect(spy).toHaveBeenCalled(); // Will break if we rename or restructure
});

// ✅ GOOD - Behavior-focused test (refactor-safe)
it("should reject payments with negative amounts", () => {
  const payment = getMockPayment({ amount: -100 });
  const result = processPayment(payment);
  expect(result.success).toBe(false);
  expect(result.error.message).toBe("Invalid amount");
});
```

**Why this matters:** The first test will fail if you refactor `validateAmount` into a different structure. The second test only cares about behavior - refactor all you want, as long as negative amounts are rejected.

**Key insight:** A separate `payment-validator.ts` file gets 100% coverage without dedicated tests - it's fully tested through `payment-processor` behavior tests. No 1:1 file mapping needed.

---

### 🧬 Mutation Testing → [skills/mutation-testing](claude/.claude/skills/mutation-testing/SKILL.md)

**Problem it solves:** 100% code coverage but bugs still slip through; tests that don't actually verify behavior; weak assertions that pass regardless of code correctness

**What's inside:**
- Comprehensive mutation operator reference (arithmetic, conditional, logical, boolean, method expressions)
- Weak vs strong test examples for each operator type
- Systematic 4-step branch analysis process
- Equivalent mutant identification and handling
- Test strengthening patterns
- Integration with TDD workflow

**The core insight:**

Code coverage tells you what code your tests *execute*. Mutation testing tells you if your tests would *detect changes* to that code. A test suite with 100% coverage can still miss 40% of potential bugs.

**Concrete example from the docs:**

```typescript
// Production code
const calculateTotal = (price: number, quantity: number): number => {
  return price * quantity;
};

// Mutant: price / quantity
// Question: Would tests fail if * became /?

// ❌ WEAK TEST - Would NOT catch mutant
it('calculates total', () => {
  expect(calculateTotal(10, 1)).toBe(10); // 10 * 1 = 10, 10 / 1 = 10 (SAME!)
});

// ✅ STRONG TEST - Would catch mutant
it('calculates total', () => {
  expect(calculateTotal(10, 3)).toBe(30); // 10 * 3 = 30, 10 / 3 = 3.33 (DIFFERENT!)
});
```

**Why this matters:** The first test uses an identity value (1) that produces the same result for both multiplication and division. The second test uses values that would produce different results, catching the bug.

**Key insight:** Avoid identity values (0 for +/-, 1 for */, empty arrays, all true/false for logical ops) in tests - they let mutants survive.

---

### 🔷 TypeScript Guidelines → [skills/typescript-strict](claude/.claude/skills/typescript-strict/SKILL.md)

**Problem it solves:** Overusing schemas everywhere, or not using them when needed; confusion about `type` vs `interface`

**What's inside:**
- Strict mode requirements and tsconfig setup
- **Type vs interface distinction** (data vs behavior contracts)
- **5-question decision framework**: When schemas ARE vs AREN'T required
- Schema-first development with Zod
- Schema usage in tests (import from shared locations, never redefine)
- Branded types for type safety

**The 5-question framework from the docs:**

Ask these in order:
1. **Does data cross a trust boundary?** (external → internal) → ✅ Schema required
2. **Does type have validation rules?** (format, constraints) → ✅ Schema required
3. **Is this a shared data contract?** (between systems) → ✅ Schema required
4. **Used in test factories?** → ✅ Schema required (for validation)
5. **Pure internal type?** (utility, state, behavior) → ❌ Type is fine

**Concrete example from the docs:**

```typescript
// ❌ Schema NOT needed - pure internal type
type Point = { readonly x: number; readonly y: number };
type CartTotal = { subtotal: number; tax: number; total: number };

// ✅ Schema REQUIRED - API response (trust boundary + validation)
const UserSchema = z.object({
  id: z.string().uuid(),
  email: z.string().email(),
  role: z.enum(["admin", "user", "guest"]),
});
const user = UserSchema.parse(apiResponse);
```

**Key insight:** Not all types need schemas. Use schemas at trust boundaries and for validation. For internal types and utilities, plain TypeScript types are sufficient.

**Critical rule:** Tests must import real schemas from shared locations, never redefine them. This prevents type drift between tests and production.

---

### 🔄 Development Workflow (TDD + Refactoring) → [skills/tdd](claude/.claude/skills/tdd/SKILL.md) + [skills/refactoring](claude/.claude/skills/refactoring/SKILL.md)

**Problem it solves:** Writing code before tests, refactoring too much/too little, not knowing when to abstract

**What's inside:**
- **TDD process with quality gates** (what to verify before each commit)
- **RED-GREEN-REFACTOR** cycle with complete examples
- **Refactoring priority classification** (Critical/High/Nice/Skip)
- **Semantic vs structural abstraction** (the most important refactoring rule)
- **Understanding DRY** - knowledge vs code duplication
- **4-question decision framework** for abstraction
- Git verification methods (audit TDD compliance retrospectively)
- Commit guidelines and PR standards

**The refactoring priority system from the docs:**

🔴 **Critical (Fix Now):** Immutability violations, semantic knowledge duplication, deep nesting (>3 levels)

⚠️ **High Value (Fix This Session):** Unclear names, magic numbers, long functions (>30 lines)

💡 **Nice to Have:** Minor improvements

✅ **Skip:** Code that's already clean, structural similarity without semantic relationship

**The semantic vs structural rule (THE BIG ONE):**

```typescript
// ❌ DO NOT ABSTRACT - Structural similarity, DIFFERENT semantics
const validatePaymentAmount = (amount: number): boolean => {
  return amount > 0 && amount <= 10000; // Fraud rules
};

const validateTransferAmount = (amount: number): boolean => {
  return amount > 0 && amount <= 10000; // Account type rules
};
// They'll evolve independently - abstracting couples unrelated business rules

// ✅ SAFE TO ABSTRACT - Same semantic meaning
const formatUserDisplayName = (first: string, last: string) => `${first} ${last}`.trim();
const formatCustomerDisplayName = (first: string, last: string) => `${first} ${last}`.trim();
const formatEmployeeDisplayName = (first: string, last: string) => `${first} ${last}`.trim();
// All represent "how we display person names" - same business concept

const formatPersonDisplayName = (first: string, last: string) => `${first} ${last}`.trim();
```

**Key insight:** "Duplicate code is far cheaper than the wrong abstraction." Only abstract code that shares the same **semantic meaning**, not just similar structure.

**DRY revelation:** DRY means "Don't Repeat Knowledge" not "Don't Repeat Code Structure". The shipping threshold example in the docs shows this perfectly.

---

### 🎨 Code Style (Functional Programming) → [skills/functional](claude/.claude/skills/functional/SKILL.md)

**Problem it solves:** Accidental mutations, nested conditionals, unclear code, when to use FP abstractions

**What's inside:**
- **Complete immutability violations catalog** (arrays, objects, nested structures)
- Functional programming patterns and when to use heavy FP abstractions
- Code structure principles (max 2 levels nesting)
- Self-documenting code patterns (no comments)
- Naming conventions (functions, types, constants, files)
- **Options objects pattern** (vs positional parameters)

**The immutability catalog from the docs:**

```typescript
// ❌ WRONG - Array mutations
items.push(newItem);        // → [...items, newItem]
items.pop();                // → items.slice(0, -1)
items[0] = updatedItem;     // → items.map((item, i) => i === 0 ? updatedItem : item)
items.sort();               // → [...items].sort()

// ❌ WRONG - Object mutations
user.name = "New Name";     // → { ...user, name: "New Name" }
delete user.email;          // → const { email, ...rest } = user; rest

// ❌ WRONG - Nested mutations
cart.items[0].quantity = 5; // → { ...cart, items: cart.items.map((item, i) => i === 0 ? { ...item, quantity: 5 } : item) }
```

**Options objects pattern:**

```typescript
// Avoid: Unclear at call site
const payment = createPayment(100, "GBP", "card_123", "cust_456", undefined, { orderId: "789" });

// Good: Self-documenting
const payment = createPayment({
  amount: 100,
  currency: "GBP",
  cardId: "card_123",
  customerId: "cust_456",
  metadata: { orderId: "789" },
});
```

**Key insight:** Immutability eliminates entire classes of bugs. The catalog provides the immutable alternative for every common mutation pattern.

---

### 🤝 Working with Claude → [skills/expectations](claude/.claude/skills/expectations/SKILL.md)

**Problem it solves:** Losing context after complex features, forgetting gotchas, unclear expectations

**What's inside:**
- Complete expectations checklist for Claude
- **Learning documentation framework** (7 criteria for what to document)
- Types of learnings to capture (gotchas, patterns, anti-patterns, decisions, edge cases)
- Documentation format templates
- "What do I wish I'd known at the start?" prompts

**The 7 criteria for documenting learnings:**

Document if ANY of these are true:
- ✅ Would save future developers >30 minutes
- ✅ Prevents a class of bugs or errors
- ✅ Reveals non-obvious behavior or constraints
- ✅ Captures architectural rationale or trade-offs
- ✅ Documents domain-specific knowledge
- ✅ Identifies effective patterns or anti-patterns
- ✅ Clarifies tool setup or configuration gotchas

**Documentation template from the docs:**

```markdown
#### Gotcha: [Descriptive Title]

**Context**: When this occurs
**Issue**: What goes wrong
**Solution**: How to handle it

```typescript
// ✅ CORRECT
const example = "correct approach";

// ❌ WRONG
const wrong = "incorrect approach";
```
```

**Key insight:** Capture learnings while context is fresh, not during retrospectives when details are lost. Ask "What do I wish I'd known at the start?" after every significant change.

---

## 🎯 Why These Skills Are Different

Unlike typical style guides, these skills provide:

1. **Decision frameworks** - Concrete questions to answer before taking action (not vague principles)
2. **Priority classifications** - Objective severity levels to prevent over/under-engineering
3. **Anti-pattern catalogs** - Side-by-side good/bad examples showing exactly what to avoid
4. **Git verification methods** - How to audit compliance after the fact
5. **Quality gates** - Verifiable checklists before commits
6. **Problem-oriented** - Organized by the problems you face, not abstract concepts

**Most valuable insight across all skills:** Abstract based on **semantic meaning** (what code represents), not **structural similarity** (what code looks like). This single principle prevents most bad abstractions.

---

### Schema-First Decision Framework Example

One of the most valuable additions - a 5-question framework for when schemas ARE vs AREN'T required:

```typescript
// ✅ Schema REQUIRED - Trust boundary (API response)
const UserSchema = z.object({ id: z.string().uuid(), email: z.string().email() });
const user = UserSchema.parse(apiResponse);

// ❌ Schema OPTIONAL - Pure internal type
type Point = { readonly x: number; readonly y: number };
```

Ask yourself:
1. Does data cross a trust boundary? → Schema required
2. Does type have validation rules? → Schema required
3. Is this a shared data contract? → Schema required
4. Used in test factories? → Schema required
5. Pure internal type? → Type is fine

---

## 🤖 Claude Code Agents: Automated Enforcement

[**→ Read the agents documentation**](claude/.claude/agents/README.md)

Thirteen specialized sub-agents that run in isolated context windows to enforce CLAUDE.md principles and manage development workflow:

### 1. `tdd-guardian` - TDD Compliance Enforcer

**Use proactively** when planning to write code, or **reactively** to verify TDD was followed.

**What it checks:**
- ✅ Tests were written before production code
- ✅ Tests verify behavior (not implementation)
- ✅ All code paths have test coverage
- ✅ Tests use public APIs only
- ❌ Flags implementation-focused tests
- ❌ Catches missing edge case tests

**Example invocation:**
```
You: "I just implemented payment validation. Can you check TDD compliance?"
Claude Code: [Launches tdd-guardian agent]
```

**Output:**
- Lists all TDD violations with file locations
- Identifies implementation-focused tests
- Suggests missing test cases
- Provides actionable recommendations

---

### 2. `ts-enforcer` - TypeScript Strict Mode Enforcer

**Use before commits** or **when adding new types/schemas**.

**What it checks:**
- ❌ `any` types (must use `unknown` or specific types)
- ❌ Type assertions without justification
- ❌ `interface` for data structures (use `type`)
- ✅ Schema-first development (schemas before types at trust boundaries)
- ✅ Immutable data patterns
- ✅ Options objects over positional parameters

**Includes the nuanced schema-first framework:**
- Schema required: Trust boundaries, validation rules, contracts, test factories
- Schema optional: Internal types, utilities, state machines, behavior contracts

**Example invocation:**
```
You: "I've added new TypeScript code. Check for type safety violations."
Claude Code: [Launches ts-enforcer agent]
```

**Output:**
- Critical violations (any types, missing schemas at boundaries)
- High priority issues (mutations, poor structure)
- Style improvements (naming, parameter patterns)
- Compliance score with specific fixes

---

### 3. `go-enforcer` - Go Best Practices Enforcer

**Use before commits** or **when writing Go code**.

**What it checks:**
- ❌ Ignored errors (never `_, _ := ...`)
- ❌ Context stored in structs (should be passed as first parameter)
- ❌ Large interfaces (should be 1-3 methods)
- ✅ Error wrapping with context
- ✅ Idiomatic naming (no Get prefix)
- ✅ Dependency injection patterns

**Example invocation:**
```
You: "I've written some Go code. Check for best practice violations."
Claude Code: [Launches go-enforcer agent]
```

**Output:**
- Critical violations (ignored errors, context in structs)
- High priority issues (large interfaces, Get prefix)
- Style improvements (naming conventions)
- Compliance score with specific fixes

---

### 4. `rust-enforcer` - Rust Best Practices Enforcer

**Use before commits** or **when writing Rust code**.

**What it checks:**
- ❌ unwrap()/expect() in production code (use Result and ?)
- ❌ Unnecessary cloning (prefer borrowing)
- ❌ unsafe blocks without justification
- ✅ Proper error handling with thiserror/anyhow
- ✅ Small traits defined at consumer
- ✅ Ownership-correct patterns

**Example invocation:**
```
You: "I've written some Rust code. Check for idiomatic violations."
Claude Code: [Launches rust-enforcer agent]
```

**Output:**
- Critical violations (unwrap, panic, unsafe without comment)
- High priority issues (clone abuse, large traits)
- Style improvements (naming, clippy warnings)
- Compliance score with specific fixes

---

### 5. `csharp-enforcer` - C# Best Practices Enforcer

**Use before commits** or **when writing C# code**.

**What it checks:**
- ❌ Nullable reference types not enabled (`#nullable enable`)
- ❌ `null` returns for non-nullable types
- ❌ `async void` methods (except event handlers)
- ❌ `.Result`, `.Wait()`, or blocking async
- ✅ Records for DTOs and value objects
- ✅ Constructor injection (no property injection)
- ✅ CancellationToken on all async methods
- ✅ Proper exception handling with guard clauses

**Example invocation:**
```
You: "I've written some C# code. Check for best practice violations."
Claude Code: [Launches csharp-enforcer agent]
```

**Output:**
- Critical violations (nullable disabled, async void, blocking async)
- High priority issues (missing CancellationToken, property injection)
- Style improvements (naming conventions, record usage)
- Compliance score with specific fixes

---

### 6. `unity-enforcer` - Unity Best Practices Enforcer

**Use before commits** or **when writing Unity code**.

**What it checks:**
- ❌ GetComponent in Update/FixedUpdate/LateUpdate (performance killer)
- ❌ `new MonoBehaviour()` (always wrong - use AddComponent)
- ❌ Missing event unsubscription (memory leaks)
- ❌ SendMessage/BroadcastMessage (no compile-time safety)
- ❌ String-based Invoke/InvokeRepeating
- ✅ [SerializeField] for inspector fields (not public)
- ✅ Component caching in Awake
- ✅ Object pooling for frequent spawns

**Example invocation:**
```
You: "I've written some Unity scripts. Check for antipatterns."
Claude Code: [Launches unity-enforcer agent]
```

**Output:**
- Critical violations (GetComponent in Update, new MonoBehaviour)
- High priority issues (event leaks, SendMessage usage)
- Performance warnings (allocations in hot paths, missing pooling)
- Style improvements (RequireComponent, SerializeField)

---

### 7. `refactor-scan` - Refactoring Opportunity Scanner

**Use after achieving green tests** (the REFACTOR step in RED-GREEN-REFACTOR).

**What it analyzes:**
- 🎯 Knowledge duplication (DRY violations)
- 🎯 Semantic vs structural similarity
- 🎯 Complex nested conditionals
- 🎯 Magic numbers and unclear names
- 🎯 Immutability violations

**What it doesn't recommend:**
- ❌ Refactoring code that's already clean
- ❌ Abstracting structurally similar but semantically different code
- ❌ Cosmetic changes without clear value

**Example invocation:**
```
You: "My tests are passing, should I refactor anything?"
Claude Code: [Launches refactor-scan agent]
```

**Output:**
- 🔴 Critical refactoring needed (must fix)
- ⚠️ High value opportunities (should fix)
- 💡 Nice to have improvements (consider)
- ✅ Correctly separated code (keep as-is)
- Specific recommendations with code examples

---

### 8. `docs-guardian` - Documentation Quality Guardian

**Use proactively** when creating documentation or **reactively** to review and improve existing docs.

**What it ensures:**
- ✅ Value-first approach (why before how)
- ✅ Scannable structure (visual hierarchy, clear headings)
- ✅ Progressive disclosure (quick start before deep dive)
- ✅ Problem-oriented navigation (organized by user problems)
- ✅ Concrete examples showing value (not just descriptions)
- ✅ Cross-references and multiple entry points
- ✅ Actionable next steps in every section

**What it checks:**
- ❌ Wall of text without visual breaks
- ❌ Feature lists without value demonstrations
- ❌ Installation-first (before showing what it does)
- ❌ Missing navigation aids
- ❌ Broken links or outdated information

**Example invocation:**
```
You: "I need to write a README for this feature."
Claude Code: [Launches docs-guardian agent]

You: "Can you review the documentation I just wrote?"
Claude Code: [Launches docs-guardian agent]
```

**Output:**
- Assessment against 7 pillars of world-class documentation
- Critical issues (must fix) vs nice-to-haves
- Specific improvement recommendations with examples
- Proposed restructuring for better discoverability
- Templates for common documentation types (README, guides, API docs)

---

### 9. `learn` - CLAUDE.md Learning Integrator

**Use proactively** when discovering gotchas, or **reactively** after completing complex features.

**What it captures:**
- Gotchas or unexpected behavior discovered
- "Aha!" moments or breakthroughs
- Architectural decisions being made
- Patterns that worked particularly well
- Anti-patterns encountered
- Tooling or setup knowledge gained

**Example invocation:**
```
You: "I just fixed a tricky timezone bug. Let me document this gotcha."
Claude Code: [Launches learn agent]
```

**Output:**
- Asks discovery questions about what you learned
- Reads current CLAUDE.md to check for duplicates
- Proposes formatted additions to CLAUDE.md
- Provides rationale for placement and structure

---

### 10. `progress-guardian` - Progress Guardian

**Use proactively** when starting significant multi-step work, or **reactively** to update progress, capture learnings, and handle blockers.

**Three-Document Model:**

| Document | Purpose | Updates |
|----------|---------|---------|
| **PLAN.md** | What we're doing (approved steps) | Only with user approval |
| **WIP.md** | Where we are now (current state) | Constantly |
| **LEARNINGS.md** | What we discovered | As discoveries occur |

**What it manages:**
- Creates and maintains three documents for significant work
- Enforces small increments, TDD, and **commit approval**
- Never modifies PLAN.md without explicit user approval
- Captures learnings as they occur
- At end: orchestrates learning merge, then **deletes all three docs**

**Example invocation:**
```
You: "I need to implement OAuth with JWT tokens and refresh logic"
Claude Code: [Launches progress-guardian to create PLAN.md, WIP.md, LEARNINGS.md]

You: "Tests are passing now"
Claude Code: [Launches progress-guardian to update WIP.md and ask for commit approval]
```

**Output:**
- **PLAN.md** - Approved steps with acceptance criteria
- **WIP.md** - Current step, status, blockers, next action
- **LEARNINGS.md** - Gotchas, patterns, decisions discovered
- At end: learnings merged into CLAUDE.md/ADRs, all docs deleted

**Key distinction:** Creates TEMPORARY documents (deleted when done). Learnings merged into permanent knowledge base first.

**Related skill:** Load `planning` skill for detailed incremental work principles.

---

### 11. `adr` - Architecture Decision Records

**Use proactively** when making significant architectural decisions, or **reactively** to document decisions already made.

**What it documents:**
- Significant architectural choices with trade-offs
- Technology/library selections with long-term impact
- Pattern decisions affecting multiple modules
- Performance vs maintainability trade-offs
- Security architecture decisions

**When to use:**
- ✅ Evaluated multiple alternatives with trade-offs
- ✅ One-way door decisions (hard to reverse)
- ✅ Foundational choices affecting future architecture
- ❌ Trivial implementation choices
- ❌ Temporary workarounds
- ❌ Standard patterns already in CLAUDE.md

**Example invocation:**
```
You: "Should we use BullMQ or AWS SQS for our job queue?"
Claude Code: [Launches adr agent to help evaluate and document]

You: "I decided to use PostgreSQL over MongoDB"
Claude Code: [Launches adr agent to document the rationale]
```

**Output:**
- Structured ADR in `docs/adr/` with context and alternatives
- Honest assessment of pros/cons and trade-offs
- Clear rationale for decision
- Consequences (positive, negative, neutral)
- Updated ADR index

**Key distinction:** Documents WHY architecture chosen (permanent), vs learn agent's HOW to work with it (gotchas, patterns).

---

### 12. `pr-reviewer` - Pull Request Quality Reviewer

**Use proactively** when reviewing a PR, or **reactively** to analyze an existing PR and post feedback.

> **Why Manual Invocation?** This agent is designed for manual invocation during Claude Code sessions rather than automated CI/CD pipelines. This approach saves significant API costs while still providing comprehensive PR reviews when needed.

**What it checks (5 categories):**

| Category | What It Validates |
|----------|------------------|
| **TDD Compliance** | Tests exist for all production changes, test-first approach |
| **Testing Quality** | Behavior-focused tests, factory patterns, no `let`/`beforeEach` |
| **TypeScript Strictness** | No `any` types, proper type usage, schema-first at boundaries |
| **Functional Patterns** | No mutation, pure functions, early returns, no comments |
| **General Quality** | Clean code, no debug statements, security, appropriate scope |

**Example invocation:**
```
You: "Review PR #123 and post feedback"
Claude Code: [Launches pr-reviewer agent, analyzes diff, posts structured review to GitHub]
```

**Output:**
- Summary table with status per category
- Critical issues (must fix before merge)
- High priority issues (should fix)
- Suggestions (nice to have)
- What's good about the PR
- Posts review directly to GitHub as a comment

**Direct GitHub Integration:**
The agent can post reviews directly to PRs using GitHub MCP tools:
- General feedback via `add_issue_comment`
- Formal reviews via `pull_request_review_write`
- Line-specific comments via `add_comment_to_pending_review`

**Project-Specific Customization:**
Use the `/generate-pr-review` command to create a project-specific PR reviewer that combines global rules with your project's conventions. The generator analyzes:
- Existing AI/LLM configs (`.cursorrules`, `CLAUDE.md`, `.github/copilot-instructions.md`)
- Architecture Decision Records (ADRs)
- Project documentation (`CONTRIBUTING.md`, `DEVELOPMENT.md`)
- Tech stack and existing code patterns

---

### 13. `use-case-data-patterns` - Use Case to Data Pattern Analyzer

**Use proactively** when implementing features, or **reactively** to understand how features work end-to-end.

**What it analyzes:**
- Maps user-facing use cases to underlying data patterns
- Traces features through system architecture
- Identifies gaps in data access patterns

**Example invocation:**
```
You: "How does the checkout flow work from user click to database?"
Claude Code: [Launches use-case-data-patterns agent]
```

**Output:**
- Comprehensive analytical report mapping use cases to data patterns
- Database interactions and architectural decisions
- Missing pieces for feature implementation

> **Attribution**: Adapted from [Kieran O'Hara's dotfiles](https://github.com/kieran-ohara/dotfiles/blob/main/config/claude/agents/analyse-use-case-to-data-patterns.md).

---

## 🚀 How to Use This in Your Projects

**Quick navigation by situation:**

| Your Situation | Recommended Option |
|----------------|-------------------|
| "I want this on all my personal projects" | [Option 1: Global Install](#option-1-install-to-claude-global-personal-config--recommended) |
| "I'm setting this up for my team" | [Option 2: Project-specific install](#option-2-use-claudemd--agents-recommended-for-projects) |
| "I just want to try the guidelines first" | [Option 3: CLAUDE.md only](#option-3-use-claudemd-only-minimal) |
| "I need to customize for my team's standards" | [Option 4: Fork and customize](#option-4-fork-and-customize-advanced) |

---

### How the Workflow Works (Regardless of Installation Method)

Once installed (via any option below), here's the typical development flow:

1. **Start feature**: Plan with Claude, let tdd-guardian guide test-first approach
2. **Write tests**: Get RED (failing test)
3. **Implement**: Get GREEN (minimal code to pass)
4. **Refactor**: Run refactor-scan to assess opportunities
5. **Review**: Run ts-enforcer and tdd-guardian before commit
6. **Document**: Use learn agent to capture insights, docs-guardian for user-facing docs
7. **Commit**: Follow conventional commits format

**Agent invocation examples:**

Agents can be invoked implicitly (Claude detects when to use them) or explicitly:

- **Implicit**: "I just implemented payment processing. Can you verify I followed TDD?" → Claude automatically launches tdd-guardian
- **Explicit**: "Launch the refactor-scan agent to assess code quality" → Claude launches refactor-scan
- **Multiple agents**: "Run TDD, TypeScript, and refactoring checks on my recent changes" → Claude launches all three in parallel

**Now choose your installation method:**

---

### Option 1: Install to ~/.claude/ (Global Personal Config) ⭐ RECOMMENDED

**Best for:** Individual developers who want consistent practices across all projects

**Why choose this:**
- ✅ One-time setup applies everywhere automatically
- ✅ No per-project configuration needed
- ✅ Works with Claude Code immediately
- ✅ Modular structure loads details on-demand
- ✅ Easy updates via git pull

**One-liner installation (macOS/Linux):**
```bash
curl -fsSL https://raw.githubusercontent.com/intinig/claude.md/main/install-claude.sh | bash
```

**One-liner installation (Windows PowerShell):**
```powershell
irm https://raw.githubusercontent.com/intinig/claude.md/main/install-claude.ps1 | iex
```

**One-liner with options** (use `bash -s --` to pass arguments):
```bash
# Install with OpenCode support
curl -fsSL https://raw.githubusercontent.com/intinig/claude.md/main/install-claude.sh | bash -s -- --with-opencode

# Install specific version
curl -fsSL https://raw.githubusercontent.com/intinig/claude.md/main/install-claude.sh | bash -s -- --version v2.0.0

# Install only TypeScript support
curl -fsSL https://raw.githubusercontent.com/intinig/claude.md/main/install-claude.sh | bash -s -- --lang typescript

# Install multiple languages
curl -fsSL https://raw.githubusercontent.com/intinig/claude.md/main/install-claude.sh | bash -s -- --lang go,rust
```

**Or download and run:**
```bash
# macOS/Linux
curl -fsSL https://raw.githubusercontent.com/intinig/claude.md/main/install-claude.sh -o install-claude.sh
chmod +x install-claude.sh
./install-claude.sh

# Windows PowerShell
Invoke-WebRequest -Uri https://raw.githubusercontent.com/intinig/claude.md/main/install-claude.ps1 -OutFile install-claude.ps1
.\install-claude.ps1
```

**Install options (bash):**
```bash
./install-claude.sh                    # Install everything (all languages)
./install-claude.sh --claude-only      # Install only CLAUDE.md
./install-claude.sh --skills-only      # Install only skills
./install-claude.sh --no-agents        # Install without agents
./install-claude.sh --with-opencode    # Also install OpenCode configuration
./install-claude.sh --version v2.0.0   # Install v2.0.0 (modular docs)
./install-claude.sh --version v1.0.0   # Install v1.0.0 (single file)
./install-claude.sh --lang typescript  # Install only TypeScript support
./install-claude.sh --lang go,rust     # Install Go and Rust support
./install-claude.sh --lang unity       # Install Unity + C# support (Unity includes C#)
```

**Install options (PowerShell):**
```powershell
.\install-claude.ps1                    # Install everything (all languages)
.\install-claude.ps1 -ClaudeOnly        # Install only CLAUDE.md
.\install-claude.ps1 -SkillsOnly        # Install only skills
.\install-claude.ps1 -NoAgents          # Install without agents
.\install-claude.ps1 -Lang typescript   # Install only TypeScript support
.\install-claude.ps1 -Lang go,rust      # Install Go and Rust support
.\install-claude.ps1 -Lang unity        # Install Unity + C# support
```

**Language options for `--lang` / `-Lang`:**
| Language | Aliases | Skills Installed |
|----------|---------|------------------|
| typescript | ts | typescript-strict, react-testing, front-end-testing |
| go | golang | go-strict, go-testing, go-error-handling, go-concurrency |
| rust | rs | rust-strict, rust-testing, rust-error-handling, rust-concurrency |
| csharp | cs, c# | csharp-strict, csharp-testing, csharp-error-handling, csharp-concurrency |
| unity | unity3d | All C# skills + unity-strict, unity-testing, unity-patterns, unity-performance |

**What gets installed (v3.3.0):**
- ✅ `~/.claude/CLAUDE.md` (~200 lines - lean core principles with shell configuration)
- ✅ `~/.claude/skills/` (25 auto-discovered patterns):
  - **Core:** tdd, testing, mutation-testing, functional, refactoring, expectations, planning
  - **TypeScript:** typescript-strict, front-end-testing, react-testing
  - **Go:** go-strict, go-testing, go-error-handling, go-concurrency
  - **Rust:** rust-strict, rust-testing, rust-error-handling, rust-concurrency
  - **C#:** csharp-strict, csharp-testing, csharp-error-handling, csharp-concurrency
  - **Unity:** unity-strict, unity-testing, unity-patterns, unity-performance
- ✅ `~/.claude/commands/` (2 slash commands: /pr, /generate-pr-review)
- ✅ `~/.claude/agents/` (13 automated enforcement agents including csharp-enforcer, unity-enforcer)

**Optional: Enable GitHub MCP Integration**

For enhanced GitHub workflows with native PR/issue integration:

**Step 1: Create a GitHub Personal Access Token**

Go to https://github.com/settings/tokens and create a token:

**For Fine-grained token (recommended):**
- Repository access: All repositories (or select specific ones)
- Permissions required:
  - **Contents**: Read and write
  - **Pull requests**: Read and write
  - **Issues**: Read and write
  - **Metadata**: Read-only (automatically included)

**For Classic token:**
- Select the `repo` scope (full control of private repositories)

**Step 2: Add the MCP Server**

```bash
claude mcp add --transport http --scope user github https://api.githubcopilot.com/mcp/ \
  --header "Authorization: Bearer YOUR_GITHUB_TOKEN"
```

Replace `YOUR_GITHUB_TOKEN` with the token you created.

**Step 3: Verify Connection**

Restart Claude Code and run `/mcp` to verify the GitHub server shows as connected.

**What this enables:**
- Native PR creation, updates, and reviews
- Issue management without CLI parsing
- Structured GitHub API access
- `@github:pr://123` - Reference PRs directly in prompts
- `@github:issue://45` - Reference issues directly in prompts

**Optional: Enable OpenCode Support**

These guidelines also work with [OpenCode](https://opencode.ai) - an open source AI coding agent. OpenCode uses `AGENTS.md` for custom instructions (similar to `CLAUDE.md` in Claude Code).

**How OpenCode Integration Works:**

OpenCode doesn't automatically read `~/.claude/` files. Instead, it uses a configuration file to specify which instruction files to load. The `opencode.json` configuration tells OpenCode to load your CLAUDE.md and skills files.

**Installation:**

```bash
# One-liner with OpenCode support
curl -fsSL https://raw.githubusercontent.com/intinig/claude.md/main/install-claude.sh | bash -s -- --with-opencode

# Or download and run with options
curl -fsSL https://raw.githubusercontent.com/intinig/claude.md/main/install-claude.sh -o install-claude.sh
chmod +x install-claude.sh
./install-claude.sh --with-opencode

# Install OpenCode config only (if you already have CLAUDE.md installed)
curl -fsSL https://raw.githubusercontent.com/intinig/claude.md/main/install-claude.sh | bash -s -- --opencode-only
```

**What gets installed:**
- `~/.config/opencode/opencode.json` - Configuration that loads:
  - `~/.claude/CLAUDE.md` (core principles)
  - `~/.claude/skills/*/SKILL.md` (all skill patterns)

**Manual Installation:**

If you prefer to set it up manually:

```bash
mkdir -p ~/.config/opencode
cat > ~/.config/opencode/opencode.json << 'EOF'
{
  "$schema": "https://opencode.ai/config.json",
  "instructions": [
    "~/.claude/CLAUDE.md",
    "~/.claude/skills/*/SKILL.md"
  ]
}
EOF
```

**Learn more:**
- [OpenCode Documentation](https://opencode.ai/docs/)
- [OpenCode Rules Configuration](https://opencode.ai/docs/rules/)
- [OpenCode GitHub](https://github.com/sst/opencode)

---

### Option 2: Use CLAUDE.md + Agents (Recommended for Projects)

**Best for:** Team projects where you want full control and project-specific configuration

**Why choose this:**
- ✅ Full enforcement in a specific project
- ✅ Team can collaborate on customizations
- ✅ Version control with your project
- ✅ Works without global installation

For full enforcement in a specific project, install both CLAUDE.md and the agents:

```bash
# In your project root
mkdir -p .claude/agents

# Download CLAUDE.md
curl -o .claude/CLAUDE.md https://raw.githubusercontent.com/intinig/claude.md/main/claude/.claude/CLAUDE.md

# Download all agents
curl -o .claude/agents/tdd-guardian.md https://raw.githubusercontent.com/intinig/claude.md/main/claude/.claude/agents/tdd-guardian.md
curl -o .claude/agents/ts-enforcer.md https://raw.githubusercontent.com/intinig/claude.md/main/claude/.claude/agents/ts-enforcer.md
curl -o .claude/agents/go-enforcer.md https://raw.githubusercontent.com/intinig/claude.md/main/claude/.claude/agents/go-enforcer.md
curl -o .claude/agents/rust-enforcer.md https://raw.githubusercontent.com/intinig/claude.md/main/claude/.claude/agents/rust-enforcer.md
curl -o .claude/agents/csharp-enforcer.md https://raw.githubusercontent.com/intinig/claude.md/main/claude/.claude/agents/csharp-enforcer.md
curl -o .claude/agents/unity-enforcer.md https://raw.githubusercontent.com/intinig/claude.md/main/claude/.claude/agents/unity-enforcer.md
curl -o .claude/agents/refactor-scan.md https://raw.githubusercontent.com/intinig/claude.md/main/claude/.claude/agents/refactor-scan.md
curl -o .claude/agents/docs-guardian.md https://raw.githubusercontent.com/intinig/claude.md/main/claude/.claude/agents/docs-guardian.md
curl -o .claude/agents/learn.md https://raw.githubusercontent.com/intinig/claude.md/main/claude/.claude/agents/learn.md
curl -o .claude/agents/progress-guardian.md https://raw.githubusercontent.com/intinig/claude.md/main/claude/.claude/agents/progress-guardian.md
curl -o .claude/agents/adr.md https://raw.githubusercontent.com/intinig/claude.md/main/claude/.claude/agents/adr.md
curl -o .claude/agents/pr-reviewer.md https://raw.githubusercontent.com/intinig/claude.md/main/claude/.claude/agents/pr-reviewer.md
curl -o .claude/agents/use-case-data-patterns.md https://raw.githubusercontent.com/intinig/claude.md/main/claude/.claude/agents/use-case-data-patterns.md

# Download agents README
curl -o .claude/agents/README.md https://raw.githubusercontent.com/intinig/claude.md/main/claude/.claude/agents/README.md

# Download commands
mkdir -p .claude/commands
curl -o .claude/commands/pr.md https://raw.githubusercontent.com/intinig/claude.md/main/claude/.claude/commands/pr.md
curl -o .claude/commands/generate-pr-review.md https://raw.githubusercontent.com/intinig/claude.md/main/claude/.claude/commands/generate-pr-review.md
```

---

### Option 3: Use CLAUDE.md Only - Single File (v1.0.0)

**Best for:** Quick evaluation or when you want everything in one standalone file

**Why choose this:**
- ✅ Single command, one file (1,818 lines)
- ✅ All content included - examples, anti-patterns, decision frameworks
- ✅ Works standalone (no broken imports)
- ✅ No agent overhead
- ⚠️ **Tradeoff:** Larger file vs v2.0.0's modular structure (156 lines + separate docs)
- ⚠️ **Tradeoff:** Uses v1.0.0 structure (content identical to v2.0.0, just organized differently)

**Important:** This downloads the v1.0.0 monolithic version. v3.0.0 no longer has @import issues - CLAUDE.md is fully self-contained with skills loaded on-demand. For project-level use, v3.0.0 is now recommended.

Download the complete single-file version:

```bash
# In your project root
mkdir -p .claude
curl -o .claude/CLAUDE.md https://raw.githubusercontent.com/intinig/claude.md/v1.0.0/claude/.claude/CLAUDE.md
```

This gives you the complete guidelines (1,818 lines) in a single standalone file.

---

### Option 4: Fork and Customize (Advanced)

**Best for:** Teams with specific standards who need full customization control

**Why choose this:**
- ✅ Complete control over guidelines and enforcement
- ✅ Customize for your team's specific tech stack
- ✅ Modify agent behavior to match your workflow
- ✅ Maintain team-specific patterns and anti-patterns

**How to customize:**

1. Fork this repository
2. Modify CLAUDE.md to match your team's preferences
3. Customize agents to enforce your specific rules
4. Commit to your fork
5. Pull into your projects

---

### Version Note: v1.0.0 vs v2.0.0 vs v3.x

**Current version (v3.3.0):** Skills-based architecture with lean CLAUDE.md (~200 lines) + 25 auto-discovered skills + C#/Unity support + shell configuration

**Previous v3 versions:**
- v3.2.0: Added Go and Rust support
- v3.0.0: Initial skills-based architecture (TypeScript focus)

**Previous version (v2.0.0):** Modular structure with main file (156 lines) + 6 detailed docs loaded via @imports (~3000+ lines total)

**Legacy version (v1.0.0):** Single monolithic file (1,818 lines, all-in-one)

| Version | Architecture | Context Size | Languages | Best For |
|---------|--------------|--------------|-----------|----------|
| **v3.3.0** | Skills (on-demand) | ~200 lines always | TS, Go, Rust, C#, Unity | Multi-language projects |
| **v3.2.0** | Skills (on-demand) | ~100 lines always | TS, Go, Rust | Backend-focused |
| **v2.0.0** | @docs/ imports | ~3000 lines always | TS only | Full docs always loaded |
| **v1.0.0** | Single file | ~1800 lines always | TS only | Standalone, no dependencies |

- **v3.3.0 (current):** https://github.com/intinig/claude.md/tree/main/claude/.claude
- **v2.0.0 modular docs:** https://github.com/intinig/claude.md/tree/v2.0.0/claude/.claude
- **v1.0.0 single file:** https://github.com/intinig/claude.md/blob/v1.0.0/claude/.claude/CLAUDE.md

The installation script installs v3.3.0 by default. Use `--version v2.0.0` or `--version v1.0.0` for older versions.

Use `--lang` option to install only specific language support (e.g., `--lang typescript,go`).

---

## 📚 Documentation

- **[CLAUDE.md](claude/.claude/CLAUDE.md)** - Core development principles (~200 lines)
- **[Skills](claude/.claude/skills/)** - Auto-discovered patterns (25 skills):
  - Core: tdd, testing, mutation-testing, functional, refactoring, expectations, planning
  - TypeScript: typescript-strict, front-end-testing, react-testing
  - Go: go-strict, go-testing, go-error-handling, go-concurrency
  - Rust: rust-strict, rust-testing, rust-error-handling, rust-concurrency
  - C#: csharp-strict, csharp-testing, csharp-error-handling, csharp-concurrency
  - Unity: unity-strict, unity-testing, unity-patterns, unity-performance
- **[Commands](claude/.claude/commands/)** - Slash commands (/pr, /generate-pr-review)
- **[Agents README](claude/.claude/agents/README.md)** - Detailed agent documentation with examples
- **[Agent Definitions](claude/.claude/agents/)** - Individual agent configuration files (13 agents including csharp-enforcer, unity-enforcer, go-enforcer, rust-enforcer, pr-reviewer)

---

## 🎯 Who This Is For

- **Teams adopting TDD** - Automated enforcement prevents backsliding
- **TypeScript projects** - Nuanced schema-first guidance with decision frameworks
- **Go/Rust projects** - Idiomatic patterns and error handling
- **C#/.NET projects** - Nullable safety, async patterns, dependency injection
- **Unity game developers** - Performance patterns, lifecycle management, pooling
- **AI-assisted development** - Consistent quality with Claude Code or similar tools
- **Solo developers** - Institutional knowledge that doesn't rely on memory
- **Code reviewers** - Objective quality criteria and git verification methods

### Shell Configuration

**Important:** CLAUDE.md v3.3.0 includes mandatory shell configuration:

| Platform | Shell | Command |
|----------|-------|---------|
| **Windows** | PowerShell (pwsh) | `pwsh -Command "..."` |
| **macOS/Linux** | Bash | `bash -c "..."` |

Windows users must use PowerShell (`pwsh.exe`), never bash or cmd. This ensures consistent behavior across platforms.

---

## 💡 Philosophy

This system is based on several key insights:

1. **AI needs explicit context** - Vague principles → inconsistent results. Decision frameworks → reliable outcomes.

2. **Quality gates prevent drift** - Automated checking catches violations before they become habits.

3. **Refactoring needs priority** - Not all improvements are equal. Critical/High/Nice/Skip classification prevents over-engineering.

4. **Semantic beats structural** - Abstract based on meaning (business concepts), not appearance (code structure).

5. **Document while fresh** - Capture learnings immediately, not during retrospectives when context is lost.

6. **Explicit "no refactoring"** - Saying "code is already clean" prevents the feeling that the refactor step was skipped.

---

## 🔄 Continuous Improvement

CLAUDE.md and the agents evolve based on real usage. The `learn` agent ensures valuable insights are captured and integrated:

- Gotchas discovered → Documented in CLAUDE.md
- Patterns that work → Added to examples
- Anti-patterns encountered → Added to warnings
- Architectural decisions → Preserved with rationale

This creates a **self-improving system** where each project session makes future sessions more effective.

---

## 🤝 Contributing

Contributions are welcome, especially:

- **Improvements to CLAUDE.md** - Better decision frameworks, clearer examples
- **Agent enhancements** - New checks, better error messages
- **Documentation** - Clarifications, additional examples
- **Real-world feedback** - What worked? What didn't?

Please open issues or PRs on GitHub.

---

## 📞 Contact

**Paul Hammond**

- [LinkedIn](https://www.linkedin.com/in/paul-hammond-bb5b78251/) - Feel free to connect and discuss
- [GitHub Issues](https://github.com/intinig/claude.md/issues) - Questions, suggestions, feedback

---

## 🙏 Acknowledgments

Special thanks to contributors who have shared their work:

- **[Kieran O'Hara](https://github.com/kieran-ohara)** - The `use-case-data-patterns` agent is adapted from [Kieran's dotfiles](https://github.com/kieran-ohara/dotfiles/blob/main/config/claude/agents/analyse-use-case-to-data-patterns.md). Thank you for creating and sharing this excellent agent specification.

---

## 📄 License

This repository is open source and available for use. The CLAUDE.md file and agents are designed to be copied and customized for your projects.

---

## ⭐ If This Helped You

If you found CLAUDE.md or the agents valuable, consider:

- Starring this repo on GitHub
- Sharing it with your team
- Contributing improvements back
- Connecting on LinkedIn to share your experience

The more people who adopt these practices, the better the AI-assisted development ecosystem becomes for everyone.
