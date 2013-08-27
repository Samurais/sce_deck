package com.ibm.bpm.sce.imagebuilder;

import java.util.HashMap;

import com.ibm.bpm.sce.exceptions.ImageBuilderException;
import com.ibm.sce.deck.resources.ManagedLocation;

import junit.framework.TestCase;

public class DevWindowsImageBuilderTest extends TestCase {

	public void testDevWindowsImageBuilder() {

		/**
		 * deploy instance
		 */
		String swRepoHost = "170.225.163.85";
		// windows org
		String smallWindows = "20019752";
		// bpm base
		String bpmImageId = "20108365";
		String bpmImageLoc = ManagedLocation.SINGAPORE.getId();
		String bpmInstanceName = "BPMv85WindowsAtlas";
		String bpmInstUsername = "idcuser";
		String bpmInstPassword = "pwd4Cloud";
		/*
		 * use for BPM Windows Instance Type
		 */
		String brzInstType = "BRZ64.2/4096/60*500*350";
		String copInstType = "COP64.2/4096/60";
		;
		/*
		 * a small size - copper String instType = "COP64.2/4096/60";
		 */
		HashMap<String, String> parms = new HashMap<String, String>();
		parms.put("UserName", bpmInstUsername);
		parms.put("Password", bpmInstPassword);
		parms.put("BPMAdminUser", "BPMAdminUser");
		parms.put("BPMAdminPassword", bpmInstPassword);
		parms.put("DB2Password", bpmInstPassword);
		parms.put("ProcessCenterUrl", "http://localhost:9080");
		parms.put("ProcessCenterUserID", "admin");
		parms.put("ProcessCenterPassword", bpmInstPassword);
		parms.put("EnvironmentName", "ProcessServer");
		parms.put("EnvironmentType", "Test");
		DevWindowsImageBuilder builder;
		try {
			builder = new DevWindowsImageBuilder(bpmImageId, bpmImageLoc,
					bpmInstanceName, brzInstType, swRepoHost, parms);
			builder.build();
		} catch (ImageBuilderException e) {
			e.printStackTrace();
		}
	}

}
