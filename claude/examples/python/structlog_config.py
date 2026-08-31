"""
Example structlog configuration.

Provides:
- Human-readable colorized stdout (development)
- JSON file logs (production)
- Context binding with contextvars
- Automatic scrubbing of sensitive fields
"""

import logging
import sys
from typing import Any

import structlog
from structlog.typing import EventDict, Processor


# Sensitive field names to scrub from logs
SENSITIVE_FIELDS = {
    "password",
    "token",
    "api_key",
    "secret",
    "authorization",
    "credentials",
}


def scrub_sensitive_data(
    logger: logging.Logger, method_name: str, event_dict: EventDict
) -> EventDict:
    """Remove sensitive data from logs."""
    for key in list(event_dict.keys()):
        if key.lower() in SENSITIVE_FIELDS:
            event_dict[key] = "[REDACTED]"
    return event_dict


def configure_logging(
    level: str = "INFO",
    json_logs: bool = False,
    log_file: str | None = None,
) -> None:
    """
    Configure structlog for the application.

    Args:
        level: Log level (DEBUG, INFO, WARNING, ERROR, CRITICAL)
        json_logs: If True, output JSON format. If False, human-readable.
        log_file: Optional path to log file (always JSON format)
    """
    # Shared processors for both stdout and file
    shared_processors: list[Processor] = [
        structlog.contextvars.merge_contextvars,
        structlog.stdlib.add_log_level,
        structlog.stdlib.add_logger_name,
        structlog.processors.TimeStamper(fmt="iso", utc=True),
        structlog.processors.StackInfoRenderer(),
        scrub_sensitive_data,
    ]

    # Console output processors
    if json_logs:
        console_processors = shared_processors + [
            structlog.processors.format_exc_info,
            structlog.processors.JSONRenderer(),
        ]
    else:
        console_processors = shared_processors + [
            structlog.dev.set_exc_info,
            structlog.dev.ConsoleRenderer(colors=True),
        ]

    # Configure stdlib logging
    logging.basicConfig(
        format="%(message)s",
        stream=sys.stdout,
        level=level,
    )

    # Add file handler if specified
    if log_file:
        file_handler = logging.FileHandler(log_file)
        file_handler.setLevel(level)
        logging.root.addHandler(file_handler)

    # Configure structlog
    structlog.configure(
        processors=console_processors,
        wrapper_class=structlog.stdlib.BoundLogger,
        context_class=dict,
        logger_factory=structlog.stdlib.LoggerFactory(),
        cache_logger_on_first_use=True,
    )


# Usage examples
def example_usage() -> None:
    """Demonstrate logging patterns."""
    # Get logger
    log = structlog.get_logger()

    # Bind context that persists across calls
    log = log.bind(request_id="req-123", user_id="user-456")

    # INFO: Job/process milestones
    log.info("job_started", job_type="data_processing", total_files=100)

    # DEBUG: Detailed flow
    log.debug("function_entered", function="process_file", file_id=1)
    log.debug("condition_evaluated", condition="file_exists", result=True)

    # WARNING: Unexpected but handled
    log.warning(
        "retry_attempted",
        attempt=2,
        max_attempts=3,
        reason="connection_timeout",
    )

    # ERROR: Task failed, but process continues
    log.error(
        "file_processing_failed",
        file_id=42,
        error_type="InvalidFormat",
        error_msg="Missing required header",
    )

    # CRITICAL: System failure, cannot continue
    log.critical(
        "database_unavailable",
        db_host="postgres.example.com",
        error="Connection refused",
    )

    # Performance: Function timing (DEBUG level)
    import time

    start = time.time()
    time.sleep(0.1)
    duration_ms = (time.time() - start) * 1000
    log.debug("query_completed", query_type="select", duration_ms=duration_ms)

    # Performance: Slow operation warning
    SLOW_THRESHOLD_MS = 1000
    if duration_ms > SLOW_THRESHOLD_MS:
        log.warning(
            "slow_operation",
            operation="query",
            duration_ms=duration_ms,
            threshold_ms=SLOW_THRESHOLD_MS,
        )

    # Aggregate metrics at completion (INFO level)
    log.info(
        "job_completed",
        job_type="data_processing",
        total_files=100,
        successful=95,
        failed=5,
        duration_seconds=45.3,
        status="partial_success",
    )

    # Exception logging - always include full traceback
    try:
        raise ValueError("Example error")
    except Exception:
        log.error(
            "operation_failed",
            operation="example",
            exc_info=True,  # Includes full traceback
        )

    # Sensitive data scrubbing demonstration
    log.info(
        "user_authenticated",
        user_id="user-789",
        password="secret123",  # Will be [REDACTED]
        api_key="sk-abc123",  # Will be [REDACTED]
    )


if __name__ == "__main__":
    # Development: colorized console output, DEBUG level
    configure_logging(level="DEBUG", json_logs=False)

    # Production: JSON logs, INFO level, write to file
    # configure_logging(level="INFO", json_logs=True, log_file="app.log")

    example_usage()
