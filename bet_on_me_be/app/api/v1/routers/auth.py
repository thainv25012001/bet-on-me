from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from app.db.session import get_db
from app.schemas import LoginRequest, TokenOut
from app.schemas.user import UserCreate, ForgotPasswordRequest, ResetPasswordRequest
from app.schemas.common import success_response
from app.services.auth_service import AuthService

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/register")
async def register(data: UserCreate, db: AsyncSession = Depends(get_db)):
    service = AuthService(db)
    token = await service.register(data)
    return success_response(token)


@router.post("/login")
async def login(data: LoginRequest, db: AsyncSession = Depends(get_db)):
    service = AuthService(db)
    token = await service.login(data.email, data.password)
    return success_response(token)


@router.post("/forgot-password")
async def forgot_password(data: ForgotPasswordRequest, db: AsyncSession = Depends(get_db)):
    service = AuthService(db)
    result = await service.forgot_password(data.email)
    return success_response(result)


@router.post("/reset-password")
async def reset_password(data: ResetPasswordRequest, db: AsyncSession = Depends(get_db)):
    service = AuthService(db)
    result = await service.reset_password(data.token, data.new_password)
    return success_response(result)
