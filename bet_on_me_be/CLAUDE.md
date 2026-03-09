# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Bet on Me is a goal-tracking and financial-stakes commitment app. This repo is the **FastAPI backend**.

## Commands

```bash
# Install dependencies
pip install -r requirements.txt

# Run database migrations
alembic upgrade head

# Create a new migration after model changes
alembic revision --autogenerate -m "description"

# Start dev server
uvicorn app.main:app --reload

# API docs available at http://localhost:8000/docs
```

## Architecture

The app follows a strict layered architecture: **Router → Service → Repository → Model**

```
app/
├── api/v1/routers/     # HTTP handlers — thin, delegate to services
├── services/           # Business logic, authorization checks
├── repositories/       # Data access via SQLAlchemy (all inherit BaseRepository)
├── models/             # SQLAlchemy ORM models
├── schemas/            # Pydantic request/response DTOs
├── core/
│   ├── config.py       # Settings loaded from .env
│   ├── security.py     # JWT creation/verification, password hashing
│   └── dependencies.py # get_current_user dependency for auth
├── db/
│   ├── session.py      # Async SQLAlchemy session factory
│   └── base.py         # Declarative base
└── utils/exceptions.py # Custom exception classes used across layers
```

## Data Model

Users own Goals → Goals have Plans (AI-generated) → Plans have Tasks → Tasks have Checkins.
Goals also have Stakes (financial commitments) and Users have Payments (wallet transactions).

All PKs are UUIDs. All tables have `created_at`/`updated_at` timestamps.

## API Conventions

All endpoints return a standard envelope:
```json
{ "success": true, "data": {...}, "error": null }
```

Use `success_response()` and `error_response()` from `app/schemas/common.py`.

Custom exceptions in `app/utils/exceptions.py` (`NotFound`, `Forbidden`, `Unauthorized`, `BadRequest`, `Conflict`) are caught by global handlers in `main.py` and mapped to HTTP status codes.

All protected endpoints use `current_user: User = Depends(get_current_user)` for JWT auth. Authorization (ownership checks) is enforced in the service layer, not the router.

## Environment

Copy `.env.example` to `.env`. Required variables:
- `DATABASE_URL` — asyncpg PostgreSQL URL (e.g., `postgresql+asyncpg://...`)
- `SECRET_KEY` — JWT signing key
- `ACCESS_TOKEN_EXPIRE_MINUTES` — defaults to 30
- `ALGORITHM` — defaults to HS256
