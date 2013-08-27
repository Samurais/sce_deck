package com.ibm.sce.deck.tools;

import junit.framework.TestCase;

import com.ibm.sce.deck.resources.ManagedInstance;
import com.ibm.sce.deck.tools.ManagedLogger;
import com.ibm.sce.deck.tools.ManagedProperties;

/**
 * @author Hai Liang BJ Wang/China/IBM Jul 15, 2013
 */
public class ManagedLoggerTest extends TestCase {

	ManagedProperties managedProps = new ManagedProperties();

	/**
	 * Red Hat v6.4 x86_64 Image ID in Singapore
	 */
	private static String redHatImageID = "20025211";
	private static String instType = "COP64.2/4096/60";
	private static String instName = "idler";
	private static ManagedInstance managedInst;
	private static boolean is_failed = false;
	private static ManagedLogger mgrLogger;
	private static final String msg = new String("log it");
	private static final String CLASS_NAME = ManagedLogger.class.getName();

	public void setUp() throws Exception {
		mgrLogger = ManagedLogger.getInstance();
	}

	public void tearDown() throws Exception {
		mgrLogger = null;
	}

	/**
	 * <p>
	 * Title: test info
	 * </p>
	 * <p>
	 * </p>
	 */
	public void testInfo() {
		mgrLogger.info(CLASS_NAME, msg + " info");

	}

	/**
	 * <p>
	 * Title: test debug
	 * </p>
	 * <p>
	 * </p>
	 */
	public void testDebug() {
		mgrLogger.debug(ManagedLogger.class.getName(), msg + " debug");

	}

	/**
	 * <p>
	 * Title:test err
	 * </p>
	 * <p>
	 * </p>
	 */
	public void testErr() {
		mgrLogger.err(ManagedLogger.class.getName(), msg + " err");

	}

}
