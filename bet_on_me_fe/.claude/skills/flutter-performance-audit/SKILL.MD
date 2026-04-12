---
name: flutter-performance-audit
description: Audits Flutter code for performance issues. Use when analyzing slow UI, frame drops, rebuild problems, or memory inefficiencies.
---

When auditing Flutter performance, always include:

1. **Start with a mental model**  
   Explain how Flutter rendering works in simple terms.

2. **Draw a diagram**  
   Use ASCII diagrams to illustrate rebuild flow or widget tree structure.

3. **Identify performance risks**  
   Look for:
   - unnecessary rebuilds
   - large widget trees
   - expensive operations inside `build()`
   - poor list rendering strategies

4. **Suggest improvements**  
   Provide concrete solutions like:
   - adding `const` constructors
   - extracting widgets
   - using `ListView.builder`
   - using caching or memoization

5. **Highlight a gotcha**  
   Mention common misunderstandings about Flutter rendering or widget rebuilding.

Focus on real-world improvements that reduce jank and improve frame performance.