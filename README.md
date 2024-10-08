# vaultwarden-backup-gfs

Simple automatic Vaultwarden backups using the [Grandfather-Father-Son](https://www.backblaze.com/blog/better-backup-practices-what-is-the-grandfather-father-son-approach/)  approach.

** This image currently only supports sqlite and mysql/mariadb installations of Vaultwarden.

** This is a 3rd party project created independently by a user of Vaultwarden and is not associated with [Vaultwarden](https://github.com/dani-garcia/vaultwarden), [Bitwarden](https://github.com/bitwarden), or Bitwarden Inc.

## Installation


vaultwarden-backup-gfs has three requirements:

- Your Vaultwarden data folder or volume is mounted to `/vaultwarden/data`
- An output folder mounted to `/vw-backups/output/`
- `DAILY_RETENTION`, `WEEKLY_RETENTION`, and `MONTHLY_RETENTION` env variables are set

Once retention values are set and the correct volumes mounted, you can run the container with the following commands

~~~
docker pull asouchereau/vaultwarden-backup-gfs

docker run -d --name vaultwarden-backup-gfs \
-v /vw-data/:/vaultwarden/data/ \
-v /vw-backups/:/vw-backups/output/ \
-e DAILY_RETENTION=7 \
-e WEEKLY_RETENTION=8 \
-e MONTHLY_RETENTION=6 \ 
asouchereau/vaultwarden-backup-gfs
~~~


Or use a docker compose file if you prefer

~~~
version: '3.4'

services:

  vaultwarden:
    image: vaultwarden/server:latest
    restart: always
    ports:
      - '80:80'
    volumes:
      - vw-data:/data/
       
  backup:
    image: asouchereau/vaultwarden-backup-gfs:latest
    restart: always
    volumes:
      - vw-data:/vaultwarden/data/
      - vw-backups:/vw-backups/output
    environment:
      - DAILY_RETENTION=7
      - WEEKLY_RETENTION=8
      - MONTHLY_RETENTION=6

volumes:
  vw-data:
    # This volume is shared between the vaultwarden and backup containers
    name: vw-data
  vw-backups:
    # This volume is used to store your archive files
    name: vw-backups

~~~

### Database
#### sqlite
By default, this image looks for a db.sqlite3 file in the top level of your mounted data directory. Set environment variable `DB_TYPE` to `sqlite` or leave it unset. 
#### MariaDB/MySQL
For MySQL or MariaDB setups, this image requires your vaultwarden database credentials to connect and create a dump file. Set the following environment variables
- `DB_TYPE` ("mysql")
- `DB_HOST` (server address or name of docker container running db server)
- `DB_PORT`
- `DB_USER`
- `DB_PASSWORD`
- `DB_DATABASE`

For example:

~~~
  backup:
    image: asouchereau/vaultwarden-backup-gfs:latest
    restart: always
    volumes:
      - vw-data:/vaultwarden/data/
      - vw-backups:/vw-backups/output
    environment:
      - DAILY_RETENTION: 7
      - WEEKLY_RETENTION: 8
      - MONTHLY_RETENTION: 6
      - DB_TYPE: "mysql"
      - DB_HOST: "mariadb"
      - DB_PORT: "3306"
      - DB_USER: "vwuser"
      - DB_PASSWORD: "changeme"
      - DB_DATABASE: "vaultwarden"
~~~


## Usage

### Retention
Retention refers to the maximum amount of time the system will keep a backup for. Since this image uses the GFS approach, there are 3 sets of backups, each with their own retention period.

Each backup type is treated separately, meaning each type runs on independent schedules and archives are stored in different directories. The backups each run at different times to prevent weekly and daily or monthly and daily backups from overlapping, causing one of them to fail.

A cleanup task will run automatically to remove expired backups, but only after a new backup is created successfully. 

| **Backup Type**| **Variable**      | **Example Values** | **Schedule** |
|----------------|-------------------|--------------------|--------------|
| Daily          | DAILY_RETENTION   | "7" (days)         | Every day at 00:00 (0 0 * * *)|
| Weekly         | WEEKLY_RETENTION  | "8" (weeks)        | Every Sunday at 01:00 (0 1 * * 0)|
| Monthly        | MONTHLY_RETENTION | "6" (months)       | First day of every month at 02:00 (0 2 1 * *)|

### Minimum Backups
Minimum backups is the amount of most recent backups that are ignored by the retention system. For example, if MIN_DAILY_BACKUPS is set to 5, the script will keep the 5 most recent backups regardless of their age.

This is useful to prevent the deletion of useful backups in cases where the container is down for an extended period of time and is not creating new backups.

By default, the minimum backup values are the same as the retention values for their respective type. You can overwrite these by setting `MIN_DAILY_BACKUPS`, `MIN_WEEKLY_BACKUPS`, and `MIN_MONTHLY_BACKUPS` as an environment variable in the docker run command / compose file.