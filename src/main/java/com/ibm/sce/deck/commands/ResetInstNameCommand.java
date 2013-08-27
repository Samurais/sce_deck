package com.ibm.sce.deck.commands;

import com.ibm.cloud.api.rest.client.ClientConfig;
import com.ibm.cloud.api.rest.client.http.APIHTTPException;
import com.ibm.cloud.api.rest.client.http.command.AbstractHTTPCommand;
import org.apache.commons.httpclient.Header;
import org.apache.commons.httpclient.HttpMethod;
import org.apache.commons.httpclient.methods.PutMethod;
import org.apache.commons.httpclient.methods.StringRequestEntity;
import java.io.Reader;
import java.io.UnsupportedEncodingException;
import java.net.URLEncoder;

public class ResetInstNameCommand extends AbstractHTTPCommand {
	private static final String URI = ClientConfig.CONTEXT
			+ ClientConfig.VERSION + "/instances/";
	private final String id;
	private static String name;

	public ResetInstNameCommand(final String id, final String name) {
		this.id = id;
		this.name = name;
	}

	public String getRelativeURI() {
		return URI + this.id;
	}

	public HttpMethod getMethod() {
		PutMethod put = super.createPUTMethod(getRelativeURI());
		try {
			StringBuilder builder = new StringBuilder("name");
			builder.append("=");
			builder.append(name);
			String encoded = URLEncoder.encode(builder.toString(), "UTF-8");
			StringRequestEntity entity = new StringRequestEntity(encoded,
					"application/x-www-form-urlencoded", null);

			put.setRequestEntity(entity);
		} catch (UnsupportedEncodingException e) {
		}
		return put;
	}

	public void handleResponse(int code, Header[] headers, Reader body)
			throws APIHTTPException {
	}

	// public static void main(String[] args) {
	// String id = new String("444635");
	// String name = new String("YesNew");
	// ResetInstNameCommand cmd = new ResetInstNameCommand(id, name);
	//
	// try {
	// try {
	// ManagedHTTPTransport.exec(cmd);
	// } catch (SCEClientException e) {
	// e.printStackTrace();
	// }
	// // System.out.println(cmd.getInstance().getHostname());
	// } catch (IOException e) {
	// e.printStackTrace();
	// } catch (APIHTTPException e) {
	// e.printStackTrace();
	// }
	//
	// }
}