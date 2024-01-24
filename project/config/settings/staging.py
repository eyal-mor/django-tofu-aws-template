import os

import requests
from config.settings.base import *  # fmt: skip

DEBUG = False

ALLOWED_HOSTS = ["0.0.0.0", "localhost", "127.0.0.1"]

try:
    aws_token = requests.put(
        "http://169.254.169.254/latest/api/token",
        headers={"X-aws-ec2-metadata-token-ttl-seconds": "21600"},
    ).content.decode("utf-8")
    local_ip = requests.get(
        "http://169.254.169.254/latest/meta-data/local-ipv4",
        headers={"X-aws-ec2-metadata-token": aws_token},
    ).content.decode("utf-8")
    ALLOWED_HOSTS.append(local_ip)
    print("Set local IP to {}".format(local_ip))
except Exception as e:
    print(e)
    print("Failed to set local IP")

AWS_ENDPOINT_URL = os.environ.setdefault("AWS_ENDPOINT_URL", "https://s3.us-east-1.amazonaws.com")

LOGGING = {
    "version": 1,
    "disable_existing_loggers": False,
    "handlers": {
        "console": {
            "class": "logging.StreamHandler",
        },
    },
    "root": {
        "handlers": ["console"],
        "level": "DEBUG",
    },
    "loggers": {
        "django": {
            "handlers": ["console"],
            "level": "DEBUG",
            "propagate": False,
        },
        "asyncio": {
            "level": "WARNING",
        },
    },
}
