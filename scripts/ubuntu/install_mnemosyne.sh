#!/bin/bash

set -e
set -x

apt-get update
apt-get install -y git python-pip python-dev
pip install virtualenv

SCRIPTS=`pwd`
bash $SCRIPTS/install_mongo.sh

cd /opt/
git clone https://github.com/threatstream/mnemosyne.git
cd mnemosyne
virtualenv env
. env/bin/activate
pip install -r requirements.txt
chmod 755 -R .

source $SCRIPTS/hp_channels.sh
IDENT=mnemosyne
SECRET=`python -c 'import uuid;print str(uuid.uuid4()).replace("-","")'`

cat > /opt/mnemosyne/mnemosyne.cfg <<EOF
[webapi]
host = 0.0.0.0
port = 8181

[mongodb]
database = mnemosyne

[hpfriends]
host = localhost
port = 10000
ident = $IDENT
secret = $SECRET
channels = $CHANNELS

[file_log]
enabled = True
file = mnemosyne.log

[loggly_log]
enabled = False
token =

[normalizer]
ignore_rfc1918 = True
EOF

deactivate
. /opt/hpfeeds/env/bin/activate
python /opt/hpfeeds/broker/add_user.py "$IDENT" "$SECRET" "" "$mnemosyne_SUBSCRIBE"

apt-get install -y supervisor

cat >> /etc/supervisor/conf.d/mnemosyne.conf <<EOF 
[program:mnemosyne]
command=/opt/mnemosyne/env/bin/python runner.py --config mnemosyne.cfg
directory=/opt/mnemosyne
stdout_logfile=/var/log/mnemosyne.log
stderr_logfile=/var/log/mnemosyne.err
autostart=true
autorestart=true
startsecs=10
EOF

supervisorctl update
