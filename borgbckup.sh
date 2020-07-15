#!/bin/sh

# Setting this, so the repo does not need to be given on the commandline:
export BORG_REPO='ssh://backupman@1.2.3.4 /data/backup/php01'

# Setting this, so you won't be asked for your repository passphrase:
export BORG_PASSPHRASE='sadsadk;lksakl;dasldl;asklda'
# or this to ask an external program to supply the passphrase:
#export BORG_PASSCOMMAND='pass show backup'

# some helpers and error handling:
info() { printf "\n%s %s\n\n" "$( date )" "$*" >&2; }
trap 'echo $( date ) Backup interrupted >&2; exit 2' INT TERM

info "Starting backup"

# Backup the most important directories into an archive named after
# the machine this script is currently running on:

borg create                         \
    --verbose                       \
    --filter AME                    \
    --list                          \
    --stats                         \
    --show-rc                       \
    --compression lz4               \
    --exclude-caches                \
    --exclude '/home/*/.local/*'    \
    --exclude '/home/*/.cache/*'    \
    --exclude '/home/*/.config/*'   \
    --exclude '/var/cache/*'        \
    --exclude '/var/tmp/*'          \
                                    \
    ::'{hostname}-{now}'            \
   /projects/                       \
   

backup_exit=$?

info "Pruning repository"

# Use the `prune` subcommand to maintain 7 daily, 4 weekly and 6 monthly
# archives of THIS machine. The '{hostname}-' prefix is very important to
# limit prune's operation to this machine's archives and not apply to
# other machines' archives also:

borg prune                          \
    --list                          \
    --show-rc                       \
    --prefix ''	                    \
    --keep-daily    7               \
    --keep-weekly   4               \
    --keep-monthly  6               \
    

prune_exit=$?

# use highest exit code as global exit code
global_exit=$(( backup_exit > prune_exit ? backup_exit : prune_exit ))

if [ ${global_exit} -eq 0 ]; then
        info "Backup and Prune finished successfully"
        echo "borgbackup on php01: Backup and Prune finished successfully" | \
          mail -s "borgbackup on php01: success" yourmail@gmail.com
    elif [ ${global_exit} -eq 1 ]; then
        info "Backup and/or Prune finished with warnings"
        echo "borgbackup on php01: Backup and Prune finished with warnings" | \
          mail -s "borgbackup on php01: warning" yourmail@gmail.com
    else
        info "Backup and/or Prune finished with errors"
        echo "borgbackup on php01: Backup and Prune finished with errors" | \
          mail -s "borgbackup on php01: error" yourmail@gmail.com
    fi


exit ${global_exit}
