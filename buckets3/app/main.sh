#!/usr/bin/env bashio

AWS_KEY=$(bashio::config 'awskey')
AWS_SECRET=$(bashio::config 'awssecret')
AWS_BUCKET=$(bashio::config 'bucketname')
MAX_SNAPSHOTS_TO_KEEP=$(bashio::config 'maxSnapshots')

function purge_hassio_snapshots() {
  bashio::log.info "About to purge old snapshots"
  SNAPSHOTS=$(bashio::api.hassio GET /snapshots false | jq -c '.snapshots|sort_by(.date)')
  readarray -t SNAPSHOTS < <(echo $SNAPSHOTS | jq -c '.[]')
  bashio::log.info "Found "${#SNAPSHOTS[@]}" Snapshots"
  NUM_TO_DELETE=$((${#SNAPSHOTS[@]} - $MAX_SNAPSHOTS_TO_KEEP))
  if ((NUM_TO_DELETE <= 0)); then
    bashio::log.info "No Snapshots needs to be deleted"
    return
  fi
  bashio::log.info "Delete "$NUM_TO_DELETE" Snapshots"
  for i in $(seq 1 $NUM_TO_DELETE); do
    SNAPSHOT="${SNAPSHOTS[i - 1]}"
    SLUG=$(bashio::jq "$SNAPSHOT" '.slug')
    NAME=$(bashio::jq "$SNAPSHOT" '.name')
    bashio::log.info "About to delete Snapshot: $NAME (ID: $SLUG) "
    bashio::api.hassio POST "/snapshots/${SLUG}/remove" false
  done
}

function create_hassio_snapshot() {
  NAME="backup-"$(date +'%Y-%m-%d %H:%M:%S')
  bashio::log.info "About to create a new snapshot: $NAME"
  BACKUP_ADDONS_ENABLED=$(bashio::config 'backup_addons.enabled')
  readarray -t INSTALLED_ADDONS < <(echo "$(bashio::addons.installed)")
  bashio::log.info "Found "${#INSTALLED_ADDONS[@]}" installed addons"
  WHITELISTED_ADDONS=()
  BLACKLISTED_ADDON=()
  if [ "$BACKUP_ADDONS_ENABLED" == "true" ]; then
    for ((i = 0; i < "$(bashio::config 'backup_addons.whitelist | length')"; i++)); do
      WHITELISTED_ADDONS+=("$(bashio::config "backup_addons.whitelist[$i]")")
    done
    for ((i = 0; i < "$(bashio::config 'backup_addons.blacklist | length')"; i++)); do
      BLACKLISTED_ADDONS+=("$(bashio::config "backup_addons.blacklist[$i]")")
    done
    for i in "${INSTALLED_ADDONS[@]}"; do
      bashio::log.debug "Verify backup policy for Addon ${i}"
      if [[ " ${BLACKLISTED_ADDONS[@]} " =~ " ${i} " ]]; then
        bashio::log.info "Addon ${i} is backlisted -> do not backup"
        continue
      fi
      if ((${#WHITELISTED_ADDONS[@]} <= 0)); then
        bashio::log.info "Addon ${i} is not defined -> backup it"
        BACKUP_ADDONS+=("$i")
        continue
      fi
      if [[ " ${WHITELISTED_ADDONS[@]} " =~ " ${i} " ]]; then
        bashio::log.info "Addon ${i} is whitelisted -> backup it"
        BACKUP_ADDONS+=("$i")
        continue
      fi
    done
  fi
  BACKUP_ADDONS=$(printf '%s\n' "${BACKUP_ADDONS[@]}" | jq -R . | jq -s)

  BACKUP_FOLDERS=("ssl" "addons/local" "homeassistant" "share")
  BACKUP_FOLDERS=$(printf '%s\n' "${BACKUP_FOLDERS[@]}" | jq -R . | jq -s)

  SNAPSHOT_OPTIONS=$(printf '{"name":"%s", "addons":%s, "folders":%s}' "$NAME" "$BACKUP_ADDONS" "$BACKUP_FOLDERS")
  bashio::log.info "snapshot options:" "$SNAPSHOT_OPTIONS"
  bashio::api.hassio POST /snapshots/new/partial "$SNAPSHOT_OPTIONS"
}

function aws_sync() {
  bashio::log.info "About to sync with aws bucket: $AWS_BUCKET"
  aws configure set aws_access_key_id $AWS_KEY
  aws configure set aws_secret_access_key $AWS_SECRET
  aws s3 sync --delete /backup/ s3://""$AWS_BUCKET/
}

bashio::log.info "Start"
create_hassio_snapshot
purge_hassio_snapshots
aws_sync
bashio::log.info "Done"
