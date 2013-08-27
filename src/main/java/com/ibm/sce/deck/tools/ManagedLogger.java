package com.ibm.sce.deck.tools;

import org.apache.log4j.Logger;
import org.apache.log4j.xml.DOMConfigurator;

public class ManagedLogger {

	private static ManagedLogger manageLogger;
	private final static String SPACE = new String(":");
	private static Logger infoLogger;
	private static Logger debugLogger;
	private static Logger errLogger;
	private static boolean isLog4j;

	private ManagedLogger() {
		ManagedProperties mgrProps = new ManagedProperties();
		if (mgrProps.getProperty("log4j_enable").equalsIgnoreCase("true")) {
			isLog4j = true;
			DOMConfigurator.configure(mgrProps.getProperty("log4j_xml"));
			infoLogger = Logger.getLogger("INFO");
			debugLogger = Logger.getLogger("DEBUG");
			errLogger = Logger.getLogger("ERROR");
		} else {
			isLog4j = false;
		}
	}

	public void info(String className, String msg) {
		if (isLog4j) {
			infoLogger.info(getMsg(className, msg));
		}
	}

	public void debug(String className, String msg) {
		if (isLog4j) {
			debugLogger.debug(getMsg(className, msg));
		}
	}

	/**
	 * <p>
	 * Title: err
	 * </p>
	 * <p>
	 * Description:
	 * </p>
	 * 
	 * @param msg
	 */
	public void err(String className, String msg) {
		if (isLog4j) {
			errLogger.error(getMsg(className, msg));
		}
	}

	private String getMsg(String className, String msg) {
		StringBuffer sb = new StringBuffer();
		sb.append(className);
		sb.append(SPACE);
		sb.append(msg);
		return sb.toString();
	}

	public synchronized static ManagedLogger getInstance() {
		if (manageLogger == null) {
			manageLogger = new ManagedLogger();
		}
		return manageLogger;
	}

	/**
	 * 
	 * <p>
	 * Title: main
	 * </p>
	 * <p>
	 * Description: test manage log
	 * </p>
	 * 
	 * @param args
	 */

	// public static void main(String[] args) {
	//	
	// ManagedLogger mgrLogger = ManagedLogger.getInstance();
	// String msg = new String("log it");
	// mgrLogger.info(ManagedLogger.class.getName(), msg+" info");
	// mgrLogger.err(ManagedLogger.class.getName(), msg+ " err");
	// mgrLogger.debug(ManagedLogger.class.getName(), msg+ " debug");
	//	
	// }
}
