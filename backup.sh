#!/bin/sh

# Make sure to:
# 1) Name this file `backup.sh` and place it in /home/ec2-user
# 2) Run sudo apt-get install awscli to install the AWSCLI
# 3) Run aws configure (enter s3-authorized IAM user and specify region)
# 4) Fill in DB host + name
# 5) Create S3 bucket for the backups and fill it in below (set a lifecycle rule to expire files older than X days in the bucket)
# 6) Run chmod +x backup.sh
# 7) Test it out via ./backup.sh
# 8) Set up a daily backup at midnight via `crontab -e`:
#    0 0 * * * /home/ec2-user/backup.sh > /home/ec2-user/backup.log

# DB host (secondary preferred as to avoid impacting primary performance)
HOST=localhost

# DB name
DBNAME=************
DBUSER=****
PASS=******

# S3 bucket name
BUCKET=******

# Linux user account
USER=ec2-user

# Current time
TIME=`/bin/date +%d-%m-%Y-%T`

# Backup directory
DEST=/home/$USER/tmp

# Tar file of backup directory
TAR=$DEST/../$TIME.tar

# Create backup dir (-p to avoid warning if already exists)
/bin/mkdir -p $DEST

# Log
echo "Backing up $HOST/$DBNAME to s3://$BUCKET/ on $TIME";

# Dump from mongodb host into backup directory
/usr/bin/mongodump -h $HOST -d $DBNAME -u $DBUSER -p $PASS -o $DEST --authenticationDatabase admin

# Create tar of backup directory
/bin/tar cvf $TAR -C $DEST .

# Upload tar to s3
/usr/bin/aws s3 cp $TAR s3://$BUCKET/

# Remove tar file locally
/bin/rm -f $TAR

# Remove backup directory
/bin/rm -rf $DEST
 

date_sevendays=$(date +%F --date='7 day ago')
echo "removing before $date_sevendays"
Bucket="********"
olddata=$(aws s3api list-objects --bucket $Bucket  --query "Contents[?LastModified<='$date_sevendays'].Key")
for s3objectname in $olddata; do
if [[ "$s3objectname" != "["  &&  "$s3objectname" != "]" ]];then
filename=$( echo "$s3objectname" | cut -d ',' -f 1)
aws s3 rm  s3://$Bucket/${filename//\"} 
fi 
done 

# All done
echo "Backup available at https://s3.amazonaws.com/$BUCKET/$TIME.tar"
