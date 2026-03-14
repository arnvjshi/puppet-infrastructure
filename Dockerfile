FROM ubuntu:22.04

# Set environment variables
ENV PUPPET_SERVER_VERSION=7.14.0
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update && \
    apt-get install -y wget gnupg2 ca-certificates && \
    wget https://apt.puppet.com/puppet7-release-jammy.deb && \
    dpkg -i puppet7-release-jammy.deb && \
    apt-get update && \
    apt-get install -y puppetserver && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* puppet7-release-jammy.deb

# Configure Puppet Server memory settings (adjust based on your system)
RUN sed -i 's/-Xms2g/-Xms512m/g' /etc/default/puppetserver && \
    sed -i 's/-Xmx2g/-Xmx512m/g' /etc/default/puppetserver

# Create necessary directories
RUN mkdir -p /etc/puppetlabs/puppet/ssl && \
    mkdir -p /opt/puppetlabs/server/data/puppetserver

# Set permissions
RUN chown -R puppet:puppet /etc/puppetlabs && \
    chown -R puppet:puppet /opt/puppetlabs/server/data/puppetserver

# Expose Puppet Server port
EXPOSE 8140

# Copy configuration files
COPY puppet.conf /etc/puppetlabs/puppet/puppet.conf
COPY autosign.conf /etc/puppetlabs/puppet/autosign.conf

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f https://localhost:8140/status/v1/simple --insecure || exit 1

# Start Puppet Server
CMD ["/opt/puppetlabs/bin/puppetserver", "foreground"]
