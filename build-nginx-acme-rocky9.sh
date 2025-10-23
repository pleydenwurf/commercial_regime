#!/bin/bash
# build-nginx-acme-rocky9.sh

set -e

export ROCKY_VERSION="9"
export ARTIFACTORY_URL="https://your-artifactory.company.com"
export PIP_INDEX_URL="${ARTIFACTORY_URL}/artifactory/api/pypi/pypi/simple"

# Install minimal dependencies - no certbot!
dnf install -y python3 python3-pip python3-devel gcc openssl-devel libffi-devel
dnf groupinstall -y "Development Tools"

# Build nginx-acme as standalone ACME client
cd /workspace
pip3 install --index-url $PIP_INDEX_URL --trusted-host your-artifactory.company.com -r requirements.txt

# Common nginx-acme dependencies (not certbot)
pip3 install --index-url $PIP_INDEX_URL \
    cryptography \
    requests \
    josepy \
    acme

python3 setup.py build
python3 setup.py install --prefix=/opt/nginx-acme

echo "nginx-acme built successfully as standalone ACME client"