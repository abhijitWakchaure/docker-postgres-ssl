FROM postgres:13

# Generated SSL certificates will be placed inside $CERTS_ROOT/certs
ENV CERTS_ROOT /var/lib/postgresql/data/

RUN apt-get update && apt-get -y upgrade \
	&& apt-get install -y --no-install-recommends curl python3 \
	&& rm -rf /var/lib/apt/lists/*

ADD ./createCerts.sh ${CERTS_ROOT}
ADD ./docker-entrypoint-custom.sh /
ADD ./initDB.sql /docker-entrypoint-initdb.d/initDB.sql

ADD ./postgresql.conf /etc/postgresql/postgresql.conf
ADD ./pg_hba.conf /etc/postgresql/pg_hba.conf

# Take the ownership for dirs as postgres is running with non-root user
RUN chown -R postgres:postgres /var/lib/postgresql/
RUN chown -R postgres:postgres /etc/postgresql

RUN su postgres

ENTRYPOINT [ "/docker-entrypoint-custom.sh"]