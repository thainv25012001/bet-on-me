from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    DATABASE_URL: str
    SECRET_KEY: str
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 360  # 6 hours
    ALGORITHM: str = "HS256"
    OPENAI_API_KEY: str

    # Kafka
    KAFKA_BOOTSTRAP_SERVERS: str = "localhost:29092"
    KAFKA_GOAL_TOPIC: str = "goal_creation"

    class Config:
        env_file = ".env"


settings = Settings()
