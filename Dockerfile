FROM matrixdotorg/synapse:v1.36.0

# Install shared_secret_auth, which can be enabled if desired
RUN apt-get update && \
    apt-get install -y git && \
    apt-get clean autoclean && \
    rm -rf /var/lib/apt/* /var/lib/cache/* /var/lib/log/*
RUN pip install git+https://github.com/devture/matrix-synapse-shared-secret-auth
# To enable shared secret auth, set the following:
# CONFIG_password_providers.0.module=shared_secret_authenticator.SharedSecretAuthenticator
# CONFIG_password_providers.0.config.sharedSecret=

RUN mkdir -p /data /config
RUN SYNAPSE_SERVER_NAME=my.matrix.host SYNAPSE_REPORT_STATS=no /start.py generate && \
    mv /data/homeserver.yaml /config/homeserver.template.yaml
# Couldn't find a way to auto-generate the container flavor of this config, so just copy it in.
COPY ./log.template.config /config/log.template.config

COPY --from=johnstarich/env2config:v0.1.2 /env2config /
ENV E2C_CONFIGS=config,log

ENV LOG_OPTS_FILE=/config/log.config
ENV LOG_OPTS_FORMAT=yaml
ENV LOG_OPTS_TEMPLATE_FILE=/config/log.template.config

ENV SYNAPSE_CONFIG_PATH=/config/homeserver.yaml
ENV CONFIG_OPTS_FILE=/config/homeserver.yaml
ENV CONFIG_OPTS_FORMAT=yaml
ENV CONFIG_OPTS_TEMPLATE_FILE=/config/homeserver.template.yaml
ENV CONFIG_OPTS_IN_server_name=SERVER_NAME
# Set postgres DB as default, require setup params
ENV CONFIG_database.name=psycopg2
ENV CONFIG_OPTS_IN_database.args.user=DB_USER
ENV CONFIG_OPTS_IN_database.args.password=DB_PASSWORD
ENV CONFIG_OPTS_IN_database.args.database=DB_NAME
ENV CONFIG_OPTS_IN_database.args.host=DB_HOST
ENV CONFIG_database.args.keepalives_idle=10
ENV CONFIG_database.args.keepalives_interval=10
ENV CONFIG_database.args.keepalives_count=3
# Override defaults that used fake hostname
ENV CONFIG_log_config=/config/log.config
ENV CONFIG_OPTS_IN_signing_key_path=SIGNING_KEY_FILE
# Require each secret. These must be provided to override generated template values.
ENV CONFIG_OPTS_IN_registration_shared_secret=REGISTRATION_SHARED_SECRET
ENV CONFIG_OPTS_IN_macaroon_secret_key=TOKEN_SIGNING_SECRET
ENV CONFIG_OPTS_IN_form_secret=FORM_SECRET

ENTRYPOINT ["/env2config", "/start.py"]
