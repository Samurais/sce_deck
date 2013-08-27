package com.ibm.sce.deck.tools;

import com.ibm.cloud.api.rest.client.DeveloperCloud;
import com.ibm.cloud.api.rest.client.DeveloperCloudClient;
import com.ibm.cloud.cmd.tool.PasswordFileProcessor;
import com.ibm.cloud.cmd.tool.Security.EncryptionException;
import com.ibm.cloud.cmd.tool.exception.FileOperationException;
import com.ibm.cloud.cmd.tool.exception.UserNameNotMatchedException;
import com.ibm.sce.deck.exceptions.SCEClientException;

public class ManagedClient {

	private static ManagedLogger logger = ManagedLogger.getInstance();
	private static ManagedProperties mgrProps = new ManagedProperties();

	public static DeveloperCloudClient getSCEClient() throws SCEClientException {
		DeveloperCloudClient client = DeveloperCloud.getClient();
		try {
			String userName = mgrProps.getProperty("sce_account_username");
			String password;
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
			if (password.isEmpty() || (password == null)
					|| (userName.isEmpty()) || (userName == null)) {
				logger.err(ManagedClient.class.getName(),
						">> Failure to get user info for account ");
				throw new SCEClientException(SCEClientException.NOUSER);
			} else {
				client.setRemoteCredentials(userName, password);
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
		return client;
	}

	/**
	 * <p>
	 * Title: main
	 * </p>
	 * <p>
	 * Description:test Get client objects
	 * </p>
	 * 
	 * @param args
	 */
	// public static void main(String[] args) {
	//
	// try {
	// DeveloperCloudClient clt = ManagedClient.getSCEClient();
	// try {
	// clt.describeKeys();
	// } catch (UnauthorizedUserException e) {
	// e.printStackTrace();
	// } catch (UnknownErrorException e) {
	// e.printStackTrace();
	// } catch (IOException e) {
	// e.printStackTrace();
	// }
	// } catch (SCEAccountAuthException e) {
	// e.printStackTrace();
	// }
	//
	// }

}
