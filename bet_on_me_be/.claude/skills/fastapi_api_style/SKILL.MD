---
name: fastapi-api-style
description: Defines REST API design standards and response format conventions
---

# API Design

Use RESTful patterns.

GET /users
GET /users/{id}
POST /users
PATCH /users/{id}
DELETE /users/{id}

## Response Format

Success:

{
  "success": true,
  "data": {},
  "error": null
}

Error:

{
  "success": false,
  "error": {
    "code": "ERROR_CODE",
    "message": "Human readable message"
  }
}