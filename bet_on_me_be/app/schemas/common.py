import math
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


def paginated_response(items: list, total: int, page: int, page_size: int) -> dict:
    pages = math.ceil(total / page_size) if page_size else 1
    return {
        "success": True,
        "data": {"items": items, "total": total, "page": page, "page_size": page_size, "pages": pages},
        "error": None,
    }


def error_response(code: str, message: str) -> dict:
    return {"success": False, "data": None, "error": {"code": code, "message": message}}
