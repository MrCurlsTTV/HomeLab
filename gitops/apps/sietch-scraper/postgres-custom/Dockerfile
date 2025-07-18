# Use the official postgres image as a base
FROM postgres:13

ARG PG_UID=2000
ARG PG_GID=2000

# Re-create the postgres user and group with the desired UID/GID
RUN groupmod -o -g ${PG_GID} postgres && \
    usermod -o -u ${PG_UID} postgres

# Create a directory for the container's internal socket and set permissions
RUN mkdir -p /var/run/postgresql && \
    chown -R postgres:postgres /var/run/postgresql 