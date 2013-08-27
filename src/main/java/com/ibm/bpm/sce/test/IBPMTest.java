package com.ibm.bpm.sce.test;

import com.ibm.sce.deck.tools.LogHelper;

/**
 * This abstract class meant to extends by each test case
 * 
 * @author hqghuang@cn.ibm.com
 */
public interface IBPMTest {
	
	public static LogHelper logHelper = LogHelper.getInstance();

	/** implement by each test case **/
	public TestResult doTest();
}
