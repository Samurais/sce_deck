package com.ibm.sce.deck.tools;

import com.ibm.cloud.api.rest.client.http.HTTPCommand;
import com.ibm.cloud.cmd.tool.PasswordFileProcessor;
import com.ibm.cloud.cmd.tool.Security.EncryptionException;
import com.ibm.cloud.cmd.tool.exception.FileOperationException;
import com.ibm.cloud.cmd.tool.exception.UserNameNotMatchedException;
import com.ibm.cloud.api.rest.client.http.APIHTTPException;
import com.ibm.cloud.api.rest.client.http.HTTPTransport;
import com.ibm.sce.deck.exceptions.SCEClientException;

import java.io.IOException;

/**
 * @author Hai Liang BJ Wang/China/IBM Jul 24, 2013
 */
public class ManagedHTTPTransport {
	private static ManagedLogger logger = ManagedLogger.getInstance();
	private static ManagedProperties mgrProps = new ManagedProperties();
	private static HTTPTransport httpTransport;

	private ManagedHTTPTransport() {

	}

	/**
	 * <p>
	 * Title: getHTTPTransportClient
	 * </p>
	 * <p>
	 * Description: return a HTTP Request with the basic information for
	 * smartcloud
	 * </p>
	 * 
	 * @throws SCEClientException
	 */
	private static void getHTTPTransportClient() throws SCEClientException {
		httpTransport = new HTTPTransport();
		String userName = mgrProps.getProperty("sce_account_username");
		String password;
		try {
			// get the account name and password
			if (mgrProps.getProperty("sce_account_has_passphrase")
					.equalsIgnoreCase("true")) {
				String unlockPassphrase = mgrProps
						.getProperty("sce_account_unlock_passphrase");
				String filePath = mgrProps
						.getProperty("sce_account_lock_file_path");
				password = PasswordFileProcessor.getRealPassword(
						unlockPassphrase, filePath, userName);
			} else {
				password = mgrProps.getProperty("sce_account_pwd");
			}
			// set HttpTransport Credentials
			if (password.isEmpty() || (password == null)
					|| (userName.isEmpty()) || (userName == null)) {
				logger.err(ManagedClient.class.getName(),
						">> Failure to get user info for account ");
				throw new SCEClientException(SCEClientException.NOUSER);
			} else {
				httpTransport.setRemoteCredentials(userName, password);
			}
		} catch (Exception e) {
			String exceptionType = new String();
			if (e instanceof FileOperationException) {
				exceptionType = SCEClientException.FILEOPERATION;
			} else if (e instanceof EncryptionException) {
				exceptionType = SCEClientException.ENCRYPTION;
			} else if (e instanceof UserNameNotMatchedException) {
				exceptionType = SCEClientException.USERNAMENOTMATCHED;
			} else {
				exceptionType = SCEClientException.UNKNOWN;
			}
			throw new SCEClientException(exceptionType);
		}

	}

	/**
	 * <p>
	 * Title: exec
	 * </p>
	 * <p>
	 * Description: execute a command by HTTPCommand Interface, the command can
	 * process the reponse later.
	 * </p>
	 * 
	 * @param command
	 * @return the command that contains the response
	 * @throws SCEClientException
	 * @throws IOException
	 * @throws APIHTTPException
	 */
	public static HTTPCommand exec(HTTPCommand command)
			throws SCEClientException, IOException, APIHTTPException {
		getHTTPTransportClient();
		httpTransport.execute(command);
		return command;
	}

	/**
	 * <p>
	 * Title: main
	 * </p>
	 * <p>
	 * Description:
	 * </p>
	 * 
	 * @param args
	 */
	// public static void main(String[] args) {
	//
	// }

}
