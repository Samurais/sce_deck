package com.ibm.sce.deck.exceptions;

public class SCEClientException extends Exception {

	/** serialVersionUID */
	private static final long serialVersionUID = 1L;
	private static final String CLASSNAME = SCEClientException.class.getName();
	public static final String FILEOPERATION = new String(
			"Passphrase File does not exist or permssion problem");
	public static final String ENCRYPTION = new String("Encryption failure");
	public static final String USERNAMENOTMATCHED = new String(
			"User Name Not Matched");
	public static final String NOUSER = new String(
			"no sce user info(user&password) in settings");
	public static final String UNKNOWN = new String("unknown");
	private static String type;

	private SCEClientException() {
	}

	public SCEClientException(final String type) {
		this.type = type;
	}

	public String getType() {
		return this.type;
	}

	public String toString() {
		return CLASSNAME + this.getType();
	}
}
