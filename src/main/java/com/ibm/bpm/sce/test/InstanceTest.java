package com.ibm.bpm.sce.test;

import java.io.File;

import com.ibm.sce.deck.tools.EmailSender;
import com.ibm.sce.deck.tools.FileUtil;
import com.ibm.sce.deck.tools.LogHelper;
import com.ibm.sce.deck.tools.ssh.SSHHelper;
import com.ibm.sce.deck.tools.ssh.SSHResult;

/**
 * Test BPM instance through SSH server
 * 
 * @author hqghuang@cn.ibm.com
 */
public class InstanceTest {

	private static SSHHelper sshhelper = new SSHHelper();
	private String ip;
	private String keyFile;
	private String sshUser;
	private String bpmuser;
	private String bpmpwd;
	private SSHResult report;
	private String bpmtestPackageDir = Constants.CYGWIN_DIR + "/"
			+ Constants.BPM_AUTOTEST;

	public InstanceTest(String keyFile, String sshUser, String ip,
			String bpmuser, String bpmpwd) {
		this.ip = ip;
		this.keyFile = keyFile;
		this.sshUser = sshUser;
		this.bpmuser = bpmuser;
		this.bpmpwd = bpmpwd;
		this.report = null;
	}

	/**
	 * <p>
	 * Title: test
	 * </p>
	 * <p>
	 * Description: Test remote windows instance through SSH server
	 * </p>
	 * 
	 * @param instanceIp
	 */
	public void test(String instanceIp) {
		sshhelper.login(new File(keyFile), sshUser, ip);

		// Send BPM auto test package to remote instance
		FileUtil.createZip(Constants.BPM_AUTOTEST_DIR,
				Constants.BPM_AUTOTEST_ZIP);
		sshhelper.scpTo(Constants.BPM_AUTOTEST_ZIP, Constants.CYGWIN_DIR);
		SSHResult result = sshhelper.exec("rm -rf " + bpmtestPackageDir);

		// Unzip BPM auto test package by jar.exe
		result = sshhelper
				.exec("cd / && /cygdrive/c/IBM/BPM/v8.5/java/bin/jar.exe -xvf C:/cygwin/"
						+ Constants.BPM_AUTOTEST + ".zip");
		LogHelper.printInfo("result: \n" + result.getOut());

		// Run BPM auto test command(bpmtest.bat) through SSH server
		result = sshhelper.exec(bpmtestPackageDir + "/bpmtest.bat " + bpmuser
				+ " " + bpmpwd);
		LogHelper.printInfo("result: \n" + result.getOut());

		// Get test result and send by email
		report = sshhelper.exec("cat " + bpmtestPackageDir + "/result.txt");
		LogHelper.printInfo("result: \n" + report.getOut());
		// Logout SSH
		sshhelper.logout();
	}

	/**
	 * <p>
	 * Title: notify
	 * </p>
	 * <p>
	 * Description: send reports mail addresses
	 * </p>
	 * 
	 * @param mailRecipients
	 * @param subject
	 */
	public void notify(String mailRecipients, String subject) {
		if (report != null) {
			EmailSender mailSender = new EmailSender(subject);
			mailSender.sendResult(mailRecipients, report.getOut());
		} else {
			throw new RuntimeException("Test Report is unavailable.");
		}

	}
}
