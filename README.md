

Tricks:
# Restart DB from scratch:
```shell
make down
rm -rf pgdata
make up
```

# Makemigrations:
```shell
make ARGS="makemigrations" django_manage
```

# Create-superuser:
```shell
make ARGS="createsuperuser" django_manage
```
