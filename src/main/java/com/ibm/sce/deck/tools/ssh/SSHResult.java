package com.ibm.sce.deck.tools.ssh;

public class SSHResult {
	
	protected String out;
	
	protected String err;
	
	protected int returnCode=-2000;

	public String getOut() {
		return out;
	}

	public void setOut(String out) {
		this.out = out;
	}

	public String getErr() {
		return err;
	}

	public void setErr(String err) {
		this.err = err;
	}

	public int getReturnCode() {
		return returnCode;
	}

	public void setReturnCode(int returnCode) {
		this.returnCode = returnCode;
	}
}
