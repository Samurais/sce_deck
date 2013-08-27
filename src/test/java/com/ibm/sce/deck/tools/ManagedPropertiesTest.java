package com.ibm.sce.deck.tools;

import com.ibm.sce.deck.tools.ManagedProperties;

import junit.framework.TestCase;

public class ManagedPropertiesTest extends TestCase {

	/**
	 * <p>
	 * Title: testProperties
	 * </p>
	 * <p>
	 * Description: SCE Deck uses a properties file to maintain some Global
	 * Settings like path of log .
	 * </p>
	 */
	public void testProperties() {
		ManagedProperties mg = new ManagedProperties();
		assertTrue(!mg.getProperty("sce_account_username").isEmpty());
	}
}
