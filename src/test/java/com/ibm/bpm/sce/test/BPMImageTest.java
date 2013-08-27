package com.ibm.bpm.sce.test;

import java.util.HashMap;

import com.ibm.bpm.sce.exceptions.ImageBuilderException;
import com.ibm.bpm.sce.test.ImageTest;
import com.ibm.bpm.sce.test.Constants;
import com.ibm.sce.deck.resources.ManagedLocation;
import com.ibm.sce.deck.tools.LogHelper;
import com.ibm.sce.deck.tools.ManagedProperties;

import junit.framework.TestCase;


/**
 * 
 * @author hqghuang@cn.ibm.com
 */
public class BPMImageTest extends TestCase{

	private ManagedProperties props = new ManagedProperties();
	
	public void testRunAutoTest(){

		/**
		 * deploy instance
		 */
		String swRepoHost = "170.225.163.85";
		// BPM image id
		String bpmImageId = "20108908";
		String bpmImageLoc = ManagedLocation.SINGAPORE.getId();
		String bpmInstanceName = "AutoTest-BPMv85WindowsAtlas";
		String bpmInstUsername = "idcuser";
		String bpmInstPassword = "pwd4Cloud";
		/*
		 * BPM product type 
		 * 
		 * BPMPC - Constants.BPM_PC
		 * BPMPS - Constants.BPM_PS
		 */
		String productType = Constants.BPM_PC;
		
		/*
		 * use for BPM Windows Instance Type
		 * 
		 * Copper - COP64.2/4096/60
		 * Bronze - BRZ64.2/4096/60*500*350
		 * Silver - SLV64.4/8192/60*500*500
		 * Gold - GLD64.8/16384/60*500*500
		 * Platinum - PLT64.16/16384/60*500*500*500*500
		 */
		String instType = "BRZ64.2/4096/60*500*350";
		
		// Provision a BPM PC instance
		HashMap<String, String> parms = new HashMap<String, String>();
		parms.put("UserName", bpmInstUsername);
		parms.put("Password", bpmInstPassword);
		parms.put("BPMAdminUser", "BPMAdminUser");
		parms.put("BPMAdminPassword", bpmInstPassword);
		parms.put("DB2Password", bpmInstPassword);
		if (productType.equals(Constants.BPM_PC)){
			parms.put("ProcessCenterUrl", "http://localhost:9080");
			parms.put("ProcessCenterUserID", "none");
			parms.put("ProcessCenterPassword", "nonepassword");
			parms.put("EnvironmentName", "none");
		} else {
			//update the PC URL
			parms.put("ProcessCenterUrl", "http://localhost:9080");
			parms.put("ProcessCenterUserID", "bpmadmin");
			parms.put("ProcessCenterPassword", bpmInstPassword);
			parms.put("EnvironmentName", "ProcessServer");
		}
		parms.put("EnvironmentType", "Test");

		try {
			ImageTest imageTest = new ImageTest(bpmImageId, bpmImageLoc, bpmInstanceName, instType, swRepoHost, parms);
			String secondImageId = imageTest.runAutoTest(props.getProperty("sce_private_key"), "idcuser", "bpmadmin", 
					bpmInstPassword, BPMImageTest.class.getSimpleName() + Constants.MAIL_SUBJECT_NEW + bpmImageId);
			if (secondImageId != null){
				LogHelper.printInfo("Test second-handle BPM image...");
				imageTest = new ImageTest(secondImageId, bpmImageLoc, bpmInstanceName, instType, swRepoHost, parms);
				secondImageId = imageTest.runAutoTest(props.getProperty("sce_private_key"), "idcuser", "bpmadmin", 
						bpmInstPassword, BPMImageTest.class.getSimpleName() + Constants.MAIL_SUBJECT_SECOND + secondImageId);
			}
		} catch (ImageBuilderException e) {
			e.printStackTrace();
		}
	}
}
