#!/bin/bash
webhook="https://bots.keybase.io/<redacted>"

##### USAGE / ERRORS #####

function usage() {
    cat << EOF
Usage: restic-age-checker.sh <root> <command>
Root is the directory where your snapshots are stored in. restic-age-checker.sh stores it's data in '$root\.age-checker'.
EOF
    cat << EOF
cron <quiet>;Run regularly, if no new snapshots are found, notify via webhook. Set quiet to 1 for no summary
status <quiet>;Unlike cron, does not increment age. Intended to be used by the user at any time to get an overview. Set quiet to 1 for no summary
webhook <url>;Set a webhook url for warning notifications. See WEBHOOKS for more information. Set to 0 to disable webhooks.
list;List initialized repos.
setmax <repo> <age>;Set a per-repo maximum age.
(un)ignore <repo>;(Un)ignore a repository.
reset <repo>;Reset repo age to 0.
forget <repo>;Forget all data by restic-age-checker.sh of a repository.
gignoreevery <age-increment>;Set the global default for ignore reminders. The default is to remind of an ignored repository every 30 runs. Set to 0 to disable.
ignoreevery <repo> <age-increment>;Same as globalignorereminder, just per-repo.
EOF | column -t -s ";"
    cat << EOF
Age represents one run, usually one day (executed by cron). Add this to crontab:
@daily /path/to/this/script cron

WEBHOOKS:
The script uses "$repo: $status at $currentsnapdate ($snapage)" as the data for the webhook. This works with Matrix's bot and Keybase. Set webhookdata to a different value as an enviroment variable or in the config file to change this.

EXIT CODES:
Except for 0, the larger the number, the less significant the problem is. Although it could be argued, that a fully successful run is the most significant achivement.
 - 0 Business as usual
 - 1 The script failed to execute. Probably something to do with the syntax.
 - 2 There are one or more unignored repos with that are older than allowed.
 - 3 There are one or more unignored repos with no snapshots.
 - 4 There are one or more ignored repos presnet, of what's ignore reminder has been triggered.
 - 5 There are one or more ignore repos present. This is fine.
EOF
    exit 1
}

## Errors ##

function test-arg-nr { # test-arg-nr <have> <wanted>
    if [[ $1 != $2 ]];then
        if [[ $2 -lt $1 ]];then
            printf "FATAL: Too few arguments!\n\n"
            elif [[ $2 -gt $1 ]];then
            printf "FATAL: Too many arguments!\n\n"
        else
            err-what
        fi
        usage
    fi
}

function err-what {
    echo "FATAL: No idea how this happened, there's probably a bug!"
    exit 1
}

##### FUNCTIONS #####

function main {
    
    sto=$(mktemp --suffix=.csv) # Where we store stdout data in
    touch $sto
    
    for repo in $(ls $root); do # Loop through
        
        local datafile=$repodata/$repo # Where we are kepeing track of a repo's snapshot status.
        touch $datafile # If not exists
        
        source $datafile # Get persistent data if exists
        local currentsnap=$(ls -Art $root/$repo/snapshots/ | tail -n 1) # get latest snap
        
        if [[ $currentsnap == "" ]];then # Some repos don't have snapshots. That's not great.
            local state=empty
        else
            local currentsnapdate=$(date -r $root/$repo/snapshots/$currentsnap "+%F  %H:%M %:::z") # get currentsnap time, used for summary and webhooks.
            
            if [[ "$currentsnap" != "$prevsnap" ]];then # Did we discover a new snapshot?
                local state="new"
                local snapage=1 # We have seen it one time.
            else
                if [[ $1 == 1 ]];then # Are we running script normally (do snaps age)?
                    ((snapage++)) # We saw this snapshot again.
                fi
                
                if [[ $ignore  == 1 ]];then # Is the repo ignored? (am I gonna ping ping you for it not having any new snaps)
                    if [[ $ignoreevery >= 0 ]];then # Global or local
                        local runtimeevery=$ignoreevery
                    else
                        local runtimeevery=$globalevery
                    fi                    
                    if [[ $runtimeevery >= 1 ]] && ! (( $snapage % $runtimeevery )) ; then # Is it time to remind of ignore?
                        local state="igno_remind"
                    else
                        local state="ignored"
                    fi
                else # Not ignored
                    if [[ $max >= 1 ]];then # Global or local
                        local runtimemax=$max
                    else
                        local runtimemax=$globalmax
                    fi
                    
                    if [[ $snapage -gt $runtimemax ]];then # are we missing backups?
                        status="warn"
                    else
                        status="ok"
                    fi
                fi # Ignore
            fi # Did we discover a new snap
        fi # snap is empty
        
        main-state $state $repo $currentsnapdate $snapage # Commit the last known state to the global exit status and get variables for the next command. Last 3 are only used for webhooks.
        
        echo "$sortp;$repo;$state;$snapage;$currentsnapdate" >> $sto # Store the accumulated in a tmp file, that gets fancy read to stdout as a summary.
        
        # Write data file for
        echo "" > $datafile # Persistent: commit and overwrite
        echo "# Data file for restic-age-checker.sh
        local lastsnap=$currentsnap
        local snapage=$snapage
        local max=$max
        local ignore=$ignore
        local ignoreevery=$ignoreevery
        " > $datafile
        
    done # EOF going through repos
    
    main-summary $sto $1 $2
    rm $sto # Cleanup
}

