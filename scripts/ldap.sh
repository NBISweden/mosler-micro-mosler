# -*-sh-*-

source ${SCRIPT_FOLDER:-.}/common.sh

echo "LDAP packages"
{ PACKAGES=openldap-servers openldap-clients
  yum -y install $PACKAGES
}

echo "Configuring iptables"
# Remove the line
sed -i '/^-A INPUT -m state --state NEW -m tcp -p tcp --dport 389 -j ACCEPT/ d' /etc/sysconfig/iptables
# Insert it before --dport 22
sed -i '/^-A INPUT -m state --state NEW -m tcp -p tcp --dport 22 -j ACCEPT/ i \
-A INPUT -m state --state NEW -m tcp -p tcp --dport 389 -j ACCEPT' /etc/sysconfig/iptables
service iptables restart

sed -i 's/^olcRootDN:.*/olcRootDN: cn=Manager,dc=mosler,dc=bils,dc=se/' '/etc/openldap/slapd.d/cn=config/olcDatabase={2}bdb.ldif'
sed -i 's/^olcSuffix:.*/olcSuffix: dc=mosler,dc=bils,dc=se/' '/etc/openldap/slapd.d/cn=config/olcDatabase={2}bdb.ldif'

if sed -n '/^olcSuffix:.*/ p' '/etc/openldap/slapd.d/cn=config/olcDatabase={2}bdb.ldif'; then
   sed -i 's/^olcRootPW:.*/olcRootPW:  {SSHA}SGuX86SN0jX+X4M+1Gxlih4MmjEdh+gM/' '/etc/openldap/slapd.d/cn=config/olcDatabase={2}bdb.ldif'
else
    echo 'olcRootPW:  {SSHA}SGuX86SN0jX+X4M+1Gxlih4MmjEdh+gM' >> '/etc/openldap/slapd.d/cn=config/olcDatabase={2}bdb.ldif'
fi

service slapd restart

echo "Configuration using ldap.conf"
ldapadd -c -D cn=Manager,dc=mosler,dc=bils,dc=se -w ldap -f ldap_conf

