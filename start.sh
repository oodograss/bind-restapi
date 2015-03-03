#!/bin/bash
#set -e

pkill -TERM named

named -c /etc/named.conf

nohup ruby dns.rb 2>&1>dns.log &