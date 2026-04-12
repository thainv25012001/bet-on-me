---
name: flutter-optimize
description: Reviews and optimizes Flutter code for performance, readability, and maintainability. Use when improving Flutter widgets, refactoring code, or reviewing pull requests.
---

When optimizing Flutter code, always include:

1. **Start with a quick diagnosis**  
   Briefly describe what the code is doing and identify potential issues.

2. **Explain the problem**  
   Highlight performance issues such as:
   - unnecessary widget rebuilds
   - missing `const` constructors
   - deeply nested widget trees
   - inefficient list rendering

3. **Show the optimized code**  
   Provide a clean refactored version that follows Flutter best practices.

4. **Explain why the new version is better**  
   Focus on performance improvements, readability, and maintainability.

5. **Highlight a gotcha**  
   Mention common Flutter mistakes like:
   - heavy logic inside `build()`
   - rebuilding large widgets unnecessarily
   - using `ListView` instead of `ListView.builder`.

Keep explanations concise and practical. Always prefer clean, production-ready Flutter patterns.