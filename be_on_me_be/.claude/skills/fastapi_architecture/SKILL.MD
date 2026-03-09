---
name: fastapi-architecture
description: Defines the recommended project architecture and folder structure for FastAPI backend services
---

# FastAPI Architecture Guidelines

## Project Structure

app/
  main.py
  core/
  api/
  models/
  schemas/
  services/
  repositories/
  db/
  utils/

Rules:

- Routers only handle HTTP layer
- Services contain business logic
- Repositories handle database access
- Schemas are Pydantic models
- Models are SQLAlchemy ORM models

Never put database queries in routers.
Never put business logic in routers.