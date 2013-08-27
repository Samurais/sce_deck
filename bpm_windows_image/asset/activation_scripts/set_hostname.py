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

#--------------------------------------------------------------------
# This script is designed to modify the host name of all the profiles
# to the current host name of the host.
#
# To invoke the script, type:
#   wsadmin -f setHostName.py <host-name>
#      host_name         - Host name to set in all nodes of the profile
#
#--------------------------------------------------------------------

AdminConfig.setValidationLevel("NONE" )
import sys
from java.io import FileInputStream
from javax.xml.transform.stream import StreamSource
from javax.xml.transform.stream import StreamResult
from javax.xml.parsers import DocumentBuilderFactory
from javax.xml.transform import TransformerFactory
from javax.xml.transform import Transformer
from org.apache.xml.serialize import XMLSerializer
import os

print "Starting script..."
print "Reading config parameters..."

#---------------------------------------------
# Check/Print Usage
#---------------------------------------------
def printUsageAndExit (  ):
        print " "
        print "Usage: wsadmin -f set_hostname.py <host_name>"
        sys.exit()
#endDef

#---------------------------------------------
# Parse command line arguments
#---------------------------------------------
print ""
print "Command line arguments"
print "----------------------"
if (len(sys.argv) < 1):
        printUsageAndExit( )
else:
    #parse the parameters from command line    
    hostName = sys.argv[0];
    print "New Host name:   " + `hostName`
#endElse

#---------------------------------------------
# Obtain Node list
#---------------------------------------------
print ""
print "Finding all Nodes..."
print "--------------------------------"

lineSep = java.lang.System.getProperty("line.separator") 
nodeList = AdminConfig.list('Node').split(lineSep)
for aNode in nodeList:
    node = AdminConfig.showAttribute(aNode, 'name')
    print "Node: " + node
    params = "[-nodeName " + node + " -hostName " + hostName + "]"
    print "changeHostName Parms: " + params
    AdminTask.changeHostName(params)
#endFor
AdminConfig.save();

