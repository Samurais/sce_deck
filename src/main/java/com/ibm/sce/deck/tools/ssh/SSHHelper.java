package com.ibm.sce.deck.tools.ssh;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.io.OutputStream;

import com.jcraft.jsch.Channel;
import com.jcraft.jsch.ChannelExec;
import com.jcraft.jsch.JSch;
import com.jcraft.jsch.JSchException;
import com.jcraft.jsch.Session;
import com.jcraft.jsch.UserInfo;

public class SSHHelper {

	JSch jsch = new JSch();

	Session session = null;

	public void login(File priKey, String username, String hostname) {
		try {
			jsch.addIdentity(priKey.getAbsolutePath());
			session = jsch.getSession(username, hostname, 22);
			// username and passphrase will be given via UserInfo interface.
			UserInfo ui = new SSHUserInfo();
			session.setUserInfo(ui);
			session.connect();
		} catch (JSchException e) {
			e.printStackTrace();
			throw new RuntimeException("Failed to login", e);
		}
	}

	public boolean isLoggedIn() {
		if (session != null) {
			return session.isConnected();
		} else {
			return false;
		}
	}

	public void logout() {
		if (isLoggedIn()) {
			session.disconnect();
		}
	}

	/**
	 * SCP a local file to remote file path
	 * 
	 * @param lfile
	 *            local file path
	 * @param rfile
	 *            remote file path
	 */
	public void scpTo(String lfile, String rfile) {
		FileInputStream fis = null;
		try {
			boolean ptimestamp = true;

			// exec 'scp -t rfile' remotely
			String command = "scp " + (ptimestamp ? "-p" : "") + " -t " + rfile;
			Channel channel = session.openChannel("exec");
			((ChannelExec) channel).setCommand(command);
			((ChannelExec) channel).setErrStream(System.err);
			// get I/O streams for remote scp
			OutputStream out = channel.getOutputStream();
			InputStream in = channel.getInputStream();

			channel.connect();

			if (checkAck(in) != 0) {
				throw new RuntimeException("Failed to connect.");
			}

			File _lfile = new File(lfile);
			System.out.println("copying " + lfile + " to " + rfile);
			if (ptimestamp) {
				command = "T " + (_lfile.lastModified() / 1000) + " 0";
				// The access time should be sent here,
				// but it is not accessible with JavaAPI ;-<
				command += (" " + (_lfile.lastModified() / 1000) + " 0\n");
				out.write(command.getBytes());
				out.flush();
				if (checkAck(in) != 0) {
					throw new RuntimeException(
							"Failed to initialize timestamp.");
				}
			}

			// send "C0644 filesize filename", where filename should not include
			// '/'
			long filesize = _lfile.length();
			System.out.println("File size: " + filesize + " byptes, file: "
					+ _lfile.getName());
			command = "C0644 " + filesize + " ";
			if (lfile.lastIndexOf('/') > 0) {
				command += lfile.substring(lfile.lastIndexOf('/') + 1);
			} else {
				command += lfile;
			}
			command += "\n";
			out.write(command.getBytes());
			out.flush();
			if (checkAck(in) != 0) {
				throw new RuntimeException("Failed to initialize filesize.");
			}

			// send a content of lfile
			fis = new FileInputStream(lfile);
			byte[] buf = new byte[1024];
			while (true) {
				int len = fis.read(buf, 0, buf.length);
				if (len <= 0)
					break;
				out.write(buf, 0, len); // out.flush();
				System.out.println("writing " + len + " bytes...");
			}
			fis.close();
			fis = null;
			// send '\0'
			buf[0] = 0;
			out.write(buf, 0, 1);
			out.flush();
			if (checkAck(in) != 0) {
				throw new RuntimeException("Failed to write binary.");
			}
			out.close();
			System.out.println("File " + _lfile.getName() + " writen to "
					+ rfile);
			channel.disconnect();
		} catch (Exception e) {
			e.printStackTrace();
			// prevent thread hung
			this.logout();
			throw new RuntimeException("Failed to scp to", e);
		}
	}

