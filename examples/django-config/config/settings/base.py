import sys
from datetime import timedelta
from pathlib import Path

import environ
from django.core.management.utils import get_random_secret_key

env = environ.Env(
    DEBUG=(bool, False),
)

BASE_DIR = Path(__file__).resolve().parent.parent

sys.path.append(str(BASE_DIR.parent.parent))

environ.Env.read_env(BASE_DIR / ".env")

SECRET_KEY = env.str("SECRET_KEY", default=get_random_secret_key())

INSTALLED_APPS = [
    "django.contrib.admin",
    "django.contrib.auth",
    "django.contrib.contenttypes",
    "django.contrib.sessions",
    "django.contrib.messages",
    "django.contrib.staticfiles",
    "corsheaders",
    "health_check",
    "health_check.db",
    "health_check.cache",
    "health_check.storage",
    "health_check.contrib.celery",  # requires celery
    "rest_framework",
    "rest_framework_simplejwt",
    "oauth2_provider",
    "django_celery_results",
]


MIDDLEWARE = [
    "django.middleware.security.SecurityMiddleware",
    "corsheaders.middleware.CorsMiddleware",
    "django.contrib.sessions.middleware.SessionMiddleware",
    "django.middleware.common.CommonMiddleware",
    "django.middleware.csrf.CsrfViewMiddleware",
    "django.contrib.auth.middleware.AuthenticationMiddleware",
    "django.contrib.messages.middleware.MessageMiddleware",
    "django.middleware.clickjacking.XFrameOptionsMiddleware",
]

CORS_ALLOW_CREDENTIALS = True

# import urllib

# sqlalchemy_connection_string = f"sqla+postgresql://{env.db()['USER']}:{urllib.parse.quote_plus(env.db()['PASSWORD'])}@{env.db()['HOST']}/{env.db()['NAME']}"
# CELERY_RESULT_BACKEND = "django-db"
# CELERY_BROKER_URL = sqlalchemy_connection_string
# CELERY_ACCEPT_CONTENT = ["json"]
# CELERY_TASK_SERIALIZER = "json"
# CELERY_RESULT_SERIALIZER = "json"
# CELERY_TIMEZONE = "UTC"

# CELERY_RESULT_EXTENDED = True

STATIC_ROOT = BASE_DIR / "staticfiles"
# STATICFILES_STORAGE = "whitenoise.storage.CompressedManifestStaticFilesStorage"
# DEFAULT_FILE_STORAGE = "storages.backends.s3.S3Storage"

ROOT_URLCONF = "config.urls"

TEMPLATES = [
    {
        "BACKEND": "django.template.backends.django.DjangoTemplates",
        "DIRS": [],
        "APP_DIRS": True,
        "OPTIONS": {
            "context_processors": [
                "django.template.context_processors.debug",
                "django.template.context_processors.request",
                "django.contrib.auth.context_processors.auth",
                "django.contrib.messages.context_processors.messages",
            ],
        },
    },
]

REST_FRAMEWORK = {
    "DEFAULT_PAGINATION_CLASS": "rest_framework.pagination.PageNumberPagination",
    "PAGE_SIZE": 100,
    "DEFAULT_AUTHENTICATION_CLASSES": ("rest_framework_simplejwt.authentication.JWTAuthentication",),
    # 'DEFAULT_AUTHENTICATION_CLASSES': (
    #     'oauth2_provider.contrib.rest_framework.OAuth2Authentication',
    # )
    # 'DEFAULT_SCHEMA_CLASS': 'drf_spectacular.openapi.AutoSchema',
}

SIMPLE_JWT = {
    "ACCESS_TOKEN_LIFETIME": timedelta(minutes=60),
    "SLIDING_TOKEN_REFRESH_LIFETIME": timedelta(days=1),
    "ROTATE_REFRESH_TOKENS": False,
    "ALGORITHM": "HS256",
    "SIGNING_KEY": SECRET_KEY,
    "VERIFYING_KEY": None,
    "AUTH_HEADER_TYPES": ("Bearer",),
    "USER_ID_FIELD": "id",
    "USER_ID_CLAIM": "user_id",
    "AUTH_TOKEN_CLASSES": ("rest_framework_simplejwt.tokens.AccessToken",),
    "TOKEN_TYPE_CLAIM": "token_type",
}

WSGI_APPLICATION = "config.wsgi.application"
DATABASES = {"default": env.db()}

AUTH_PASSWORD_VALIDATORS = [
    {
        "NAME": "django.contrib.auth.password_validation.UserAttributeSimilarityValidator",
    },
    {
        "NAME": "django.contrib.auth.password_validation.MinimumLengthValidator",
    },
    {
        "NAME": "django.contrib.auth.password_validation.CommonPasswordValidator",
    },
    {
        "NAME": "django.contrib.auth.password_validation.NumericPasswordValidator",
    },
]

LANGUAGE_CODE = "en-us"

TIME_ZONE = "UTC"

USE_I18N = True

USE_TZ = True

DEFAULT_AUTO_FIELD = "django.db.models.BigAutoField"

LOGIN_URL = "/admin/login/"

STORAGE_OPTIONS = {
    "access_key": env("AWS_S3_ACCESS_KEY_ID", default="root"),
    "secret_key": env("AWS_S3_SECRET_ACCESS_KEY", default="password"),
    "security_token": env("AWS_SECURITY_TOKEN", default=""),
    "region_name": env("AWS_S3_REGION_NAME", default="us-east-1"),
    "signature_version": env("AWS_S3_SIGNATURE_VERSION", default="s3v4"),
    "url_protocol": "http:",
    # https://docs.aws.amazon.com/AmazonS3/latest/userguide/acl-overview.html#canned-acl
    "default_acl": env("AWS_DEFAULT_ACL", default="public-read"),
    "endpoint_url": "http://minio:9000",  # env("AWS_S3_ENDPOINT_URL", default="s3.amazonaws.com"),
    "verify": False,
    "session_profile": False,
}

STORAGES = {
    "default": {
        "BACKEND": "storages.backends.s3.S3Storage",
        "OPTIONS": {
            **STORAGE_OPTIONS,
            "bucket_name": env("AWS_S3_BUCKET_UPLOADS_NAME", default="uploads"),
            "location": "uploads/",
            "custom_domain": "localhost:9000/uploads",
        },
    },
    "staticfiles": {
        "BACKEND": "storages.backends.s3.S3StaticStorage",
        "OPTIONS": {
            **STORAGE_OPTIONS,
            "bucket_name": env("AWS_S3_BUCKET_STATIC_NAME", default="static"),
            "location": "static/",
            "custom_domain": "localhost:9000/static",
        },
    },
}
