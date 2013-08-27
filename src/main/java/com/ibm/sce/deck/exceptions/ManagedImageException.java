package com.ibm.sce.deck.exceptions;

public class ManagedImageException extends Exception {

	/** serialVersionUID */
	private static final long serialVersionUID = 1L;
	private static final String CLASSNAME = ManagedImageException.class
			.getName();
	public static final String RESOURCE_LIMITATION = new String(
			"Resources Limited");
	public static final String IMAGE_NOT_EXIST = new String(
			"image does not exist");
	public static final String UNAUTHORIZEDUSER = new String(
			"User unauthorized");
	public static final String UNKNOWNIMAGE = new String("unknown image");
	public static final String UNKNOWNERROR = null;
	public static final String SCECLIENT = null;
	public static final String ASSET_LOCAL_FOLDER_NOT_EXIST = new String(
			"local folder does not exist , can not upload it into Image Asset Catalog");
	private static String type;

	private ManagedImageException() {

	}

	public ManagedImageException(final String type) {
		this.type = type;
	}

	public String getType() {
		return this.type;
	}

	public String toString() {
		return CLASSNAME + this.getType();
	}
}
