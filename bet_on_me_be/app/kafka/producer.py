import json
import logging
from aiokafka import AIOKafkaProducer
from app.core.config import settings

logger = logging.getLogger(__name__)

_producer: AIOKafkaProducer | None = None


async def start_producer() -> None:
    global _producer
    _producer = AIOKafkaProducer(bootstrap_servers=settings.KAFKA_BOOTSTRAP_SERVERS)
    await _producer.start()
    logger.info("Kafka producer started (brokers=%s)", settings.KAFKA_BOOTSTRAP_SERVERS)


async def stop_producer() -> None:
    global _producer
    if _producer is not None:
        await _producer.stop()
        _producer = None
        logger.info("Kafka producer stopped")


async def send_goal_job(job_id: str, payload: dict) -> None:
    """Publish a goal-creation job to the Kafka topic.

    Uses send_and_wait so produce errors surface immediately on the POST request.
    """
    if _producer is None:
        raise RuntimeError("Kafka producer is not started")
    message = json.dumps({"job_id": job_id, "payload": payload}).encode()
    await _producer.send_and_wait(settings.KAFKA_GOAL_TOPIC, message, key=job_id.encode())
    logger.debug("Published goal job %s to topic %s", job_id, settings.KAFKA_GOAL_TOPIC)
