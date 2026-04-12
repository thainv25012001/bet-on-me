---
name: flutter-architecture
description: Guides developers in structuring Flutter applications using clean architecture and feature-based organization.
---

When explaining or improving Flutter architecture, always include:

1. **Start with an analogy**  
   Compare the architecture to organizing departments in a company.

2. **Draw the architecture diagram**  
   Use ASCII diagrams to illustrate layers like presentation, domain, and data.

3. **Explain each layer**  
   Walk through what responsibilities belong to each layer.

4. **Show example folder structure**

Example:

lib/
  features/
    goal/
      presentation/
      domain/
      data/

5. **Highlight a gotcha**  
   Explain common architecture mistakes like placing business logic inside UI widgets.

Keep explanations practical and suitable for real production apps.