## Main subfunctions ##

function main-state { # main-state <state> <repo> <latestdate> <age>
    # Editing anything here, you probably must edit stuff in function/usage/EXIT\ CODES.
    state=$1
    local webhookorder='$2 $1 $3 $4' # 1=repo 2=status 3=latestdate 4=age
    case $1 in
        warn)
            sortp=6
            main-exit 2
            main-webhook $(eval echo $webhookorder)
        ;;
        empty)
            sortp=5
            main-exit 3
        ;;
        igno_remind)
            sortp=4
            main-exit 4
            main-webhook $(eval echo $webhookorder)
        ;;
        ok)
            sortp=3
        ;;
        new)
            sortp=2
        ;;
        ignored)
            sortp=1
            main-exit 5
        ;;
        *)
            err-what
        ;;
    esac
}

function main-webhook {
    if [[ $webhook != 0 ]]; then
        curl -X POST -H "Content-Type: application/json" -d $(eval echo $webhookdata) $webhook
    else
        echo "WARN: Situation worthy of executiong a webhook, but webhooks disabled."
    fi
}

function main-exit { #main-exit <wanted exit code>
    if [[ $mainexit -lt $1 ]];then
        mainexit=$1 # Only override the exit code, if the situation gets worse.
    fi
}

function main-summary { # main-summary <file-to-print> <read-only> <quiet>
    if [[ $3 != 1 ]];then # If not quiet
        
        if [[ $2 == 1 ]];then # Print if operating in ro mode
            modeheader="ro"
            elif [[ $2 == 0 ]];then
            modeheader="rw"
        else
            err-what
        fi
        
        header1="$(hostname -s);$modeheader;;$(date '+%F  %H:%M %:::z')"
        escaped_header1=$(printf '%s\n' "$header1" | sed -e 's/[\/&]/\\&/g')
        # Static and doesn't need to be escaped.
        header2="repo;status;age;latest"
        divider="----;------;---;------"
        
        cat $1 | sort -t ";" -r -k1,1 -k4rn | cut -c 3- | sed "1s/^/$escaped_header1\n$header2\n$divider\n/g" | column -t -s ";" # Below state=$statusprio, not $status. Statusprio is set along status, representing it as a number, for sorting.
        # Datain | sort by sortp, then age    | rm state  | Pre-append $header1 $header2 and $divider, as above | tidy up and make it nice
    fi
}


## Configurating functions ##

function webhook { # webhook <url or 0 to disable>
    if [[ $1 != 0 ]];then
        webhook=
    else
        regex='(https?|ftp|file)://[-A-Za-z0-9\+&@#/%?=~_|!:,.;]*[-A-Za-z0-9\+&@#/%=~_|]' # https://stackoverflow.com/a/3184819
        if [[ ! $1 =~ $regex ]];then # Are webhooks disabled or a valid URL?
            echo "WARN: Webhook URL is not valid."
        fi
        webhook=$1
    fi
    store-conf
}

function ignore { # unignore <repo> <1 to ignore, 0 to undo>
    testrepo $1 0
    echo "ignore=$2" >> $repodata/$1
}

function list { # list
    ls $root
}

function setmax { # setmax <repo> <runs>
    testrepo $1 0
    echo "max=$2" >> $repodata/$1
}

