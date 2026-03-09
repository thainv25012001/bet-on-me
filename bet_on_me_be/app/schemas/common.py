from typing import Any
from pydantic import BaseModel


class ErrorDetail(BaseModel):
    code: str
    message: str


class ApiResponse(BaseModel):
    success: bool
    data: Any = None
    error: ErrorDetail | None = None


def success_response(data: Any = None) -> dict:
    return {"success": True, "data": data, "error": None}


def error_response(code: str, message: str) -> dict:
    return {"success": False, "data": None, "error": {"code": code, "message": message}}
