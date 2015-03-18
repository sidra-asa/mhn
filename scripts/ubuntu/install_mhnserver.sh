#!/bin/bash

set -e
set -x

apt-get update
apt-get install -y git build-essential python-pip python-dev redis-server
pip install virtualenv

MHN_HOME=/opt/mhn
OSVER=$(basename `pwd`)
cd $MHN_HOME

virtualenv env
. env/bin/activate
pip install -r server/requirements.txt

cd $MHN_HOME/server/

echo "==========================================================="
echo "  MHN Configuration"
echo "==========================================================="

python generateconfig.py

echo -e "\nInitializing database, please be patient. This can take several minutes"
python initdatabase.py $OSVER
cd $MHN_HOME

apt-get install -y nginx
mkdir -p /opt/www
cat > /etc/nginx/sites-available/default <<EOF 
server {
    listen       80;
    server_name  _;
    
    location / { 
        try_files \$uri @mhnserver; 
    }
    
    root /opt/www;

    location @mhnserver {
      include uwsgi_params;
      uwsgi_pass unix:/tmp/uwsgi.sock;
    }

    location  /static {
      alias $MHN_HOME/server/mhn/static;
    }
}
EOF
ln -fs /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default

apt-get install -y supervisor

cat > /etc/supervisor/conf.d/mhn-uwsgi.conf <<EOF 
[program:mhn-uwsgi]
command=$MHN_HOME/env/bin/uwsgi -s /tmp/uwsgi.sock -w mhn:mhn --pyargv $OSVER -H $MHN_HOME/env --chmod-socket=666
directory=$MHN_HOME/server
stdout_logfile=/var/log/uwsgi/mhn.log
stderr_logfile=/var/log/uwsgi/mhn.err
autostart=true
autorestart=true
startsecs=10
EOF

cat > /etc/supervisor/conf.d/mhn-celery-worker.conf <<EOF 
[program:mhn-celery-worker]
command=$MHN_HOME/env/bin/celery worker -A mhn.tasks --loglevel=INFO
directory=$MHN_HOME/server
stdout_logfile=$MHN_HOME/server/worker.log
stderr_logfile=$MHN_HOME/server/worker.err
autostart=true
autorestart=true
startsecs=10
user=www-data
EOF

cat > /etc/supervisor/conf.d/mhn-celery-beat.conf <<EOF 
[program:mhn-celery-beat]
command=$MHN_HOME/env/bin/celery beat -A mhn.tasks --loglevel=INFO
directory=$MHN_HOME/server
stdout_logfile=$MHN_HOME/server/worker.log
stderr_logfile=$MHN_HOME/server/worker.err
autostart=true
autorestart=true
startsecs=10
EOF

SECRET=`python -c 'import uuid;print str(uuid.uuid4()).replace("-","")'`
/opt/hpfeeds/env/bin/python /opt/hpfeeds/broker/add_user.py "collector" "$SECRET" "" "$collector_SUBSCRIBE"

cat > $MHN_HOME/server/collector.json <<EOF
{
  "IDENT": "collector",
  "SECRET": "$SECRET"
}
EOF

cat > /etc/supervisor/conf.d/mhn-collector.conf <<EOF 
[program:mhn-collector]
command=$MHN_HOME/env/bin/python collector.py collector.json
directory=$MHN_HOME/server
stdout_logfile=$MHN_HOME/server/collector.log
stderr_logfile=$MHN_HOME/server/collector.err
autostart=true
autorestart=true
startsecs=10
EOF

touch $MHN_HOME/server/mhn.log
mkdir -p /var/log/uwsgi
chown www-data:www-data -R $MHN_HOME/server/*

supervisorctl update
/etc/init.d/nginx restart
