package com.ibm.sce.deck.tools;

import java.io.File;
import java.io.FileInputStream;

import com.ibm.sce.deck.tools.ssh.SSHHelper;
import com.ibm.sce.deck.tools.ssh.SSHResult;

/**
 * @author Hai Liang BJ Wang/China/IBM Jul 24, 2013
 */
public class SSHClient {
	private static ManagedProperties mgrProps = new ManagedProperties();
	private File privateKey = new File(mgrProps.getProperty("sce_private_key"));
	private String userName = new String("idcuser");
	private String hostname;

	/**
	 * <p>
	 * Title: Provide SSH Client by a given IP
	 * </p>
	 * <p>
	 * Description: get a ssh client that can execute shell commands ,scp files
	 * and return responses.
	 * </p>
	 * 
	 * @param hostname
	 *            machine that uses the same ssh key pair seted in SCE Deck
	 *            properties . In other word, the machine can be accessed in
	 *            this way - ssh -i sce_private_key idcuser@hostname
	 */
	public SSHClient(final String hostname) {
		this.hostname = hostname;
	}

	/**
	 * TODO
	 * <p>
	 * Title: uploadFolder
	 * </p>
	 * <p>
	 * Description: upload a folder
	 * </p>
	 * 
	 * @param localPath
	 * @param remotePath
	 */
	// public void uploadFolder(String localPath, String remotePath) {
	// SSHHelper sshhelper = new SSHHelper();
	// sshhelper.login(privateKey, userName, hostname);
	// sshhelper.logout();
	// }

	/**
	 * <p>
	 * Title: upload
	 * </p>
	 * <p>
	 * Description: upload a file into remote machine
	 * </p>
	 * 
	 * @param localPath
	 *            the absolute or relative path of file. It is better to use
	 *            absolute path.
	 * @param remotePath
	 *            the path that uses for this file in remote machine
	 */
	public void upload(String localPath, String remotePath) {
		SSHHelper sshhelper = new SSHHelper();
		sshhelper.login(privateKey, userName, hostname);
		sshhelper.scpTo(localPath, remotePath);
		sshhelper.logout();
	}

	/**
	 * <p>
	 * Title: download
	 * </p>
	 * <p>
	 * Description: download a file from remote machine
	 * </p>
	 * 
	 * @param localPath
	 * @param remotePath
	 */
	public void download(String localPath, String remotePath) {
		SSHHelper sshhelper = new SSHHelper();
		sshhelper.login(privateKey, userName, hostname);
		sshhelper.scpFrom(remotePath, localPath);
		sshhelper.logout();
	}

	/**
	 * <p>
	 * Title: exec
	 * </p>
	 * <p>
	 * Description: execute a command in remote machine
	 * </p>
	 * 
	 * @param command
	 * @return
	 */
	public SSHResult exec(String command) {
		SSHHelper sshhelper = new SSHHelper();
		sshhelper.login(privateKey, userName, hostname);
		SSHResult sshResult = sshhelper.exec(command);
		sshhelper.logout();
		return sshResult;
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
	public static void main(String[] args) {
		SSHClient instSSHClient = new SSHClient("170.225.160.15");
		instSSHClient.upload("/tmp/he", "/home/idcuser");
	}

}
