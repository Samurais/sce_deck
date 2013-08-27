package com.ibm.bpm.sce.test;

import java.util.ArrayList;
import java.util.List;

/**
 * 
 * @author hqghuang@cn.ibm.com
 */
public class TestResult {

	private String title;

	public enum Status {
		SUCCESS, FAILED, WARNING
	}

	/** test case that passed */
	private List<String> passList = new ArrayList<String>();

	/** test case that failed */
	private List<String> failList = new ArrayList<String>();

	/** test case that warned */
	private List<String> warnList = new ArrayList<String>();

	public List<String> getPassList() {
		return passList;
	}

	public void addSuccessCase(String caseName) {
		passList.add(caseName);
	}

	public List<String> getFailList() {
		return failList;
	}

	public void addFailedCase(String caseName) {
		failList.add(caseName);
	}

	public void addWarningCase(String caseName) {
		warnList.add(caseName);
	}

	public List<String> getWarnList() {
		return warnList;
	}

	public String getTitle() {
		return title;
	}

	public void setTitle(String title) {
		this.title = title;
	}

	public String toString() {
		StringBuffer sb = new StringBuffer();
		sb.append(title + "  passed: " + passList.size() + " failed: " + failList.size() + " warning: " + warnList.size() + "\n");

		if (passList.size() > 0){
			sb.append("  Passed item list: \n");
			for (int i=1; i <= passList.size(); i++){
				String prefix = i < 10 ? "  " : " "; 
				sb.append(prefix + i + ". " + passList.get(i-1) + "\n");
			}
			sb.append("\n");
		}
		
		if (warnList.size() > 0){
			sb.append("  Warned item list: \n");
			for (int i=1; i <= warnList.size(); i++){
				String prefix = i < 10 ? "  " : " "; 
				sb.append(prefix + i + ". " + warnList.get(i-1) + "\n");
			}
			sb.append("\n");
		}
		
		if (failList.size() > 0){
			sb.append("  Failed item list: \n");
			for (int i=1; i <= failList.size(); i++){
				String prefix = i < 10 ? "  " : " "; 
				sb.append(prefix + i + ". " + failList.get(i-1) + "\n");
			}
		}
		return sb.toString();
	}
}
