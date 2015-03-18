#!/bin/bash

set -e
set -x

. /opt/hpfeeds/env/bin/activate

SCRIPTS=`pwd`
source $SCRIPTS/hp_channels.sh

# update the hpfeeds channels used by mnemosyne
IDENT=mnemosyne
SECRET=`python -c "import pymongo;print pymongo.MongoClient().hpfeeds.auth_key.find({'identifier':'$IDENT'},{'secret':'1','_id':0})[0]"|grep -o "[a-z0-9]\{32\}"`

python /opt/hpfeeds/broker/add_user.py "$IDENT" "$SECRET" "" "$mnemosyne_SUBSCRIBE"

unset IDENT
unset SECRET

# update the hpfeeds channels used by honeymap
IDENT=honeymap
SECRET=`python -c "import pymongo;print pymongo.MongoClient().hpfeeds.auth_key.find({'identifier':'$IDENT'},{'secret':'1','_id':0})[0]"|grep -o "[a-z0-9]\{32\}"`

python /opt/hpfeeds/broker/add_user.py "$IDENT" "$SECRET" "" "$honeymap_SUBSCRIBE"

unset IDENT
unset SECRET

# update the hpfeeds channels used by geoloc
IDENT=geoloc
SECRET=`python -c "import pymongo;print pymongo.MongoClient().hpfeeds.auth_key.find({'identifier':'$IDENT'},{'secret':'1','_id':0})[0]"|grep -o "[a-z0-9]\{32\}"`

python /opt/hpfeeds/broker/add_user.py "$IDENT" "$SECRET" "$geoloc_PUBLISH" "$geoloc_SUBSCRIBE"

unset IDENT
unset SECRET

# update the hpfeeds channels used by collector
IDENT=collector
SECRET=`python -c "import pymongo;print pymongo.MongoClient().hpfeeds.auth_key.find({'identifier':'$IDENT'},{'secret':'1','_id':0})[0]"|grep -o "[a-z0-9]\{32\}"`

python /opt/hpfeeds/broker/add_user.py "$IDENT" "$SECRET" "$PUBLISH_CHAN" "$collector_SUBSCRIBE"

unset IDENT
unset SECRET
unset SUBSCRIBE_CHAN

deactivate

supervisorctl reload
