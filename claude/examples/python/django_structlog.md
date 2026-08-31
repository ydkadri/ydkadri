# Django with Structured Logging

Integrating structlog with Django requires bridging Django's logging configuration with structlog.

## Settings Configuration

```python
# settings.py
import structlog

# Structlog processors
structlog.configure(
    processors=[
        structlog.contextvars.merge_contextvars,
        structlog.stdlib.filter_by_level,
        structlog.stdlib.add_logger_name,
        structlog.stdlib.add_log_level,
        structlog.stdlib.PositionalArgumentsFormatter(),
        structlog.processors.TimeStamper(fmt="iso"),
        structlog.processors.StackInfoRenderer(),
        structlog.processors.format_exc_info,
        structlog.processors.UnicodeDecoder(),
        structlog.stdlib.ProcessorFormatter.wrap_for_formatter,
    ],
    logger_factory=structlog.stdlib.LoggerFactory(),
    wrapper_class=structlog.stdlib.BoundLogger,
    cache_logger_on_first_use=True,
)

# Django logging configuration
LOGGING = {
    "version": 1,
    "disable_existing_loggers": False,
    "formatters": {
        "json": {
            "()": structlog.stdlib.ProcessorFormatter,
            "processor": structlog.processors.JSONRenderer(),
        },
        "console": {
            "()": structlog.stdlib.ProcessorFormatter,
            "processor": structlog.dev.ConsoleRenderer(colors=True),
        },
    },
    "handlers": {
        "console": {
            "class": "logging.StreamHandler",
            "formatter": "console" if DEBUG else "json",
        },
        "file": {
            "class": "logging.handlers.RotatingFileHandler",
            "filename": "logs/django.log",
            "formatter": "json",
            "maxBytes": 10485760,  # 10MB
            "backupCount": 5,
        },
    },
    "loggers": {
        "django": {
            "handlers": ["console", "file"],
            "level": "INFO",
            "propagate": False,
        },
        "django.request": {
            "handlers": ["console", "file"],
            "level": "INFO",
            "propagate": False,
        },
        "": {
            "handlers": ["console", "file"],
            "level": "INFO",
        },
    },
}
```

## Middleware for Request Context

```python
# middleware.py
import uuid
import structlog
from django.utils.deprecation import MiddlewareMixin

class StructlogMiddleware(MiddlewareMixin):
    def process_request(self, request):
        request_id = str(uuid.uuid4())
        structlog.contextvars.clear_contextvars()
        structlog.contextvars.bind_contextvars(
            request_id=request_id,
            path=request.path,
            method=request.method,
            user_id=request.user.id if request.user.is_authenticated else None,
        )
        request.request_id = request_id
```

## View Usage

```python
# views.py
import structlog
from django.http import JsonResponse

logger = structlog.get_logger(__name__)

def my_view(request):
    logger.info("Processing request")

    try:
        data = process_data(request.GET.get("id"))
        logger.info("Request processed successfully", data_count=len(data))
        return JsonResponse({"data": data})
    except Exception as e:
        logger.error("Request failed", error=str(e), exc_info=True)
        return JsonResponse({"error": str(e)}, status=500)
```

## Model Signals

```python
# models.py
import structlog
from django.db.models.signals import post_save
from django.dispatch import receiver

logger = structlog.get_logger(__name__)

@receiver(post_save, sender=User)
def user_saved(sender, instance, created, **kwargs):
    if created:
        logger.info("User created", user_id=instance.id, username=instance.username)
    else:
        logger.info("User updated", user_id=instance.id)
```

## Management Commands

```python
# management/commands/process_data.py
import structlog
from django.core.management.base import BaseCommand

logger = structlog.get_logger(__name__)

class Command(BaseCommand):
    help = "Process data"

    def handle(self, *args, **options):
        logger.info("Command started")

        try:
            count = process_all_data()
            logger.info("Command completed", records_processed=count)
        except Exception as e:
            logger.error("Command failed", error=str(e), exc_info=True)
            raise
```

## Celery Integration

```python
# celery.py
import structlog
from celery import Celery
from celery.signals import task_prerun, task_postrun

logger = structlog.get_logger(__name__)

app = Celery("myapp")

@task_prerun.connect
def task_prerun_handler(task_id, task, args, kwargs, **extra):
    structlog.contextvars.clear_contextvars()
    structlog.contextvars.bind_contextvars(
        task_id=task_id,
        task_name=task.name,
    )
    logger.info("Task started")

@task_postrun.connect
def task_postrun_handler(task_id, task, args, kwargs, retval, **extra):
    logger.info("Task completed")
    structlog.contextvars.clear_contextvars()
```

## Testing with Structured Logs

```python
# tests.py
import structlog
from django.test import TestCase
from structlog.testing import LogCapture

class MyViewTests(TestCase):
    def test_view_logs(self):
        with LogCapture() as cap:
            response = self.client.get("/my-view/")

        assert any(
            log["event"] == "Processing request"
            for log in cap.entries
        )
```
