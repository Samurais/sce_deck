package com.ibm.bpm.sce.test;

import java.net.HttpURLConnection;
import java.net.URL;
import java.security.cert.CertificateException;
import java.security.cert.X509Certificate;

import javax.net.ssl.HostnameVerifier;
import javax.net.ssl.HttpsURLConnection;
import javax.net.ssl.SSLContext;
import javax.net.ssl.SSLSession;
import javax.net.ssl.TrustManager;
import javax.net.ssl.X509TrustManager;

/**
 * Mock http requst to BPM WASConsole, ProcessCenter, ProcessPortal,
 * PerformanceAdmin BPCExplorer, BusinessSpace link, ensure the link work.
 * 
 * @author hqghuang@cn.ibm.com
 */
public class HttpConnection implements IBPMTest {

	private String ip = null;
	private String type = null;
	private TestResult tr = new TestResult();

	public HttpConnection(String ip, String productType) {
		this.ip = ip;
		this.type = productType;
	}

	/**
	 * <p>
	 * Title: testConnection
	 * </p>
	 * <p>
	 * Description: Test http connection of BPM links
	 * </p>
	 * 
	 */
	public void testConnection() {
		httpsConnection("WASConsole", Constants.HTTPS + ip + ":9043/ibm/console/logon.jsp");
		httpsConnection("ProcessPortal", Constants.HTTPS + ip + ":9443/ProcessPortal/login.jsp");
		httpConnection("PerformanceAdmin", Constants.HTTP + ip + ":9080/PerformanceAdmin/login.jsp");
		httpsConnection("BusinessSpace", Constants.HTTPS + ip + ":9443/mum/resources/bootstrap/login.jsp");
		httpsConnection("BPCExplorer", Constants.HTTPS + ip + ":9443/bpc/index.jsp");

		if (type.equals("PC")) {
			httpConnection("ProcessCenter", Constants.HTTP + ip + ":9080/ProcessCenter/login.jsp");
		} else {
			logHelper.log("it's PS, skipping test ProcessCenter", tr, TestResult.Status.WARNING);
		}
	}

	/**
	 * <p>
	 * Title: httpConnection
	 * </p>
	 * <p>
	 * Description: request http connection
	 * </p>
	 * 
	 * @param component
	 * @param urlStr
	 */
	protected void httpConnection(String component, String urlStr) {
		try {
			logHelper.log("Connecting to " + urlStr);
			URL url = new URL(urlStr);
			HttpURLConnection conn = (HttpURLConnection) url.openConnection();
			conn.setRequestMethod("POST");
			logHelper.log("Return code: " + conn.getResponseCode());
			if (conn.getResponseCode() != 200) {
				logHelper.log("Failed to connect to " + urlStr, tr, TestResult.Status.FAILED);
				return;
			}
			logHelper.log("Connect to " + component + " success!", tr, TestResult.Status.SUCCESS);
			conn.disconnect();
		} catch (Exception e) {
			logHelper.log("Failed to connect to " + urlStr, tr, TestResult.Status.FAILED);
			logHelper.log(e.getMessage());
		}
	}

	/**
	 * <p>
	 * Title: httpsConnection
	 * </p>
	 * <p>
	 * Description: request https connection
	 * </p>
	 * 
	 * @param component
	 * @param urlStr
	 */
	protected void httpsConnection(String component, String urlStr) {
		try {
			logHelper.log("Connecting to " + urlStr);
			SSLContext sc = SSLContext.getInstance("SSL");
			sc.init(null, new TrustManager[] { new ITrustManager() },
					new java.security.SecureRandom());
			// init a URL resource
			URL url = new URL(urlStr);
			HttpsURLConnection conn = (HttpsURLConnection) url.openConnection();
			conn.setSSLSocketFactory(sc.getSocketFactory());
			conn.setHostnameVerifier(new TrustAnyHostnameVerifier());
			conn.setInstanceFollowRedirects(true);
			conn.setUseCaches(false); // obtain the newest info of server
			conn.setAllowUserInteraction(false);
			conn.setRequestMethod("POST");
			logHelper.log("Return code: " + conn.getResponseCode());
			if (conn.getResponseCode() != 200) {
				logHelper.log("Failed to connect to " + urlStr, tr, TestResult.Status.FAILED);
				return;
			}
			logHelper.log("Connect to " + component + " success!", tr, TestResult.Status.SUCCESS);
			conn.disconnect();
		} catch (Exception e) {
			logHelper.log(e.getMessage());
			logHelper.log("Failed to connect to " + urlStr, tr, TestResult.Status.FAILED);
		}
	}

	private static class TrustAnyHostnameVerifier implements HostnameVerifier {
		public boolean verify(String hostname, SSLSession session) {
			return true;
		}
	}

	private static class ITrustManager implements X509TrustManager {

		// check client trust status
		public void checkClientTrusted(X509Certificate chain[], String authType)
				throws CertificateException {
			logHelper.log("Check client trust status...");
		}

		// check Server trust status
		public void checkServerTrusted(X509Certificate chain[], String authType)
				throws CertificateException {
			logHelper.log("Check client trust status...");
		}

		// get those accepted Issuers
		public X509Certificate[] getAcceptedIssuers() {
			return null;
		}
	}

	public TestResult doTest() {
		tr.setTitle("[BPM Http/Https Connection Test]");
		testConnection();
		return tr;
	}

}
