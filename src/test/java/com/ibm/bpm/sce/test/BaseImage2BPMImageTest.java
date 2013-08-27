package com.ibm.bpm.sce.test;

import java.util.HashMap;

import junit.framework.TestCase;

import com.ibm.bpm.sce.exceptions.ImageBuilderException;
import com.ibm.bpm.sce.imagebuilder.DevWindowsImageBuilder;
import com.ibm.bpm.sce.test.ImageTest;
import com.ibm.bpm.sce.test.Constants;
import com.ibm.sce.deck.resources.ManagedImage;
import com.ibm.sce.deck.resources.ManagedLocation;
import com.ibm.sce.deck.tools.LogHelper;

/**
 * 
 * @author hqghuang@cn.ibm.com
 */
public class BaseImage2BPMImageTest extends TestCase{


	/**
	 * End to End test for BPM on SCE
	 */
	public void testSceEnd2End() {

		String swRepoHost = "170.225.163.85";
		// windows org
		// String smallWindows = "20019752";
		// Windows server 2008 base image
		String bpmImageId = "20108365";
		String bpmImageLoc = ManagedLocation.SINGAPORE.getId();
		String bpmInstanceName = "BPMv85WindowsAtlas";
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
		String instType = "SLV64.4/8192/60*500*500";
		
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

		DevWindowsImageBuilder builder;
		ManagedImage image = null;
		try {
			// build BPM image
			builder = new DevWindowsImageBuilder(bpmImageId, bpmImageLoc,
					bpmInstanceName, instType, swRepoHost, parms);
			image = builder.build();

			String imageId = image.getImage().getID();
			// test BPM image
			ImageTest imageTest = new ImageTest(imageId, bpmImageLoc, bpmInstanceName, instType, swRepoHost, parms);
			String secondImageId = imageTest.runAutoTest("src/main/resources/storagekey.com_rsa",
					"idcuser", "bpmadmin", bpmInstPassword, BaseImage2BPMImageTest.class.getSimpleName() + Constants.MAIL_SUBJECT_NEW + imageId);

			// test a second-hand BPM image
			if (secondImageId != null){
				LogHelper.printInfo("Test second-handle BPM image...");
				imageTest = new ImageTest(secondImageId, bpmImageLoc, bpmInstanceName, instType, swRepoHost, parms);
				secondImageId = imageTest.runAutoTest("src/main/resources/storagekey.com_rsa",
						"idcuser", "bpmadmin", bpmInstPassword, BaseImage2BPMImageTest.class.getSimpleName() + Constants.MAIL_SUBJECT_SECOND + secondImageId);
			}
		} catch (ImageBuilderException e) {
			LogHelper.printInfo(e.getMessage());
			e.printStackTrace();
		}
	}
}
