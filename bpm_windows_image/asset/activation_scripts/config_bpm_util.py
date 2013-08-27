# ****************************************************************
# 
#  THIS PRODUCT CONTAINS RESTRICTED MATERIALS OF IBM
# 
#  5724-M24
# 
#  (C) Copyright IBM Corp. 2013 All Rights Reserved. 
# 
#  US Government Users Restricted Rights - Use, duplication or
#  disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
# 
# ****************************************************************

AdminConfig.setValidationLevel("NONE" )
import java.lang.String as jstr
import java.util.Properties as jprops
import java.io as jio
import javax.management as jmgmt
import AdminUtilities

#.............................................................................	
# Import the cert
#..............................................................................	
def importCert(alias, targetHost, targetPort):
	print "\n**************** importCert() start ****************"
	
	storeName='CellDefaultTrustStore'
	dmgr=AdminControl.completeObjectName("process=dmgr,type=Server,*")
	if dmgr=='':
		storeName='NodeDefaultTrustStore'
	  
	print AdminTask.retrieveSignerInfoFromPort('[-host %s -port %s ]' %(targetHost,targetPort))
	AdminTask.retrieveSignerFromPort('[-keyStoreName %s -host %s -port %s -certificateAlias %s ]' %(storeName,targetHost,targetPort,alias))
	AdminConfig.save()
	
	print "**************** importCert() end ****************"
#endDef

#
#change the db2 password for pc/ps server
#
def updateDB2pwd(dbUser, dbPwd):
	AdminTask.modifyAuthDataEntry('[-alias BPM_DB_ALIAS -user %s -password %s ]' %(dbUser, dbPwd))
	AdminConfig.save()
#endDef

#main

methodName=sys.argv[0]

if (methodName == 'importCert'):
	# importCert(alias, targetHost, targetPort)
	importCert(sys.argv[1], sys.argv[2], sys.argv[3])
elif (methodName == 'updateDB2pwd'):
	updateDB2pwd(sys.argv[1], sys.argv[2])
else:
	print "********** method name input error *************"

