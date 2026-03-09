---
name: fastapi-database
description: Defines database patterns using PostgreSQL, SQLAlchemy and repository pattern
---

# Database Layer

Use:

- PostgreSQL
- SQLAlchemy 2.0
- Alembic migrations

Structure:

db/
models/
repositories/

Repositories handle all database queries.

Example:

class UserRepository:

    def __init__(self, db: Session):
        self.db = db

    def get_user(self, user_id: int):
        return self.db.query(User).filter(User.id == user_id).first()