	/**
	 * SCP a remote file to local file path.
	 * 
	 * @param rfile
	 *            remote file path
	 * @param lfile
	 *            local file path
	 */
	public void scpFrom(String rfile, String lfile) {
		String prefix = null;
		if (new File(lfile).isDirectory()) {
			prefix = lfile + File.separator;
		}
		// exec 'scp -f rfile' remotely

		try {
			String command = "scp -f " + rfile;
			Channel channel = session.openChannel("exec");
			((ChannelExec) channel).setCommand(command);
			// get I/O streams for remote scp
			OutputStream out = channel.getOutputStream();
			InputStream in = channel.getInputStream();

			FileOutputStream fos = null;

			channel.connect();

			byte[] buf = new byte[1024];

			// send '\0'
			buf[0] = 0;
			out.write(buf, 0, 1);
			out.flush();

			while (true) {
				int c = checkAck(in);
				if (c != 'C') {
					throw new RuntimeException("Error in initializing SCP.");
				}

				// read '0644 '
				in.read(buf, 0, 5);

				long filesize = 0L;
				while (true) {
					if (in.read(buf, 0, 1) < 0) {
						// error
						break;
					}
					if (buf[0] == ' ')
						break;
					filesize = filesize * 10L + (long) (buf[0] - '0');
				}

				String file = null;
				for (int i = 0;; i++) {
					in.read(buf, i, 1);
					if (buf[i] == (byte) 0x0a) {
						file = new String(buf, 0, i);
						break;
					}
				}
				System.out.println("File size: " + filesize + " byptes, file: "
						+ file);

				// send '\0'
				buf[0] = 0;
				out.write(buf, 0, 1);
				out.flush();

				// read a content of lfile
				fos = new FileOutputStream(prefix == null ? lfile : prefix
						+ file);
				int foo;
				while (true) {
					if (buf.length < filesize)
						foo = buf.length;
					else
						foo = (int) filesize;
					foo = in.read(buf, 0, foo);
					if (foo < 0) {
						// error
						break;
					}
					fos.write(buf, 0, foo);
					filesize -= foo;
					System.out.println(filesize + " bytes left...");
					if (filesize == 0L)
						break;
				}
				fos.close();
				fos = null;

				if (checkAck(in) != 0 && (filesize != 0L)) {
					throw new RuntimeException("Failed to scpFrom.");
				}

				// send '\0'
				buf[0] = 0;
				out.write(buf, 0, 1);
				out.flush();
			}

		} catch (Exception e) {
			this.logout();
		}
	}

	public SSHResult execAsRoot(String command) {
		return this.exec("sudo " + command);
	}

	public SSHResult exec(String command) {

		SSHResult result = new SSHResult();
		try {
			StringBuilder outStr = new StringBuilder();
			StringBuilder errStr = new StringBuilder();
			Channel channel = session.openChannel("exec");
			((ChannelExec) channel).setCommand(command);
			channel.setInputStream(null);
			InputStream err = ((ChannelExec) channel).getErrStream();
			// ((ChannelExec) channel).setErrStream(System.err);
			InputStream in = channel.getInputStream();

			channel.connect();
			System.out.println("Executing command: " + command);
			byte[] tmp = new byte[1024];
			while (true) {
				if (channel.isClosed()) {
					break;
				}
				try {
					Thread.sleep(1000);
				} catch (Exception ee) {
					ee.printStackTrace();
				}
			}
			while (in.available() > 0) {
				int i = in.read(tmp, 0, 1024);
				if (i < 0)
					break;
				String tmpStr = new String(tmp, 0, i);
				outStr.append(tmpStr);
			}

			while (err.available() > 0) {
				int i = err.read(tmp, 0, 1024);
				if (i < 0)
					break;
				// System.out.print(new String(tmp, 0, i));
				String tmpStr = new String(tmp, 0, i);
				errStr.append(tmpStr);
			}
			result.setOut(outStr.toString());
			result.setErr(errStr.toString());
			result.setReturnCode(channel.getExitStatus());
			channel.disconnect();
		} catch (Exception e) {
			e.printStackTrace();
			// prevent thread hung
			this.logout();
			throw new RuntimeException("Failed to exec", e);
		}
		return result;
	}

	static int checkAck(InputStream in) throws Exception {
		int b = in.read();
		// b may be 0 for success,
		// 1 for error,
		// 2 for fatal error,
		// -1
		if (b == 0)
			return b;
		if (b == -1)
			return b;

		if (b == 1 || b == 2) {
			StringBuffer sb = new StringBuffer();
			int c;
			do {
				c = in.read();
				sb.append((char) c);
			} while (c != '\n');
			if (b == 1) { // error
				System.err.print(sb.toString());
			}
			if (b == 2) { // fatal error
				System.err.print(sb.toString());
			}
		}
		return b;
	}

	/**
	 * A sample usage of this tool.
	 * 
	 * @param args
	 */
	public static void main(String[] args) {
		File priKey = new File("test_key_pri_open_ssh.rsa");
		SSHHelper helper = new SSHHelper();
		helper.login(priKey, "virtuser", "172.17.108.221");
		helper.scpTo("scripts/checkServers.py", "/tmp");
		SSHResult result = helper.exec("ls -l /tmp | grep py");
		System.out.println("result:" + result.getOut());
		result = helper
				.execAsRoot("/opt/IBM/BPM/v85/bin/wsadmin.sh -username virtuser -password "
						+ "passw0rd -f /tmp/checkServers.py");
		System.out.println(result.getOut());
		helper.logout();
	}

}
