# -*-sh-*-

set -v

echo "Openstack python clients"
{ PACKAGES=\
python-novaclient python-keystoneclient python-neutronclient python-glanceclient python-heatclient python-neutronclient \
openstack-nova openstack-neutron openstack-neutron-ml2 openstack-neutron-openvswitch openvswitch MySQL-python
  yum -y install $PACKAGES
}

echo "Starting OpenVSwitch"
service openvswitch start
chkconfig openvswitch on

echo "Configuring iptables"
#lineinfile: dest=/etc/sysconfig/iptables state=present line='-A INPUT -m state --state NEW -s ${MGMT_CIDR} -j ACCEPT' insertbefore='^-A INPUT -m state --state NEW .*'

echo "Configuring iptables"
# Remove the line
sed -i "/^-A INPUT -m state --state NEW -s ${MGMT_CIDR} -j ACCEPT/ d" /etc/sysconfig/iptables
# Insert it before the other line
sed -i "/^-A INPUT -m state --state NEW .*/ i \
-A INPUT -m state --state NEW -s ${MGMT_CIDR} -j ACCEPT" /etc/sysconfig/iptables
service iptables restart
    
echo "Copying Keystone credentials"
rsync rsync/keystonerc /root/.keystonerc

# - name: Adding the supernode as known_hosts
#   shell: echo 'todo'
# # Supernode needs to reach everywhere
# #    - copy: src={{ lookup('env','HOME') }}/.ssh/id_rsa dest=/root/.ssh/id_rsa

