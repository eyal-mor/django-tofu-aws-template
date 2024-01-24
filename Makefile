format:
	poetry run autoflake --in-place --remove-all-unused-imports --remove-unused-variables --recursive .
	poetry run isort .
	poetry run black .

build:
	docker build -t {FILL_HERE}-django-base -f docker/Dockerfile.base .
	docker compose build

up: down build
	docker compose up

start:
	docker compose start

down:
	docker compose down --remove-orphans --volumes

stopapp:
	docker compose stop web celery

startapp:
	docker compose start web celery

restart: stopapp startapp

django_manage:
	docker compose run init-web poetry run ./manage.py $(ARGS)

migrate:
	$(MAKE) ARGS=makemigrations django_manage
	$(MAKE) ARGS=migrate django_manage

infra-apply:
	docker compose run init-infra

swagger:
	docker compose exec web poetry run ./manage.py  generateschema --file /app/openapi.yml

psql:
	docker compose exec postgres psql -U postgres -d {FILL_HERE}
