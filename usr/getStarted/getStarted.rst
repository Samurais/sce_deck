How to get on SCE Deck
----------------------------

- configuration
 
SCE Deck uses src/main/resources/managed_sce.properties as the Global Settings File.

====================================   =========================================  ========================================================================
key                                     example                                     description
------------------------------------   -----------------------------------------  ------------------------------------------------------------------------       
sce_account_username                    whliang@cn.ibm.com                         user id of SCE
------------------------------------   -----------------------------------------  ------------------------------------------------------------------------
sce_account_pwd                         cloud4fun                                  password of sce_account_username
------------------------------------   -----------------------------------------  ------------------------------------------------------------------------
sce_account_has_passphrase              true                                       set to true if using passphrase*(1)
------------------------------------   -----------------------------------------  ------------------------------------------------------------------------
sce_account_unlock_passphrase           unlock                                     if using passphrase,provide the unlock name
------------------------------------   -----------------------------------------  ------------------------------------------------------------------------
sce_account_lock_file_path             /home/hailiang/sce/whliang.key              if using passphrase,provide the key file 
------------------------------------   -----------------------------------------  ------------------------------------------------------------------------
sce_ssh_key                             SCEDeck                                    an existing sshkey name from sce_account_username,it is created by user 
------------------------------------   -----------------------------------------  ------------------------------------------------------------------------
sce_private_key                        src/main/resources/storagekey.com_rsa       the private key of sce_ssh_key
------------------------------------   -----------------------------------------  ------------------------------------------------------------------------
sce_public_key                         src/main/resources/storagekey.com_rsa_pub   the public key of sce_ssh_key
------------------------------------   -----------------------------------------  ------------------------------------------------------------------------
log4j_enable                           true                                        if you want to use logger in codes,set to true . if not , set to false
------------------------------------   -----------------------------------------  ------------------------------------------------------------------------
log4j_xml                              src/main/resources/log4j.xml                log4j settings*(2)
====================================   =========================================  ========================================================================
	
	 1. if sce_account_has_passphrase is true , make sure sce_account_unlock_passphrase,sce_account_lock_file_path exist.Generally,you can set it to false and just use sce_account_pwd.sce_account_pwd and sce_account_has_passphrase are two ways to approach your sce account. 
	
	 2. if log4j_enable is true , make sure the log paths that used in log4j_xml exist on your file system.
	
- packages structure

BPM85SCEDeck::
	
	-lib (jars)
	-src 
	---main  
	-----java (java classes)
	-----resources (settings,log4j.xml and sshkeys)
	-------scripts (scripts like shell file )
	-----webapp    (package sce deck site)
	-------WEB-INF
	---test        (junit test class)  
	-----java      (classes here can be used as examples like how to provision instance,manage instances and images)
	-----resources (some files used during testing)
	-------scripts
	-usr           (user guide ,building scripts )  
	---getStartted 

- run junit 

Nothing to specific as the test case can be run in eclipse or ant as usual .

- site

`SCE Deck Site <http://idlerx.cn.ibm.com:8080/sce-deck/>`_ ::

	JavaDocs	JavaDoc API documentation.
	Test JavaDocs	Test JavaDoc API documentation.
	Junit Testcases Report	Junit Testcases Report.
	Cobertura Test Coverage	Cobertura Test Coverage Report.
	Source Xref	HTML based, cross-reference version of Java source code.
	Test Source Xref	HTML based, cross-reference version of Java test source code.
	CPD Report	Duplicate code detection.
	PMD Report	Verification of coding rules.
	Tag List	Report on various tags found in the code.


- note

1. The whole project is built based on Maven. If you want to check in codes, please follow the package structure.
	
2. The configuration needs to be customize in order to use your own account ,keyname and log policy,but don't check in it.
	
3. The job building whole project is started on every Odd Clock like 6:00,8:00 and 10:00. So , any testcase you want to run by SCE Deck, you may check in it accordingly. 