function reset { # reset <repo>
    testrepo $1 1
    echo "local snapage=0" >> $repodata/$1
}

function forget { # forget <repo>
    testrepo $1 1
    rm $repodata/$1
}

function globalIgnoreEvery { # globalIgnoreEvery <runs>
    globalevery=$1
    store-conf
}

function ignoreEvery { #ignoreEvery <repo> <run>
    testrepo $1 0
    echo "local ignoreevery=$2" >> $repodata/$1
}

## Subfunctions ##

function testrepo { # testrepo <repo> <fatal (1)> <touch repo-config?>
    local testErr=$(ls $1 2>&1)
    if [[ $? != 0 ]];then
        if [[ $2 == 1 ]];then
            echo "FATAL: $testErr"
            exit 1
        fi
        echo "WARN: Creating repo due to: $testErr"
        touch $repodata/$1
    fi
}

function get-conf { # Defaults are set here
    source $acroot/config # Get settings from config file, if exists
    
    ## Set defaults ##
    if [[ -z ${webhookdata+x} ]];then # If not ovverriden, set the webhook data formatting. This can only be done via an env variable to prevent errors. Future changes might make this a conf file thing as well.
        webhookdata='$repo: $status at $currentsnapdate \($snapage\)' # 1=repo 2=status 3=latestdate 4=age
    fi
    
    if [[ -z ${webhook+x} ]] || [[ $webhook == "" ]];then
        webhook=0
    fi
    
    if [[ -z ${globalmax} ]];then
        globalmax=7
    fi
    
    if [[ -z ${globalevery} ]];then
        globalevery=30
    fi
    
    
}

function store-conf {
    echo "# Config file made by restic-age-checker.sh.
webhook=$webhook
globalmax=$globalmax
globalevery=$globalevery
" > $acroot/config
}

##### EXECUTION BEGINS HERE #####

set -e # If any errors occur, stop and exit.

if [[ $1 == "help" ]] || [[ $1 == "-h" ]] || [[ $1 == "--help" ]] ||;then # Print help
    usage
fi

if [[ $# <= 2 ]];then # Do we have the minimum number of arguments?
    err-arg-nr 2 $#
fi

## Mandatory argument: root directory ##
root=$1

rootErr=$(ls $root 2>&1) # Check if root dir exists.
if [[ $? != 0 ]];then
    echo "FATAL: $rootErr"
    exit 1
fi

if [[ $(ls $root) == "" ]];then # Check if root contains any repos
    echo "WARN: root directory does not contain any repos."
fi

acroot=root/.age-checker # All data is stored in here.
repodata=$acroot/repo # All repo data is stored in here. Have to do this, because repos can be named anything, really.
mkdir -p $repodata # Create all needed dirs, if not exist

get-conf

#TODO: transform true, yes; false, no to 0 and 1.

argloop=1
for arg in "$@"; do # Transform aka booleans to 0 and 1.
    case $(echo $arg | tr '[:upper:]' '[:lower:]') in
        true|yes|y)
        declare $$tu=mystr # TODO: how to re-declare number vars?
        ;;
        false|no|n)
        ;;
    esac
    ((argloop++))
done

## Mandatory argument: command ##
case $(echo $2 | tr '[:upper:]' '[:lower:]') in # ,, makes everything lovercase
    cron|run|rw|c)
        test-arg-nr $# 3
        main 1 $3
    ;;
    status|ro|s)
        test-arg-nr $# 3
        main 0 $3
    ;;
    webhook|wh|w)
        test-arg-nr $# 3 $#
        webhook $3
    ;;
    unignore|uignore|ui|u)
        test-arg-nr $# 3
        unignore $3 0
    ;;
    ignore)
        test-arg-nr $# 3
        ignore $3 1
    ;;
    list|ls|l)
        test-arg-nr $# 2
        list
    ;;
    setmax|max|sm|s|m)
        test-arg-nr $# 4
        setmax $3 $4
    ;;
    reset|rs|r)
        test-arg-nr $# 3
        reset $3
    ;;
    ignoreevery|ie)
        test-arg-nr $# 4
        ignoreEvery $3 $4
    ;;
    gignoreevery|globalignoreevery|gie|gi)
        test-arg-nr $£ 4
        ignoreEvery $3 $4
    ;;
    *)
        usage
    ;;
esac

exit $mainexit # Relay the exit code from main.
