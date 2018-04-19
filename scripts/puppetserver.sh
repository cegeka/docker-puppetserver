#!/bin/bash

set -e

# define functions
function debug-log() {
    if [ ! -z "$DEBUG_LOG" ]; then
        echo "DEBUG: $@"
    fi
}

function restore-backup-files() {
    source_dir="$1"
    dest_dir="$2"

    if [ -f "$dest_dir/.norestore" ]; then
        # don't restore anything into this directory.
        debug-log "Not restoring into $dest_dir due to presence of .norestore"
        return 0;
    fi

    # create directories if they don't exist
    find $source_dir -mindepth 1 -type d | sort | while read d ; do
        trimmed_d="$(echo $d | sed "s:$source_dir/::g")"
        debug-log "Found a restorable directory at $d, destination $dest_dir/$trimmed_d"
        if [ ! -d "$dest_dir/$trimmed_d" ] ; then
            debug-log "Creating directory $dest_dir/$trimmed_d"
            mkdir -p -m 0755 "$dest_dir/$trimmed_d"
        fi
    done

    # create files if they don't exist
    find $source_dir -mindepth 1 -type f | sort | while read f ; do
        trimmed_f="$(echo $f | sed "s:$source_dir/::g")"
        debug-log "Found a restorable file at $f, destination $dest_dir/$trimmed_f"
        if [ ! -f "$dest_dir/$trimmed_f" ] ; then
            debug-log "Restoring file $dest_dir/$trimmed_f"
            ( cat "$f" > "$dest_dir/$trimmed_f" && chmod 0644 "$dest_dir/$trimmed_f" )
        fi
    done
}

# restore default config files if they don't exist
restore-backup-files /usr/share/puppet/backup/etc /etc/puppetlabs/puppet
restore-backup-files /usr/share/puppetserver/backup/etc /etc/puppetlabs/puppetserver
restore-backup-files /usr/share/puppetcode/backup/etc /etc/puppetlabs/code

# default variables
JAVA_ARGS="${JAVA_ARGS:--Xms2g -Xmx2g}"

INSTALL_DIR="${INSTALL_DIR:-/opt/puppetlabs/server/apps/puppetserver}"
CONFIG="${CONFIG:-/etc/puppetlabs/puppetserver/conf.d}"
#BOOTSTRAP_CONFIG="${BOOTSTRAP_CONFIG:-/etc/puppetlabs/puppetserver/bootstrap.cfg}"
BOOTSTRAP_CONFIG="/etc/puppetlabs/puppetserver/services.d/,/opt/puppetlabs/server/apps/puppetserver/config/services.d/"

# copied from SystemD unit provided by puppet server
exec /usr/bin/java $JAVA_ARGS \
    '-XX:OnOutOfMemoryError=kill -9 %%p' \
    -Djava.security.egd=/dev/urandom \
    -cp "${INSTALL_DIR}/puppet-server-release.jar" clojure.main \
    -m puppetlabs.trapperkeeper.main \
    --config "${CONFIG}" \
    -b "${BOOTSTRAP_CONFIG}" $@

