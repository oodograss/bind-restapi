#!/bin/bash
set -e

# install 

CDIR=$( cd "$( dirname "$0" )" && pwd )
BINDVER=bind-9.10.1-P1

. ./config.property
if [ -z "$domain" -o -z "$host" -o -z "$in_addr" -o -z "$lb_addr" -o -z "$API_KEY" ]; then
	echo "Config imcomplete."
	exit 1
fi

## install bind
echo "***"
echo "Installing DNS Server..."
echo "***"
tar -xzf ${BINDVER}.tar.gz
cd ${BINDVER}/
mkdir -p /var/state
./configure --prefix=/usr --sysconfdir=/etc --enable-threads --localstatedir=/var/state --with-libtool --with-openssl=/usr
make && make install

if [ -n `which yum` ]; then
	yum install -y bind-libs
fi

## dns api
echo "***"
echo "Installing API Server..."
echo "***"
gem install sinatra

## configure
echo "***"
echo "Configuring..."
echo "***"
mkdir -p /var/lib/bind

cd /var/lib/bind
dnssec-keygen -a HMAC-MD5 -b 128 -n HOST ${domain}.
key=`cat *.key | awk '{print $NF}'`

dig -t NS . > named.rootl

cd $CDIR
cp etc/named.conf /etc/named.conf
cp etc/domain.zone /var/lib/bind/${domain}.zone
cp etc/domain.loopback /var/lib/bind/${domain}.loopback

sed -i "s/\${domain}/${domain}/g" /etc/named.conf
sed -i "s/\${key}/${key}/g" /etc/named.conf
sed -i "s/\${host}/${host}/g" /etc/named.conf
sed -i "s/\${in_addr}/${in_addr}/g" /etc/named.conf

sed -i "s/\${domain}/${domain}/g" /var/lib/bind/${domain}.zone
sed -i "s/\${host}/${host}/g" /var/lib/bind/${domain}.zone

sed -i "s/\${domain}/${domain}/g" /var/lib/bind/${domain}.loopback
sed -i "s/\${in_addr}/${in_addr}/g" /var/lib/bind/${domain}.loopback
sed -i "s/\${lb_addr}/${lb_addr}/g" /var/lib/bind/${domain}.loopback

sed -i "s/\${host}/${host}/g" dns.rb
sed -i "s/\${domain}/${domain}/g" dns.rb
sed -i "s/\${key}/${key}/g" dns.rb
sed -i "s/\${API_KEY}/${API_KEY}/g" dns.rb

echo "***"
echo "Finished!"
echo "***"
