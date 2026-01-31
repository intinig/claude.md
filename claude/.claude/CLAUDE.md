# Development Guidelines for Claude

## Language Mode

**Auto-detection** at session start:
- `Cargo.toml` present → **Rust mode** (load: rust-strict, rust-testing, rust-error-handling, rust-concurrency)
- `go.mod` present → **Go mode** (load: go-strict, go-testing, go-error-handling, go-concurrency)
- `package.json` or `tsconfig.json` present → **TypeScript mode** (load: typescript-strict, react-testing, front-end-testing)
- `*.csproj` or `*.sln` present (without Unity) → **C# mode** (load: csharp-strict, csharp-testing, csharp-error-handling, csharp-concurrency)
- `Assets/` folder with `ProjectSettings/` or `*.unity` files → **Unity mode** (load: unity-strict, unity-testing, unity-patterns, unity-performance + all C# skills)
- `composer.json` present → **PHP mode** (load: php-strict, php-testing, php-error-handling)
- None found → **Ask user**: "What language is this project using? (Rust / Go / TypeScript / C# / Unity / PHP)"

Language mode determines which skills are automatically relevant and which enforcer agent to use.

## Shell Configuration

**MANDATORY: Use the correct shell for your platform.**

| Platform | Shell | Command |
|----------|-------|---------|
| **Windows** | PowerShell (pwsh) | `pwsh -Command "..."` |
| **macOS/Linux** | Bash | `bash -c "..."` |

**Windows users:** Always use PowerShell (`pwsh.exe`), never bash or cmd. All shell commands in this framework assume PowerShell on Windows.

## Core Philosophy

**TEST-DRIVEN DEVELOPMENT IS NON-NEGOTIABLE.** Every single line of production code must be written in response to a failing test. No exceptions. This is not a suggestion or a preference - it is the fundamental practice that enables all other principles in this document.

I follow Test-Driven Development (TDD) with a strong emphasis on behavior-driven testing and functional programming principles. All work should be done in small, incremental changes that maintain a working state throughout development.

## Quick Reference

**Universal Principles (All Languages):**

- Write tests first (TDD non-negotiable)
- Test behavior, not implementation
- Immutable data patterns
- Small, pure functions
- Use real schemas/types in tests, never redefine them

**TypeScript Mode:**
- No `any` types - use `unknown` if type truly unknown
- No type assertions without justification
- Schema-first at trust boundaries (Zod)
- `type` for data, `interface` for behavior contracts
- Tools: Jest/Vitest + React Testing Library

**Go Mode:**
- No ignored errors (never `_, _ := ...` for error)
- Context as first parameter, never in structs
- Small interfaces, defined at consumer
- Errors wrapped with context (`fmt.Errorf("%w", err)`)
- Tools: Go 1.21+, testing package, testify/assert

**Rust Mode:**
- No unwrap()/expect() in production - use Result and ? operator
- Prefer borrowing over cloning
- Small traits, defined at consumer
- Errors wrapped with context (thiserror/anyhow)
- Tools: cargo clippy, cargo fmt, cargo test

**C# Mode:**
- Nullable reference types enabled (`#nullable enable`)
- No `null` returns where non-nullable declared
- Records for DTOs, classes for services
- Constructor injection only (no property injection)
- Async all the way with CancellationToken
- Tools: dotnet build, dotnet test, dotnet format

**Unity Mode:**
- Cache component references in Awake (never GetComponent in Update)
- Never `new MonoBehaviour()` - use AddComponent or prefabs
- Clean up events in OnDisable/OnDestroy
- No string-based methods (SendMessage, Invoke by string)
- Use `[SerializeField]` for inspector fields (not public)
- Tools: Unity Test Framework (Edit Mode + Play Mode)

**PHP Mode:**
- `declare(strict_types=1)` at file top
- Type declarations on all parameters and returns
- Property types, constructor property promotion
- Constructor injection only (no service locator)
- Small interfaces (1-3 methods), defined at consumer
- Laravel: No Facades in services, Form Requests for validation
- Tools: PHPUnit, PHPStan, PHP-CS-Fixer

## Testing Principles

**Core principle**: Test behavior, not implementation. 100% coverage through business behavior.

**Quick reference:**
- Write tests first (TDD non-negotiable)
- Test through public API exclusively
- Use factory functions for test data (no `let`/`beforeEach`)
- Tests must document expected business behavior
- No 1:1 mapping between test files and implementation files

For detailed testing patterns and examples, load the `testing` skill.
For verifying test effectiveness through mutation analysis, load the `mutation-testing` skill.

## TypeScript Guidelines

**Core principle**: Strict mode always. Schema-first at trust boundaries, types for internal logic.

**Quick reference:**
- No `any` types - ever (use `unknown` if type truly unknown)
- No type assertions without justification
- Prefer `type` over `interface` for data structures
- Reserve `interface` for behavior contracts only
- Define schemas first, derive types from them (Zod/Standard Schema)
- Use schemas at trust boundaries, plain types for internal logic

For detailed TypeScript patterns and rationale, load the `typescript-strict` skill.

## Go Guidelines

**Core principle**: Explicit error handling. Small interfaces. Context propagation.

**Quick reference:**
- Always handle errors (never `_, _ := ...` to ignore)
- Wrap errors with context: `fmt.Errorf("operation failed: %w", err)`
- Context is always first parameter, never stored in structs
- Small interfaces (1-3 methods), defined at consumer not provider
- No `Get` prefix on getters (`user.Name()` not `user.GetName()`)
- Constructor functions: `NewService(deps) *Service`

For detailed Go patterns, load the `go-strict` skill.
For error handling patterns, load the `go-error-handling` skill.
For concurrency patterns, load the `go-concurrency` skill.

## Rust Guidelines

**Core principle**: Ownership-driven design. Explicit error handling. Fearless concurrency.

**Quick reference:**
- No unwrap()/expect() in production code
- Use ? operator for error propagation
- Prefer borrowing (&T, &mut T) over cloning
- Small traits (1-3 methods), defined at consumer not provider
- Context on errors: `.context("operation failed")?`
- Builder pattern for complex struct construction

For detailed Rust patterns, load the `rust-strict` skill.
For error handling patterns, load the `rust-error-handling` skill.
For concurrency patterns, load the `rust-concurrency` skill.

## C# Guidelines

**Core principle**: Nullable safety. Async all the way. Constructor injection.

**Quick reference:**
- `#nullable enable` in all files (or project-level)
- No `null` returns for non-nullable types
- Records for DTOs and value objects
- Constructor injection only (no [Inject], no service locator)
- Async methods return Task/Task<T>, not void
- CancellationToken on all public async methods
- No `.Result`, `.Wait()`, or `.GetAwaiter().GetResult()`

For detailed C# patterns, load the `csharp-strict` skill.
For error handling patterns, load the `csharp-error-handling` skill.
For concurrency patterns, load the `csharp-concurrency` skill.
For testing patterns, load the `csharp-testing` skill.

## Unity Guidelines

**Core principle**: Cache references. Pool objects. Clean up events. Avoid string APIs.

**Quick reference:**
- Cache GetComponent results in Awake (never in Update)
- Never `new MonoBehaviour()` - use AddComponent or Instantiate
- Subscribe in OnEnable, unsubscribe in OnDisable
- No SendMessage, BroadcastMessage, or string Invoke
- Use `[SerializeField] private` not public for inspector
- Physics code in FixedUpdate, input in Update
- Use object pooling for frequently spawned objects

For detailed Unity patterns, load the `unity-strict` skill.
For architecture patterns, load the `unity-patterns` skill.
For performance optimization, load the `unity-performance` skill.
For testing patterns, load the `unity-testing` skill.

## PHP Guidelines

**Core principle**: Strict types. Type declarations everywhere. Constructor injection.

**Quick reference:**
- `declare(strict_types=1)` at file top
- Type declarations on all parameters and returns
- Property types (PHP 7.4+), readonly properties (PHP 8.1+)
- Constructor property promotion for DI
- Small interfaces (1-3 methods), defined at consumer
- Enums instead of string constants (PHP 8.1+)
- Laravel: No Facades in domain/service code
- Laravel: Form Requests for validation
- Laravel: No `env()` outside config files

For detailed PHP patterns, load the `php-strict` skill.
For error handling patterns, load the `php-error-handling` skill.
For testing patterns, load the `php-testing` skill.

## Code Style

**Core principle**: Functional programming with immutable data. Self-documenting code.

**Quick reference:**
- No data mutation - immutable data structures only
- Pure functions wherever possible
- No nested if/else - use early returns or composition
- No comments - code should be self-documenting
- Prefer options objects over positional parameters
- Use array methods (`map`, `filter`, `reduce`) over loops

For detailed patterns and examples, load the `functional` skill.

## Development Workflow

**Core principle**: RED-GREEN-REFACTOR in small, known-good increments. TDD is the fundamental practice.

**Quick reference:**
- RED: Write failing test first (NO production code without failing test)
- GREEN: Write MINIMUM code to pass test
- REFACTOR: Assess improvement opportunities (only refactor if adds value)
- **Wait for commit approval** before every commit
- Each increment leaves codebase in working state
- Capture learnings as they occur, merge at end

For detailed TDD workflow, load the `tdd` skill.
For refactoring methodology, load the `refactoring` skill.
For significant work, load the `planning` skill for three-document model (PLAN.md, WIP.md, LEARNINGS.md).

## Working with Claude

**Core principle**: Think deeply, follow TDD strictly, capture learnings while context is fresh.

**Quick reference:**
- ALWAYS FOLLOW TDD - no production code without failing test
- Assess refactoring after every green (but only if adds value)
- Update CLAUDE.md when introducing meaningful changes
- Ask "What do I wish I'd known at the start?" after significant changes
- Document gotchas, patterns, decisions, edge cases while context is fresh

For detailed TDD workflow, load the `tdd` skill.
For refactoring methodology, load the `refactoring` skill.
For detailed guidance on expectations and documentation, load the `expectations` skill.

## Resources and References

**TypeScript:**
- [TypeScript Handbook](https://www.typescriptlang.org/docs/handbook/intro.html)
- [Testing Library Principles](https://testing-library.com/docs/guiding-principles)
- [Kent C. Dodds Testing JavaScript](https://testingjavascript.com/)
- [Functional Programming in TypeScript](https://gcanti.github.io/fp-ts/)

**Go:**
- [Effective Go](https://go.dev/doc/effective_go)
- [Go Code Review Comments](https://github.com/golang/go/wiki/CodeReviewComments)
- [Standard Go Project Layout](https://github.com/golang-standards/project-layout)
- [Go Proverbs](https://go-proverbs.github.io/)

**Rust:**
- [The Rust Book](https://doc.rust-lang.org/book/)
- [Rust By Example](https://doc.rust-lang.org/rust-by-example/)
- [Rust API Guidelines](https://rust-lang.github.io/api-guidelines/)
- [Rustonomicon](https://doc.rust-lang.org/nomicon/)

**C#:**
- [C# Language Reference](https://learn.microsoft.com/en-us/dotnet/csharp/)
- [.NET Design Guidelines](https://learn.microsoft.com/en-us/dotnet/standard/design-guidelines/)
- [Nullable Reference Types](https://learn.microsoft.com/en-us/dotnet/csharp/nullable-references)
- [Async/Await Best Practices](https://learn.microsoft.com/en-us/dotnet/csharp/asynchronous-programming/)

**Unity:**
- [Unity Manual](https://docs.unity3d.com/Manual/)
- [Script Execution Order](https://docs.unity3d.com/Manual/ExecutionOrder.html)
- [ScriptableObject Architecture](https://unity.com/how-to/architect-game-code-scriptable-objects)
- [Unity Performance Best Practices](https://docs.unity3d.com/Manual/BestPracticeGuides.html)

**PHP:**
- [PHP Manual](https://www.php.net/manual/)
- [PHP The Right Way](https://phptherightway.com/)
- [PSR Standards](https://www.php-fig.org/psr/)
- [Laravel Documentation](https://laravel.com/docs)

## Summary

The key is to write clean, testable, functional code that evolves through small, safe increments. Every change should be driven by a test that describes the desired behavior, and the implementation should be the simplest thing that makes that test pass. When in doubt, favor simplicity and readability over cleverness.
