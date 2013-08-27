package com.ibm.sce.deck.tools;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.util.Properties;

public class ManagedProperties {

	private static final String USER_HOME = new String(System.getProperty(
			"user.home", null));
	private static String DECK_HOME = new String(USER_HOME + File.separatorChar
			+ "sce_deck");;
	private Properties managed_prop = new Properties();
	private String managed_sce_properties;

	public ManagedProperties() {
		if (checkConfigFiles()) {
			managed_sce_properties = DECK_HOME + File.separatorChar
					+ ManagedConstants.SCE_PROPERTIES;
		} else {
			managed_sce_properties = "src/main/resources/managed_sce.properties";
		}

		FileInputStream fis;
		try {
			fis = new FileInputStream(managed_sce_properties);
			managed_prop.load(fis);
		} catch (IOException e) {
			e.printStackTrace();
		}
	}

	private boolean checkConfigFiles() {
		boolean succ = true;
		if (!(new File(DECK_HOME + File.separatorChar
				+ ManagedConstants.SCE_PROPERTIES)).isFile()) {
			succ = false;
		}
		return succ;
	}

	public String getProperty(final String key) {
		return managed_prop.getProperty(key);
	}

}
