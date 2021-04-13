#!/bin/sh

REFDIR="$HOME/path/to/location"
PAPERS='/papers'
BOOKS='/books'
ARTICLES='/articles'
BPOSTS='/blogposts'
TEMP='/temp'
BIBFILE='library.bib'

syncBib()
{
    rm -f /tmp/$BIBFILE
    rclone --retries 1 --ignore-errors copy gdrive:Temp/$BIBFILE /tmp/ 2>/dev/null

    if [ "$?" -eq 0 ]; then
        if [ "$(sha1sum /tmp/$BIBFILE | cut -d ' ' -f 1)" != "$(sha1sum $REFDIR/$BIBFILE | cut -d ' ' -f 1)" ]; then \
            echo "syncBib: Remote bibfile differs, updating it..."
            rclone --retries 1 --ignore-errors delete gdrive:Temp/$BIBFILE 2>/dev/null
            if [ "$?" -ne 0 ]; then
                echo "syncBib: Couldn't delete remote bibfile.."
            else
                echo "syncBib: Deleted remote bibfile."
            fi

            rclone --retries 1 --ignore-errors copy $REFDIR/$BIBFILE gdrive:Temp/ 2>/dev/null
            if [ "$?" -ne 0 ]; then
                echo "syncBib: Failed to copy bibfile to remote!"
            else
                echo "syncBib: Copied bibfile to remote."
            fi
        fi
    else
        echo "syncBib: Remote doesn't have bibfile present, so nothing to compare to local. Updating..." 
        rclone --retries 1 --ignore-errors copy $REFDIR/$BIBFILE gdrive:Temp/ 2>/dev/null
        if [ "$?" -ne 0 ]; then
            echo "syncBib: Failed to copy bibfile to remote!"
        else
            echo "syncBib: Copied bibfile to remote."
        fi
    fi
}

syncDir() 
{
    [ $2 -eq 1 ] && rclone --retries 1 --ignore-errors copy $REFDIR/$1/ gdrive:$1/ 2>/dev/null \
        || rclone --retries 1 --ignore-errors sync $REFDIR/$1/ gdrive:$1/ 2>/dev/null

    RET=$?

    if [ $RET -eq 0 -a $2 -eq 1 ]; then
        echo "syncDir: Copied $REFDIR/$1 to remote."
    elif [ $RET -eq 0 -a $2 -eq 2 ]; then
        echo "syncDir: Sync'd remote with $REFDIR/$1."
    else
        echo "syncDir: Unable to copy/sync $REFDIR/$1 <-> remote!"
    fi
}

inotifywait -mr -e 'CREATE,DELETE,ATTRIB' --format '%w %e %f' \
    ${REFDIR} | grep -E '(\/Documents\/\s{1,2}|blogposts|articles|books|papers)' \
    --line-buffered | egrep -v '^.*(\.sav|\.bak|\.tmp)$|^.*ATTRIB.*(\.pdf|\.epub)$' \
    --line-buffered | \
while read -r dir ; do

    VAL1=$(echo ${dir//\/} | cut -d ' ' -f 1 --output-delimiter='' | sed "s/${REFDIR//\/}//")
    VAL2=$(echo ${dir//\/} | cut -d ' ' -f 2 --output-delimiter='')

    if [ "books" = "$VAL1" -a "CREATE" = "$VAL2" ]; then
        syncDir ${BOOKS:1:${#BOOKS}} 1
    elif [ "books" = "$VAL1" -a "DELETE" = "$VAL2" ]; then
        syncDir ${BOOKS:1:${#BOOKS}} 2
    #
    elif [ "papers" = "$VAL1" -a "CREATE" = "$VAL2" ]; then
        syncDir ${PAPERS:1:${#PAPERS}} 1
    elif [ "papers" = "$VAL1" -a "DELETE" = "$VAL2" ]; then
        syncDir ${PAPERS:1:${#PAPERS}} 2
    #
    elif [ "blogposts" = "$VAL1" -a "CREATE" = "$VAL2" ]; then
        syncDir ${BPOSTS:1:${#BPOSTS}} 1
    elif [ "blogposts" = "$VAL1" -a "DELETE" = "$VAL2" ]; then
        syncDir ${BPOSTS:1:${#BPOSTS}} 2
    #
    elif [ "articles" = "$VAL1" -a "CREATE" = "$VAL2" ]; then
        syncDir ${ARTICLES:1:${#ARTICLES}} 1
    elif [ "articles" = "$VAL1" -a "DELETE" = "$VAL2" ]; then
        syncDir ${ARTICLES:1:${#ARTICLES}} 2
    #
    elif [ "ATTRIB" = "$VAL2" ]; then
        syncBib
    else
        echo "Event, but bad programming. Not doing anything."
    fi

done
