FROM matrixdotorg/synapse:v1.31.0

RUN mkdir /data
RUN SYNAPSE_SERVER_NAME=my.matrix.host SYNAPSE_REPORT_STATS=no /start.py generate && \
    mv /data/homeserver.yaml /homeserver.template.yaml
# Couldn't find a way to auto-generate the container flavor of this config, so just copy it in.
COPY ./log.template.config /log.template.config

COPY --from=johnstarich/env2config:v0.1.2 /env2config /
ENV E2C_CONFIGS=config,log

ENV LOG_OPTS_FILE=/data/log.config
ENV LOG_OPTS_FORMAT=yaml
ENV LOG_OPTS_TEMPLATE_FILE=/log.template.config

ENV CONFIG_OPTS_FILE=/data/homeserver.yaml
ENV CONFIG_OPTS_FORMAT=yaml
ENV CONFIG_OPTS_TEMPLATE_FILE=/homeserver.template.yaml
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
ENV CONFIG_log_config=/data/log.config
ENV CONFIG_OPTS_IN_signing_key_path=SIGNING_KEY_FILE
# Require each secret. These must be provided to override generated template values.
ENV CONFIG_OPTS_IN_registration_shared_secret=REGISTRATION_SHARED_SECRET
ENV CONFIG_OPTS_IN_macaroon_secret_key=TOKEN_SIGNING_SECRET
ENV CONFIG_OPTS_IN_form_secret=FORM_SECRET

ENTRYPOINT ["/env2config", "/start.py"]
