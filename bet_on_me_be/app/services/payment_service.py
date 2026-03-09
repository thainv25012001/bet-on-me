from sqlalchemy.ext.asyncio import AsyncSession
from app.repositories.payment_repository import PaymentRepository
from app.schemas.payment import PaymentCreate
from app.models.payment import Payment
from app.models.user import User


class PaymentService:
    def __init__(self, db: AsyncSession) -> None:
        self.repo = PaymentRepository(db)

    async def list_payments(self, user: User) -> list[Payment]:
        return await self.repo.get_by_user(user.id)

    async def create_payment(self, user: User, data: PaymentCreate) -> Payment:
        return await self.repo.create(user_id=user.id, **data.model_dump())
