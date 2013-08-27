package com.ibm.bpm.sce.exceptions;

public class ImageBuilderException extends Exception {

	private static String type;
	/** serialVersionUID */
	public static final long serialVersionUID = 1L;
	public static final String INSTANCE_NOT_EXIST = "The instance does not exist.";
	public static final String PARAMS_NOT_VALID = "The user name and password in parameters map are not vaild or no value are set.";

	public ImageBuilderException() {

	}

	public ImageBuilderException(String type) {
		this.type = type;
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
	// // TODO Auto-generated method stub
	//
	// }

}
