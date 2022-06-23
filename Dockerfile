FROM postgres:13

# Generated SSL certificates will be placed inside $CERTS_ROOT/certs
ENV CERTS_ROOT /var/lib/postgresql/data/

ADD ./createCerts.sh ${CERTS_ROOT}

# Run the script to generate SSL certs on the fly
RUN /bin/bash -c "$CERTS_ROOT/createCerts.sh"

# Take the ownership for dirs as postgres is running with non-root user
RUN chown -R postgres:postgres /var/lib/postgresql/
