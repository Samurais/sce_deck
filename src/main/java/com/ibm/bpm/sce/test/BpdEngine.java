package com.ibm.bpm.sce.test;

import java.net.HttpURLConnection;
import java.net.URL;

import org.apache.commons.codec.binary.Base64;
import com.ibm.json.java.JSONArray;
import com.ibm.json.java.JSONObject;

/**
 * Using BPM Rest API to start a BPD instance, then complete the task
 * 
 * @author hqghuang@cn.ibm.com
 */
public class BpdEngine implements IBPMTest {

	private String ip = null;
	private String bpmuser = null;
	private String password = null;
	private TestResult tr = new TestResult();

	public BpdEngine(String ip, String bpmuser, String password) {
		this.ip = ip;
		this.bpmuser = bpmuser;
		this.password = password;
	}

	/**
	 * <p>
	 * Title: runSimplePA
	 * </p>
	 * <p>
	 * Description: run a system process application
	 * </p>
	 * 
	 * @param hostname
	 * @param username
	 * @param password
	 * @return
	 */
	protected boolean runSimplePA(String hostname, String username,
			String password) {
		if (startBPD(username, password, hostname,
				Constants.SAMPLE_BPD_INSTANCE)) {
			try {
				Thread.sleep(1000 * 3);
			} catch (InterruptedException e) {
				e.printStackTrace();
			}
			if (finishSampleBPDTask(username, password, hostname,
					Constants.SAMPLE_BPD_TASK)) {
				return true;
			}
			return false;
		} else {
			return false;
		}

	}

	/**
	 * <p>
	 * Title: startBPD
	 * </p>
	 * <p>
	 * Description: start BPD instance
	 * </p>
	 * 
	 * @param username
	 * @param password
	 * @param hostname
	 * @param BPDName
	 * @return
	 */
	private boolean startBPD(String username, String password, String hostname,
			String BPDName) {
		JSONObject response = invokeRestApi(username, password, hostname,
				"/rest/bpm/wle/v1/exposed/process", "GET", "parts=all",
		"application/json");
		if (response == null){
			logHelper.log("Start PA " + BPDName + " failed!", tr, TestResult.Status.FAILED);
			return false;
		}
		String status = (String) response.get("status");
		String startURL = new String();
		if (status.equals("200")) {
			JSONObject data = (JSONObject) response.get("data");
			JSONArray bpdList = (JSONArray) data.get("exposedItemsList");
			if (null == bpdList) {
				logHelper.log("There is no exposed BPD to start!", tr, TestResult.Status.WARNING);
				return false;
			}
			for (Object obj : bpdList) {
				if (BPDName.equals(((JSONObject) obj).get("display"))) {
					startURL = (String) ((JSONObject) obj).get("startURL");
					break;
				}
			}
			JSONObject res = invokeRestApi(username, password, hostname,
					startURL, "POST", "parts=all", "application/json");
			status = (String) res.get("status");
			if (status.equals("200")) {
				logHelper.log("Start PA " + BPDName + " success!", tr, TestResult.Status.SUCCESS);
				return true;
			} else {
				logHelper.log("Start PA " + BPDName + " failed!", tr, TestResult.Status.FAILED);
				return false;
			}
		} else {
			logHelper.log("There is no exposed BPD to start!", tr, TestResult.Status.WARNING);
		}
		return false;
	}

	
	/**
	 * <p>
	 * Title: finishSampleBPDTask
	 * </p>
	 * <p>
	 * Description: finish a sample BPD task
	 * </p>
	 * 
	 * @param username
	 * @param password
	 * @param hostname
	 * @param taskName
	 * @return
	 */
	private boolean finishSampleBPDTask(String username, String password,
			String hostname, String taskName) {
		String restURL = "/rest/bpm/wle/v1/search/query?condition=taskStatus%7CReceived&condition=taskSubject%7CTask:%20"
			+ taskName;
		JSONObject response = invokeRestApi(username, password, hostname,
				restURL, "PUT", "parts=all", "application/json");
		if (response == null){
			return false;
		}
		String status = (String) response.get("status");
		String taskId;
		String taskURL;
		JSONObject taskRes;
		if (status.equals("200")) {
			JSONObject data = (JSONObject) response.get("data");
			JSONArray dataList = (JSONArray) data.get("data");
			for (Object obj : dataList) {
				taskId = ((JSONObject) obj).get("taskId").toString();
				taskURL = "/rest/bpm/wle/v1/task/" + taskId + "?action=finish&parts=all";
				taskRes = invokeRestApi(username, password, hostname, taskURL, "PUT", "parts=all", "application/json");
				if (taskRes == null){
					return false;
				}
				if (((String) taskRes.get("status")).equals("200")) {
					if (((String) ((JSONObject) taskRes.get("data")).get("status")).equals("Closed")) {
						logHelper.log("Finish task "+ taskName + ", the task ID is " + taskId, tr, TestResult.Status.SUCCESS);
						return true;
					} else
						logHelper.log(Constants.FAILED + "Fail to complete task " + taskName
								+ ", task ID is " + taskId, tr, TestResult.Status.FAILED);
					return false;
				} else
					logHelper.log(Constants.FAILED + "FAIL! Error got when serach the task finish status.",
							tr, TestResult.Status.FAILED);
				return false;

			}
		} else
			logHelper.log("Error got when search the task list.");
		return false;
	}

	/**
	 * <p>
	 * Title: invokeRestApi
	 * </p>
	 * <p>
	 * Description: invoke BPD RestAPI
	 * </p>
	 * 
	 * @param username
	 * @param password
	 * @param hostname
	 * @param path
	 * @param method
	 * @param body
	 * @param contentType
	 * @return
	 */
	private JSONObject invokeRestApi(String username, String password,
			String hostname, String path, String method, String body,
			String contentType) {
		try {
			HttpURLConnection _current;
			String url = "http://" + hostname + path;
			logHelper.log("Invoke Rest API: " + url);
			_current = (HttpURLConnection) new URL(url).openConnection();
			_current.setRequestMethod(method);
			_current.addRequestProperty("Content-type", contentType);
			if (username != null && password != null) {
				String base64pass = new String(Base64.encodeBase64((username
						+ ":" + password).getBytes()));
				_current.setRequestProperty("Authorization", "Basic "
						+ base64pass);
			}
			JSONObject response = JSONObject.parse(_current.getInputStream());
			return response;
		} catch (Throwable e) {
			logHelper.log(e.getMessage());
			//e.printStackTrace();
			return null;
		}
	}

	/* (non-Javadoc)
	 * @see com.ibm.bpm.sce.autotest.BPMTestInterface#doTest()
	 */
	public TestResult doTest() {
		tr.setTitle("[BPM BPD Engine Test]");
		runSimplePA(ip + ":9080", bpmuser, password);
		return tr;
	}
}
