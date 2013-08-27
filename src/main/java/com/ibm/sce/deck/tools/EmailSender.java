package com.ibm.sce.deck.tools;

import java.io.BufferedReader;
import java.io.StringReader;
import java.util.Vector;

import javax.mail.MessagingException;
import javax.mail.Session;
import javax.mail.Transport;
import javax.mail.internet.InternetAddress;
import javax.mail.internet.MimeMessage;

import com.ibm.bpm.sce.test.Constants;

/**
 * Email sender, support HTML
 * 
 * @author hqghuang@cn.ibm.com
 */
public class EmailSender {

	private String mailTitle;

	public EmailSender(String mailTitle) {
		this.mailTitle = mailTitle;
	}

	/**
	 * <p>
	 * Title: sendResult
	 * </p>
	 * <p>
	 * Description: Send result by email
	 * </p>
	 * 
	 * @param mailTo
	 * @param resultLog
	 */
	public void sendResult(String mailTo, String resultLog) {
		String smtpHost = Constants.SMTPHOST;
		String from = Constants.MAIL_FROM;
		String password = Constants.MAIL_PWD;
		String subject = Constants.MAIL_SUBJECT + mailTitle;
		StringBuffer theMessage = generateMailBody(retrieveResult(resultLog));
		LogHelper.printInfo("mailTo: " + mailTo);
		LogHelper.printInfo("continue sending email...");
		try {
			sendMessage(smtpHost, from, mailTo, subject, theMessage.toString(),
					password);
		} catch (javax.mail.MessagingException exc) {
			exc.printStackTrace();
			LogHelper.printInfo(exc.getMessage());
		} catch (java.io.UnsupportedEncodingException exc) {
			exc.printStackTrace();
			LogHelper.printInfo(exc.getMessage());
		}
	}

	/**
	 * <p>
	 * Title: sendMessage
	 * </p>
	 * <p>
	 * Description: sendMessage
	 * </p>
	 * 
	 * @param smtpHost
	 * @param from
	 * @param mailTo
	 * @param subject
	 * @param messageText
	 * @param password
	 * @throws MessagingException
	 * @throws java.io.UnsupportedEncodingException
	 */
	public void sendMessage(String smtpHost, String from, String mailTo,
			String subject, String messageText, String password)
			throws MessagingException, java.io.UnsupportedEncodingException {

		// Step 1: Configure the mail session
		java.util.Properties props = new java.util.Properties();
		props.setProperty("mail.smtp.auth", "true");
		props.setProperty("mail.smtp.host", smtpHost);
		props.put("mail.transport.protocol", "smtp");
		props.setProperty("mail.smtp.socketFactory.class",
				"javax.net.ssl.SSLSocketFactory");
		props.setProperty("mail.smtp.socketFactory.fallback", "false");
		props.setProperty("mail.smtp.port", "465");
		props.setProperty("mail.smtp.socketFactory.port", "465");
		Session mailSession = Session.getDefaultInstance(props);
		mailSession.setDebug(false);

		// Step 2: Construct the message
		InternetAddress fromAddress = new InternetAddress(from);
		MimeMessage testMessage = new MimeMessage(mailSession);
		testMessage.setFrom(fromAddress);
		InternetAddress[] tos = null;
		String[] receivers = mailTo.split(";");
		if (receivers != null) {
			tos = new InternetAddress[receivers.length];
			for (int i = 0; i < receivers.length; i++) {
				tos[i] = new InternetAddress(receivers[i]);
			}
		}
		// InternetAddress toAddr = new InternetAddress(to);
		testMessage.setRecipients(javax.mail.Message.RecipientType.TO, tos);
		testMessage.setSentDate(new java.util.Date());
		testMessage.setSubject(subject);
		testMessage.setContent(messageText, "text/html;charset=utf-8");

		// Step 3: Now send the message
		Transport transport = mailSession.getTransport("smtp");
		transport.connect(smtpHost, from, password);
		transport.sendMessage(testMessage, testMessage.getAllRecipients());
		transport.close();
		LogHelper.printInfo("Email send success!");
	}

	/**
	 * <p>
	 * Title: retrieveResult
	 * </p>
	 * <p>
	 * Description: retrieve result
	 * </p>
	 * 
	 * @param resultLog
	 * @return
	 */
	private Vector<Vector<String>> retrieveResult(String resultLog) {
		try {
			String line = "";
			Vector<Vector<String>> doubleV = new Vector<Vector<String>>();
			Vector<String> vectory = null;
			BufferedReader input = new BufferedReader(new StringReader(
					resultLog));
			while ((line = input.readLine()) != null) {
				if (line.startsWith("[")) {
					if (vectory != null) {
						doubleV.add(vectory);
					}
					vectory = new Vector<String>();
					String[] head = line.split("]");
					vectory.add(head[0] + "]");
					vectory.add(head[1]);
				} else {
					if (vectory != null) {
						vectory.add(line);
					}
				}
			}
			// include the last one
			if (vectory != null) {
				doubleV.add(vectory);
			}
			input.close();
			return doubleV;
		} catch (Exception e) {
			e.printStackTrace();
		}
		return null;
	}

	/**
	 * <p>
	 * Title: generateMailBody
	 * </p>
	 * <p>
	 * Description: generate mail body
	 * </p>
	 * 
	 * @param doubleV
	 * @return
	 */
	private StringBuffer generateMailBody(Vector<Vector<String>> doubleV) {
		StringBuffer theMessage = new StringBuffer();
		theMessage
				.append("<br/><p align='center'>------------------------------ Pls don't reply to this ID ----------------------------</p><br/>");
		theMessage
				.append("<table style=\"border:1px solid rgb(146,176,221)\" width=\"1200\" align='center'><tbody>");
		theMessage
				.append("<tr align=\"center\"><td colspan=\"2\"><b>BPM AUTO TEST RESULT</b></td></tr>");
		for (Vector<String> testcase : doubleV) {
			theMessage
					.append("<tr align='center'><td style='width:34%;background:none repeat scroll 0% 0% rgb(226,234,248)' align='center'><b>"
							+ testcase.get(0) + "</b></td>");
			theMessage
					.append("<td style='background:none repeat scroll 0% 0% rgb(226,234,248)' align='left'>");
			for (int i = 1; i < testcase.size(); i++) {
				theMessage.append("&nbsp;&nbsp;"
						+ addFontColor(testcase.get(i)) + "<br/>");
			}
			theMessage.append("</td></tr>");
		}
		theMessage.append("</tbody></table>");
		theMessage.append("<br/><br/><br/>----------------------<br/>");
		theMessage.append("BPM Auto Test Rebot<br/>");
		theMessage.append("IBM CDL BPM Cloud Team<br/>");
		theMessage.append("----------------------<br/><br/><br/>");
		return theMessage;
	}

	/**
	 * <p>
	 * Title: addFontColor
	 * </p>
	 * <p>
	 * Description: add font color
	 * </p>
	 * 
	 * @param line
	 * @return
	 */
	private static String addFontColor(String line) {
		line = line
				.replace("[SUCCESS]", "<font color='green'>[SUCCESS]</font>");
		line = line.replace("[FAILED]", "<font color='red'>[FAILED]</font>");
		line = line.replace("[WARNING]",
				"<font color='#CFB53B'>[WARNING]</font>");
		line = line.replace("FAIL!", "<font color='red'>[FAILED]</font>");
		line = line.replace("ERROR!", "<font color='#CFB53B'>[ERROR]</font>");
		line = line.replace("WARN!", "<font color='#CFB53B'>[WARNING]</font>");
		return line;
	}
	
}
