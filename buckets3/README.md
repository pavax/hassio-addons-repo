# Hassio Addon for Backing up to S3 Bucket

Add-on for creating and uploading hass.io snapshots to AWS S3. 

This addon is essentially a simple mixture of the following projects
 * https://github.com/marcelveldt/hassio-addons-repo
 * https://github.com/rrostt/hassio-backup-s3

## Installation

Save files in /addons/buckets3 on your hassio machine.

Under the Add-on Store tab in the Hass.io view in HA you'll find the addon under Local add-ons.

Install, then set the config variables. You should create an s3-bucket, and create a user with IAM policy rights to upload an object to the bucket.

## AWS Configuration

Example IAM policy to access a certain bucket

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "s3:ListAllMyBuckets",
                "s3:GetBucketLocation"
            ],
            "Resource": "*"
        },
        {
            "Sid": "VisualEditor1",
            "Effect": "Allow",
            "Action": "s3:ListBucket",
            "Resource": "arn:aws:s3:::my-backup-bucket-name"
        },
        {
            "Sid": "VisualEditor2",
            "Effect": "Allow",
            "Action": "s3:*Object",
            "Resource": "arn:aws:s3:::my-backup-bucket-name/*"
        }
    ]
}
```


## Configuration

**Note**: _Remember to restart the add-on when the configuration is changed._

Example add-on configuration:

```json
{
  "awskey": "***",
  "awssecret": "***",
  "bucketname": "my-backup-bucket-name",
  "maxSnapshots": "3",
  "schedule": "0 4 * * *",
  "run_backup_at_startup": true,
  "backup_addons": {
    "enabled": "true",
    "whitelist": [],
    "blacklist": [
      "local_backup_s3",
      "15ef4d2f_esphome",
      "a0d7b954_sqlite-web",
      "core_mosquitto",
      "ae6e943c_remote_api"
    ]
  }
}
```
**Note**: _This is just an example, don't copy and paste it! Create your own!_

### Option: `awskey`

The bucket users `access key id` 

### Option: `awssecret`

The bucket users `secret access key`


### Option: `schedule`

Schedule when the backup task should run. By default it's set to every night at 04:00.
You can use CRON syntax for this. http://www.nncron.ru/help/EN/working/cron-format.htm


### Option: `run_backup_at_startup`

Enabling this option will run the snapshot task on startup of the addon (besides the configures schedule).
Usefull for the first time configuration.


### Option: `backup_addons`

This setting allows you to include installed addons (and their configuration) into the snapshot.
`enabled`: include installed addons in the snapshot.
`whitelist`: (optional) only include addons in this list the snapshot.
`blacklist`: (optional) include all addons except in items in this list the snapshot.

If you do not specify whitelist and blacklist items, all addons will be included in the snapshot.
You can use either use the full name for an addon or the short name (which you will have to figure out yourself)


### Option: `maxSnapshots`
Automatically purge old snapshot from hassio.
