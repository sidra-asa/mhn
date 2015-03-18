#!/bin/bash

set -e
set -x

# mnemosyne channels
mnemosyne_SUBSCRIBE='amun.events,conpot.events,thug.events,beeswarm.hive,dionaea.capture,dionaea.connections,thug.files,beeswarn.feeder,cuckoo.analysis,kippo.sessions,glastopf.events,glastopf.files,mwbinary.dionaea.sensorunique,snort.alerts,wordpot.events,p0f.events,suricata.events,shockpot.events'

# honeymap channels
honeymap_SUBSCRIBE='geoloc.events'

# geoloc channels
geoloc_PUBLISH='geoloc.events'
geoloc_SUBSCRIBE='amun.events,dionaea.connections,dionaea.capture,glastopf.events,beeswarm.hive,kippo.sessions,conpot.events,snort.alerts,kippo.alerts,wordpot.events,shockpot.events,p0f.events,suricata.events'

# collector channels
collector_SUBSCRIBE='geoloc.events'
