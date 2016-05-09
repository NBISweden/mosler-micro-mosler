#!/usr/bin/env bash

export OS_PROJECT_DOMAIN_ID=default
export OS_USER_DOMAIN_ID=default
export OS_PROJECT_NAME=mmosler1
export OS_TENANT_NAME=mmosler1
export OS_AUTH_URL=http://controller:5000/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2
export OS_ENDPOINT_TYPE=internalURL # User internal URLs
    
if [ -f user.rc ]; then
    source user.rc
else
    echo "Error: User credentials not found [user.rc]"
    exit 1;
fi

#TENANT_ID=$(openstack project list | awk '/'${OS_TENANT_NAME}'/ {print $2}')
TENANT_ID=qsdfqdsf-qsdfqsdf

# Declaring the machines
# Arrays are one-dimensional only. Tyvärr!
declare -a MACHINES
declare -A FLAVORS
declare -A MACHINE_IPs
declare -A DATA_IPs

MACHINES=('openstack-controller' 'thinlinc-master' 'filsluss' 'supernode' 'compute1' 'compute2' 'compute3' 'hnas-emulation' 'ldap' 'networking-node')

FLAVORS=(\
    [openstack-controller]=m1.small \
    [thinlinc-master]=m1.small \
    [filsluss]=m1.small \
    [supernode]=m1.small \
    [compute1]=m1.large \
    [compute2]=m1.large \
    [compute3]=m1.large \
    [hnas-emulation]=m1.small \
    [ldap]=m1.small \
    [networking-node]=m1.small \
)

MACHINE_IPs=(\
    [openstack-controller]=3 \
    [thinlinc-master]=4 \
    [filsluss]=5 \
    [supernode]=6 \
    [compute1]=7 \
    [compute2]=8 \
    [compute3]=9 \
    [hnas-emulation]=10 \
    [ldap]=11 \
    [networking-node]=12 \
)

DATA_IPs=(\
    [compute1]=110 \
    [compute2]=111 \
    [compute3]=112 \
    [networking-node]=101 \
)
