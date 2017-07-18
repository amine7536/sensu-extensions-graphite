#!/bin/bash

/opt/sensu/embedded/bin/fpm \
    -f \
    -s gem \
    -t rpm -v $GEM_VERSION \
    --prefix $GEM_PREFIX \
    --depends 'sensu > 0.29' \
    --gem-disable-dependency sensu-extension \
    $1

