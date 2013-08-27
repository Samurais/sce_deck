package com.ibm.sce.deck.exceptions;

public class ManagedInstanceException extends Exception {

	/** serialVersionUID */
	private static final long serialVersionUID = 1L;
	private static final String CLASSNAME = ManagedInstanceException.class
			.getName();
	public static final String AUTH_FAILED = new String(
			"Authentication failure");
	public static final String RESOURCE_LIMITATION = new String(
			"Resources Limited");
	public static final String BILLING_NEEDED = new String("Billing needed");
	public static final String INSTANCE_NOT_EXIST = new String(
			"instance does not exist");
	public static final String UPLOAD_FAILED = new String("Upload file failure");
	public static final String DOWNLOAD_FAILED = new String(
			"Download file failure");
	public static final String UNKNOWN = new String("Unknown failure");
	public static final String INVALIDCONFIGURATION = new String(
			"invalid configuration");
	public static final String SCECLIENT = new String(
			"SCE Client fails to access SCE Services");
	public static final String INSTANCE_ACCESS_FAILURE = new String(
			"Fail to access the instance , make sure that sce account,instance ip,ssh keys are all correct. ");
	public static final String PATH_NOT_EXIST_IN_INSTANCE = new String(
			"Path does not exist on instance");
	public static final String FAIL_TO_RUN_AUTOLOG = new String(
			"Fail to run C:/bat/autolog.bat on windows");

	private static String type;
	private static String message;

	private ManagedInstanceException() {

	}

	public ManagedInstanceException(final String type) {
		this.type = type;
	}

	public String getMessage() {
		if (message == null) {
			message = " ";
		}
		return message;
	}

	public String getType() {
		return this.type;
	}

	public void setMessage(final String message) {
		this.message = message;
	}

	public String toString() {
		return CLASSNAME + " " + this.getType() + " " + getMessage();
	}
}
