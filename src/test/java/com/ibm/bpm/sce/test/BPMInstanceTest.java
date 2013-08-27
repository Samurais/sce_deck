package com.ibm.bpm.sce.test;

import com.ibm.bpm.sce.test.InstanceTest;
import com.ibm.bpm.sce.test.Constants;
import com.ibm.sce.deck.tools.ManagedProperties;

import junit.framework.TestCase;

/**
 * Test a BPM instance
 * 
 * @author hqghuang@cn.ibm.com
 */
public class BPMInstanceTest extends TestCase {

	private String imageId = "20108931";
	private String instanceIp = "170.225.162.68";
	private String bpmUser = "bpmadmin";
	private String bpmPwd = "Passw0rd";
	private ManagedProperties props = new ManagedProperties();

	public void testBPMWindowsInstanceWithSSH() {
		// test the instance
		InstanceTest instance = new InstanceTest(props
				.getProperty("sce_private_key"), "idcuser", instanceIp,
				bpmUser, bpmPwd);
		instance.test(instanceIp);

		// send test report
		String subject = BPMInstanceTest.class.getSimpleName()
				+ " test BPM instance " + instanceIp + " launched from image-"
				+ imageId;
		instance.notify(Constants.MAIL_TEAM_LIST, subject);
	}
}
