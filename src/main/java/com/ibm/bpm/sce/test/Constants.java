package com.ibm.bpm.sce.test;

/**
 * Constants
 * 
 * @author hqghuang@cn.ibm.com
 */
public class Constants {

	public static String BPM_AUTOTEST = "bpmAutoTest";
	public static String LOG_NAME = BPM_AUTOTEST + ".log";
	public static String BPM_AUTOTEST_DIR = "bpm_windows_image/" + BPM_AUTOTEST;
	public static String BPM_AUTOTEST_ZIP = BPM_AUTOTEST_DIR + "/" + BPM_AUTOTEST + ".zip";
	public static String CYGWIN_DIR = "/cygdrive/c/cygwin";
	public static String RESULT_LOG = "result.txt";
	// test status
	public static String SUCCESS = "[SUCCESS] ";
	public static String FAILED = "[FAILED] ";
	public static String WARNING = "[WARNING] ";
	// security status
	public static String FAIL = "FAIL!";
	public static String WARN = "WARN!";
	public static String ERROR = "ERROR!";
	public static String LOCAL = "local";
	public static String SAMPLE_BPD_INSTANCE = "ReplenishmentBPD";
	public static String SAMPLE_BPD_TASK = "ApproveReplenishmentOrder";
	public static String RESULT_PREFIX = "Test Result Summary:\n\n";
	public static String HTTP = "http://";
	public static String HTTPS = "https://";
	//email setting
	public static String MAIL_TEST_LIST = "hqghuang@cn.ibm.com";
	public static String MAIL_TEAM_LIST = "hqghuang@cn.ibm.com;huangxin@cn.ibm.com;qianfeng@cn.ibm.com;whliang@cn.ibm.com;cheyi@cn.ibm.com";
	public static String SMTPHOST = "smtp.gmail.com";
	public static String MAIL_FROM = "bpmautotest1@gmail.com";
	public static String MAIL_PWD = "Passw1rd";
	public static String MAIL_SUBJECT = "[BPM TEST REPORT]";
	//config type
	public static String BRONZE = "Bronze";
	public static String SILVER = "Silver";
	public static String GOLD = "Gold";
	public static String PLATINUM = "Platinum";
	//product type
	public static String BPM_PC = "PC";
	public static String BPM_PS = "PS";
	//subject
	public static String MAIL_SUBJECT_NEW = " - Test the fresh BPM image ";
	public static String MAIL_SUBJECT_SECOND = " - Test the second-hand BPM image ";

}
