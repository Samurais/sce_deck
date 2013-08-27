#! /bin/bash 
# constants
BASEDIR=$(cd `dirname $0`;pwd)
PRJDIR=$(cd `dirname $BASEDIR`;pwd)

date=`date`
version=0.1-SNAPSHOT
deck_war=$PRJDIR/target/sce-deck.war
reports_html_name=project-reports.html
index_html=$BASEDIR/index.html
get_start_dir=$BASEDIR/getStarted
skip_test="-DskipTests"
skip_notify=true
notify_mailist="hailiang.hl.wang@gmail.com"
reports_html_path=$PRJDIR/usr/$reports_html_name

# functions

# main 
[ -z "${BASH_SOURCE[0]}" -o "${BASH_SOURCE[0]}" = "$0" ] || return
# variables
parms=($@)
for x in ${parms[@]}; do 
   if [ $x = '-t' ]; then
     skip_test=""
     echo ">> Maven run Tests"
   fi
   if [ $x = '-n' ]; then
     skip_notify=false
     echo ">> Send notifications"
   fi
done

cd $PRJDIR
mvn clean 
mvn $skip_test site:site surefire-report:report-only war:war
# the war package does not contain junit test report
# add it from wrapper
mkdir $PRJDIR/target/tempwar
cd $PRJDIR/target/tempwar
jar -xf $deck_war
# hack the reports files
cp $reports_html_path .
cp -r $get_start_dir .
cp $index_html .
sed -i "s/@build-date@/$date/g" $reports_html_name project-info.html index.html
sed -i "s/@build-version@/$version/g" $reports_html_name project-info.html index.html
 
jar -cf sce-deck.war ./*
cp -rf sce-deck.war $PRJDIR/target
cd $PRJDIR
mvn tomcat7:deploy-only

if [ $skip_notify = "false" ]; then
    echo ">> Send Notification Mails"
	python $BASEDIR/send_mail_notifications.py $notify_mailist $PRJDIR/target/surefire-reports
fi

echo `date`">> Done"

