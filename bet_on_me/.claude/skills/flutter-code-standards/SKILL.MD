---
name: flutter-code-standards
description: Defines coding standards and best practices for Flutter projects. Use when generating, modifying, or reviewing Flutter code to ensure clean architecture, high performance, and maintainable code.
---

# Flutter Code Standards

When generating or modifying Flutter code, follow these rules.

## Architecture
- Follow Clean Architecture principles
- Separate layers: presentation, domain, data
- Use feature-based folder structure

Example:
lib/
  features/
    auth/
      presentation/
      domain/
      data/

## State Management
Preferred options:
- Riverpod
- Bloc

Avoid:
- setState for complex logic

## UI Guidelines
- Use const constructors whenever possible
- Extract reusable widgets
- Avoid deeply nested widget trees
- Prefer composition over large widgets

## Performance Rules
- Avoid unnecessary rebuilds
- Use const widgets
- Use ListView.builder instead of ListView
- Use RepaintBoundary when needed
- Avoid heavy logic inside build()

## Code Style
- Follow Dart style guide
- Use meaningful variable names
- Functions < 40 lines
- Widgets should be small and reusable

## Async Handling
- Use async/await
- Avoid blocking UI thread
- Use FutureBuilder or StreamBuilder properly

## Error Handling
- Handle exceptions properly
- Avoid silent failures
- Log errors clearly

## Documentation
- Document public classes and methods