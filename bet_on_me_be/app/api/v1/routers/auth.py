from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from app.db.session import get_db
from app.schemas import LoginRequest, TokenOut
from app.schemas.user import UserCreate
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
