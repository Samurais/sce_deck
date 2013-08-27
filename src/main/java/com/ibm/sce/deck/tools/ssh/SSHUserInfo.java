package com.ibm.sce.deck.tools.ssh;

import javax.swing.JPasswordField;
import javax.swing.JTextField;

import com.jcraft.jsch.UserInfo;

public class SSHUserInfo implements UserInfo {
	String passphrase = "passw0rd";
	JTextField passphraseField = (JTextField) new JPasswordField(20);
	
	
	public String getPassword() {
		return null;
	}

	public boolean promptYesNo(String str) {
		System.out.println(str);
		System.out.println("The answer is yes.");
		return true;
	}

	public String getPassphrase() {
		return passphrase;
	}

	public boolean promptPassphrase(String message) {
		return true;
	}

	public boolean promptPassword(String message) {
		return true;
	}

	public void showMessage(String message) {
		System.out.println("Showing message:"+message);
	}
}
