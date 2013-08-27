package com.ibm.bpm.sce.test;

/**
 * 
 * @author hqghuang@cn.ibm.com
 */

import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.io.FilenameFilter;
import java.net.InetAddress;

import com.ibm.sce.deck.tools.FileUtil;
import com.ibm.sce.deck.tools.LogHelper;

public class ResultHandler {

	/**
	 * <p>
	 * Title: printResult
	 * </p>
	 * <p>
	 * Description: print test result
	 * </p>
	 * 
	 * @throws Exception
	 */
	protected void printResult() throws Exception {
		String path = "";
		String jarDir = FileUtil.getDirFromClassLoader();
		if (jarDir == null) {
			path = System.getProperty("user.dir");
		} else {
			path = jarDir.substring(0, jarDir.lastIndexOf(File.separator));
		}
		File file = new File(path + "/script/itcs104/");
		File[] files = file.listFiles(new FilenameFilter() {
			@Override
			public boolean accept(File filedir, String filename) {
				if (filename.endsWith("problems.txt")) {
					return true;
				}
				return false;
			}
		});
		String securityRes = FileUtil.readFile(files[0]);
		int failNum = securityRes.split(Constants.FAIL).length - 1;
		int warnNum = securityRes.split(Constants.WARN).length - 1;
		int errorNum = securityRes.split(Constants.ERROR).length - 1;
		StringBuffer securityLog = new StringBuffer();
		String line = "";
		int i = 1;
		String localHostName = InetAddress.getLocalHost().getHostName();
		//LogHelper.printInfo("localHostName: " + localHostName); 
		BufferedReader input = new BufferedReader(new FileReader(files[0]));
		while ((line = input.readLine()) != null) {
			if (!line.endsWith("\n")) {
				line += "\n";
			}
			line = line.replace(localHostName + ":", "  "+ i + ".");
			securityLog.append(line);
			i++;
		}
		input.close();

		FileUtil.generateReport("[Security Check Result]  failed: " + failNum
				+ " warning: " + warnNum + " error: " + errorNum + "\n"
				+ securityLog.toString());
		// print result.txt
		file = new File(path, Constants.RESULT_LOG);
		LogHelper.printInfo("Test Result Summary:\n");
		input = new BufferedReader(new FileReader(file));
		while ((line = input.readLine()) != null) {
			if (line.endsWith("\n")) {
				line += "\n";
			}
			if (line.startsWith("[")) {
				LogHelper.printInfo("  " + line);
			}
		}
		input.close();
	}

}
