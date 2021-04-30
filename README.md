# docker-synapse
Wraps the Matrix [Synapse][] container with an [env-based config][e2c].

[Synapse]: https://github.com/matrix-org/synapse
[e2c]: https://github.com/JohnStarich/env2config

## Quick Start

Use the below Docker stack for environment variables, default volume locations, and ports.
Once the `${YOUR_*}` and example.com variables are filled in, deploy with `docker stack deploy matrix --compose-file docker-compose.yml`.

Most of the secret env vars are random strings but some, like the signing key, are a specific format. To generate a signing key file, run:
```bash
docker run --rm -it --entrypoint generate_signing_key.py johnstarich/synapse:1.31.0_20210429 > signing.key
```

**NOTE: All published ports are examples only. Use HTTPS and a proxy instead, like [Traefik][].**

[Traefik]: https://doc.traefik.io/traefik/

```yaml
version: "3.4"

services:
  synapse:
    image: johnstarich/synapse:1.31.0_20210429
    ports:
    - "8008:8008"
    environment:
    # Required:
    - SERVER_NAME=example.com
    - DB_HOST=synapse_db
    - DB_NAME=synapse
    - DB_PASSWORD=${YOUR_DB_PASS}
    - DB_USER=synapse
    - FORM_SECRET=${YOUR_FORM_SECRET}
    - REGISTRATION_SHARED_SECRET=${YOUR_REGISTRATION_SHARED_SECRET}
    - SIGNING_KEY_FILE=/run/secrets/signing_key
    - TOKEN_SIGNING_SECRET=${YOUR_TOKEN_SIGNING_SECRET}
    # Optional. See Synapse docs for more config info: https://github.com/matrix-org/synapse
    #- CONFIG_public_baseurl=https://matrix.example.com/
    #- CONFIG_enable_registration=false
    #- CONFIG_recaptcha_public_key=
    #- CONFIG_recaptcha_private_key=
    #- CONFIG_enable_registration_captcha=true
    #- CONFIG_recaptcha_siteverify_api=
    #- CONFIG_turn_uris.0=turn:turn.example.com?transport=udp
    #- CONFIG_turn_uris.1=turn:turn.example.com?transport=tcp
    #- CONFIG_turn_shared_secret=
    #- CONFIG_media_store_path=/data/media
    #- CONFIG_app_service_config_files.0=/bridge/slack-bridge.yaml
    #
    ## SharedSecretAuthenticator is built-in and can be enabled if you like: https://github.com/devture/matrix-synapse-shared-secret-auth
    #- CONFIG_password_providers.0.module=shared_secret_authenticator.SharedSecretAuthenticator
    #- CONFIG_password_providers.0.config.sharedSecret=
    #
    secrets:
    # Signing key file provided as a Docker secret. Unfortunately not declaratively generated.
    - signing_key
    volumes:
    - synapse:/data
    - bridge:/bridge

  synapse_db:
    image: postgres:12-alpine
    environment:
    - POSTGRES_USER=synapse
    - POSTGRES_PASSWORD=${YOUR_DB_PASS}
    - POSTGRES_DB=synapse
    - POSTGRES_INITDB_ARGS=--encoding=UTF-8 --lc-collate=C --lc-ctype=C
    volumes:
    - synapse_db:/var/lib/postgresql/data

  web:
    image: vectorim/element-web:v1.7.25
    ports:
    - "8081:80"

  web_admin:
    image: awesometechnologies/synapse-admin:0.7.2
    ports:
    - "8080:80"

volumes:
  synapse:
  synapse_db:
  bridge:  # This volume is intended to hold bridge registration files, which are included in synapse's app_service_config_files config

secrets:
  signing_key:
    file: ./signing.key
```
