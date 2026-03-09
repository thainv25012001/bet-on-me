---
name: fastapi-service-layer
description: Defines service layer for business logic separation
---

# Service Layer

Services implement business logic.

Example:

class UserService:

    def __init__(self, repo: UserRepository):
        self.repo = repo

    def get_user_profile(self, user_id: int):

        user = self.repo.get_user(user_id)

        if not user:
            raise UserNotFound()

        return user