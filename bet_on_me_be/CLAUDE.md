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

# API docs
open http://localhost:8000/docs
```

## Architecture

Strict layered architecture: **Router → Service → Repository → Model**

- **Routers** (`app/api/v1/routers/`) — thin HTTP handlers; instantiate the service, call one method, return `success_response(...)`.
- **Services** (`app/services/`) — all business logic and ownership authorization. Services hold one primary repo and additional repos as needed for cross-entity ownership checks (see `checkin_service.py` walking Task → Plan → Goal to verify ownership).
- **Repositories** (`app/repositories/`) — all inherit `BaseRepository` which provides `get`, `get_all`, `create`, `update`, `delete`. Domain repos add query methods (e.g. `get_by_user`, `get_by_goal`).
- **Models** (`app/models/`) — all inherit `UUIDBase` (UUID pk + `created_at`). No `updated_at` on the base — add it per model if needed.
- **Schemas** (`app/schemas/`) — Pydantic DTOs; `model_config = {"from_attributes": True}` required on `Out` schemas for ORM serialization.

## Data Model

```
User
└── Goal (user_id, title, start_date, target_date, stake_per_day, status)
    ├── Plan (goal_id, total_days, generated_by="ai")
    │   └── Task (plan_id, day_number, title, description, estimated_minutes)
    │       └── Checkin (task_id, user_id, ...)
    └── Stake (goal_id, user_id, ...)
User
└── Payment (wallet transactions)
```

`POST /goals` triggers an OpenAI API call (`gpt-4o-mini`) that generates the full task list atomically within one DB transaction (flush → AI call → commit).

## API Conventions

All responses use the standard envelope from `app/schemas/common.py`:
```json
{ "success": true, "data": {...}, "error": null }
```

Custom exceptions (`NotFound`, `Forbidden`, `Unauthorized`, `BadRequest`, `Conflict`) in `app/utils/exceptions.py` are raised in the service layer and caught by global handlers in `main.py`.

Authorization (ownership) is **always enforced in the service layer**, never in routers.

All protected endpoints use: `current_user: User = Depends(get_current_user)`

## Environment

Copy `.env.example` to `.env`. Required variables:
- `DATABASE_URL` — asyncpg PostgreSQL URL (`postgresql+asyncpg://...`)
- `SECRET_KEY` — JWT signing key
- `OPENAI_API_KEY` — OpenAI API key from platform.openai.com
- `ACCESS_TOKEN_EXPIRE_MINUTES` — defaults to 30
- `ALGORITHM` — defaults to HS256

## Key Patterns

**Multi-entity transaction** (see `goal_service.py::create_goal`): use `db.flush()` to get IDs mid-transaction without committing, then commit once at the end. Wrap in try/except with `db.rollback()`.

**Cross-entity ownership check**: services instantiate additional repos (e.g. `GoalRepository`) to walk the FK chain and verify the resource belongs to the requesting user before proceeding.

**`BaseRepository.create()`** commits immediately — avoid it inside multi-step transactions; build the model manually and `db.add()` it instead.
