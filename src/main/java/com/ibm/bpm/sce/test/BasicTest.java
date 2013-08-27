package com.ibm.bpm.sce.test;

import java.util.ArrayList;

import com.ibm.sce.deck.tools.FileUtil;

/**
 * 
 * @author hqghuang@cn.ibm.com
 */
public class BasicTest {

	/**
	 * <p>
	 * Title: runTest
	 * </p>
	 * <p>
	 * Description: run test cases which implemented from IBPMTest 
	 * </p>
	 * 
	 * @param ip
	 * @param bpmuser
	 * @param bpmpwd
	 * @param productType
	 */
	public void runTest(String ip, String bpmuser, String bpmpwd,
			String productType) {
		IBPMTest testcase = null;
		TestResult result = null;
		StringBuffer sb = new StringBuffer();
		ArrayList<IBPMTest> testers = new ArrayList<IBPMTest>();
		testcase = new HttpConnection(ip, productType);
		testers.add(testcase);
		testcase = new BpdEngine(ip, bpmuser, bpmpwd);
		testers.add(testcase);
		sb.append(Constants.RESULT_PREFIX);
		for (IBPMTest tester : testers) {
			result = tester.doTest();
			sb.append(result.toString());
		}
		FileUtil.generateReport(sb.toString());
	}

	
	/**
	 * <p>
	 * Title: main
	 * </p>
	 * <p>
	 * Description: invoke by external command
	 * </p>
	 * 
	 * @param args
	 */
	public static void main(String[] args) {
		String ip = args[0];
		String bpmuser = args[1];
		String bpmpwd = args[2];
		String productType = args[3];
		BasicTest test = new BasicTest();
		test.runTest(ip, bpmuser, bpmpwd, productType);
	}
}
