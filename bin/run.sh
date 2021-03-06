#!/bin/bash

HOST=localhost
DATABASE_USER=
USER_USER=
PASSWORD_USER=''
GAME=lemuria
GAME_ID=4
BASE_DIR=/home/fantasya/games/$GAME
ALPHA_DIR=$BASE_DIR/lemuria-alpha
BIN_DIR=$ALPHA_DIR/bin
LAST_TURN=`php8.0 $BIN_DIR/last-turn.php`
LAST_NEWCOMERS_FILE=$ALPHA_DIR/storage/game/$LAST_TURN/newcomers.json
TURN=`expr $LAST_TURN + 1`
NEWCOMERS_FILE=$ALPHA_DIR/storage/game/$TURN/newcomers.json
ZIP_DIR=zip
LOG_DIR=log
EMAIL_DIR=email
EMAIL_SUBJECT="Lemuria AW $TURN"
EMAIL_TEMPLATE=$EMAIL_DIR/turn.email.template
EMAIL_TEXT=$EMAIL_DIR/turn.email.txt
EMAIL_LINK='https://www.fantasya-pbem.de/report/t'
FANTASYACOMMAND="php8.0 /var/customers/webs/fantasya/website/bin/console"
EMAIL_LOG=$EMAIL_DIR/log/$TURN
LOG=$LOG_DIR/run-$TURN.log

cd $BASE_DIR
touch $LOG

echo "Lemuria ZAT start: `date`" >> $LOG
echo "Running turn $TURN..." >> $LOG
echo "Running the game..." >> $LOG
TIMER_START=`date +%s`
ZAT_REPORTS=`php8.0 $BIN_DIR/turn.php`
ZAT_RESULT=$?
echo "Lemuria exit code: $ZAT_RESULT" >> $LOG
TIMER_END=`date +%s`
let DURATION=($TIMER_END-$TIMER_START+30)/60
echo "This AW took $DURATION minutes." >> $LOG
if [ $ZAT_RESULT -gt 0 ]
then
	echo "Game aborted!" >> $LOG
	exit 1
fi
echo >> $LOG

# Allow website to write newcomers.json.
chmod go+w $NEWCOMERS_FILE
# Reset last newcomers.json.
chmod go-w $LAST_NEWCOMERS_FILE

echo "Sending e-mails..." >> $LOG
mkdir -p $EMAIL_LOG
for REPORT_LINE in $ZAT_REPORTS
do
	ID=`echo $REPORT_LINE | cut -d : -f 1`
	UUID=`echo $REPORT_LINE | cut -d : -f 2`
	REPORT=`echo $REPORT_LINE | cut -d : -f 3`
	EMAIL=`$FANTASYACOMMAND email:lemuria $UUID`
	if [ $? -eq 0 ]
	then
		WITH_ATTACHMENT=`mysql -N -s -h $HOST -u $USER_USER -D $DATABASE_USER -p$PASSWORD_USER -e "SELECT u.flags & 1 FROM user u JOIN assignment a ON a.user_id = u.id WHERE a.uuid = '$UUID'"`
		EMAIL_TOKEN=`$FANTASYACOMMAND download:token $GAME_ID $ID $EMAIL $TURN`
		if [ $? -eq 0 ]
		then
			cat $EMAIL_TEMPLATE > $EMAIL_TEXT
			echo "$EMAIL_LINK/$EMAIL_TOKEN" >> $EMAIL_TEXT
			echo "$ID -> $EMAIL" >> $LOG
			if [ $WITH_ATTACHMENT -eq 1 ]
			then
				echo "$REPORT -> $EMAIL" >> $LOG
				mutt -F $EMAIL_DIR/muttrc -s "$EMAIL_SUBJECT" -a $REPORT -- $EMAIL < $EMAIL_TEXT 2>&1 >> $LOG
			else
				mutt -F $EMAIL_DIR/muttrc -s "$EMAIL_SUBJECT" -- $EMAIL < $EMAIL_TEXT 2>&1 >> $LOG
			fi
			echo $(cat $EMAIL_TEXT) > $EMAIL_LOG/$EMAIL.mail 2>> $LOG
		else
			echo "Creation of download token failed for $EMAIL! No mail sent." >> $LOG
		fi
	else
		echo "Fetching email address failed for $UUID! No mail sent." >> $LOG
	fi
done
echo >> $LOG

echo "Lemuria ZAT end: `date`" >> $LOG
echo "Finished." >> $LOG
