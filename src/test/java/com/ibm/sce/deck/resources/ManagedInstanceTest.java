package com.ibm.sce.deck.resources;

import java.io.File;
import java.util.Date;
import java.util.HashMap;
import java.util.Map;

import org.junit.FixMethodOrder;
import org.junit.runners.MethodSorters;

import junit.framework.TestCase;

import com.ibm.cloud.api.rest.client.bean.Image;
import com.ibm.sce.deck.exceptions.ManagedImageException;
import com.ibm.sce.deck.exceptions.ManagedInstanceException;
import com.ibm.sce.deck.resources.ManagedImage;
import com.ibm.sce.deck.resources.ManagedInstance;
import com.ibm.sce.deck.resources.ManagedLocation;
import com.ibm.sce.deck.tools.ManagedProperties;

//Running test cases in order of method names in ascending order
/**
 * @author Hai Liang BJ Wang/China/IBM Jul 15, 2013
 */
@FixMethodOrder(MethodSorters.NAME_ASCENDING)
public class ManagedInstanceTest extends TestCase {

	ManagedProperties managedProps = new ManagedProperties();

	/**
	 * Red Hat v6.4 x86_64 Image ID in Singapore
	 */
	private static String redHatImageID = "20025211";
	private static String instType = "COP64.2/4096/60";
	private static String instName = "Automatic";
	// private static String instID="440835";
	private static String instID;
	private static String localFile = "src/test/resources/scripts/test_upload.sh";
	private static String localDownloadFile = "/tmp/downloadFile";
	private static String remoteAbsolutePath = "~/test_upload.sh";
	private static String captureImageName = "AutomaticTestImage";
	private static boolean is_failed = false;

	public void setUp() throws Exception {
	}

	public void tearDown() throws Exception {
	}

	/**
	 * <p>
	 * Title: testProvision
	 * </p>
	 * <p>
	 * Description: test deploy and waitForActive in ManagedInstance class
	 * .ManagedInstance <b>deploy</b> method provision an instance
	 * <b>waitForActive</b> hang until the instance is in active status
	 * </p>
	 */
	public void testaProvision() {
		try {
			Map parms = new HashMap<String, String>();
			ManagedInstance managedInst = new ManagedInstance(instName,
					instType, redHatImageID, ManagedLocation.SINGAPORE.getId(),
					managedProps.getProperty("sce_ssh_key"), parms);
			managedInst.deploy();
			instID = managedInst.getId();
			assertTrue(managedInst.waitForActive());
		} catch (Exception e) {
			is_failed = true;
			assertTrue(false);
		}
	}

	/**
	 * <p>
	 * Title: testbRename
	 * </p>
	 * <p>
	 * Description: rename the instance after it is active
	 * </p>
	 */
	public void testbRename() {
		if (!is_failed) {
			try {
				ManagedInstance managedInst = new ManagedInstance(this.instID);
				managedInst.resetName(instName + "reset");
				managedInst.updateStatus();
				assertTrue(managedInst.getName().equals(instName + "reset"));
			} catch (ManagedInstanceException e) {
				System.out.println(e.getType());
			}
		} else {
			// failed due to previous failed case
			assertTrue(false);
		}
	}

	/**
	 * <p>
	 * Title: testbExcmd
	 * </p>
	 * <p>
	 * Description: execute a shell command in the instance and reture the
	 * results
	 * </p>
	 */
	public void testbExcmd() {
		if (!is_failed) {
			try {
				ManagedInstance managedInst = new ManagedInstance(this.instID);
				String sshr = managedInst.exec("ls /").getOut();
				assertTrue(sshr.contains("var"));
			} catch (ManagedInstanceException e) {
				System.out.println(e.getType());
			}
		} else {
			// failed due to previous failed case
			assertTrue(false);
		}
	}

	/**
	 * <p>
	 * Title: testbUploadFile
	 * </p>
	 * <p>
	 * Description:upload a file into the instance
	 * </p>
	 */
	public void testcUploadFile() {
		if (!is_failed) {
			ManagedInstance managedInst;
			try {
				managedInst = new ManagedInstance(this.instID);
				managedInst.upload(localFile, remoteAbsolutePath);
				assertTrue(managedInst.isPathExist(remoteAbsolutePath));
			} catch (ManagedInstanceException e) {
				System.out.println(e.getType());
			}
		} else {
			// failed due to previous failed case
			assertTrue(false);
		}
	}

	/**
	 * <p>
	 * Title: testcDownloadFile
	 * </p>
	 * <p>
	 * Description: download a file to local from the remote instance
	 * </p>
	 */
	public void testdDownloadFile() {
		if (!is_failed) {
			ManagedInstance managedInst;
			try {
				managedInst = new ManagedInstance(this.instID);
				managedInst.download(localDownloadFile, remoteAbsolutePath);
				assertTrue(new File(localDownloadFile).exists());
			} catch (ManagedInstanceException e) {
				System.out.println(e.getType());
			}
		} else {
			// failed due to previous failed case
			assertTrue(false);
		}
	}

	/**
	 * <p>
	 * Title: test download file from vm that host bpm installer
	 * </p>
	 * <p>
	 * Description:vm that host BPM Installer can be logined using key in
	 * managed_sce.properties
	 * </p>
	 */
	public void testeScpFrom() {
		if (!is_failed) {
			ManagedInstance managedInst;
			try {
				managedInst = new ManagedInstance(this.instID);
				String remoteIP = new String("170.225.163.85");
				String remoteFP = new String("/tmp/sce-dev");
				String localFP = new String("/tmp/test");
				managedInst.scpFrom(remoteIP, remoteFP, localFP);
				assertTrue(managedInst.isPathExist(localFP));
			} catch (ManagedInstanceException e) {
				System.out.println(e.getType());
			}
		} else {
			// failed due to previous failed case
			assertTrue(false);
		}
	}

	/**
	 * <p>
	 * Title: testfCaptureImage
	 * </p>
	 * <p>
	 * Description: save an instance to an image
	 * </p>
	 */
	public void testfCaptureImage() {
		if (!is_failed) {
			ManagedInstance managedInst;
			try {

				String imgName = this.captureImageName
						+ (new Date()).toString();
				managedInst = new ManagedInstance(this.instID);
				Image img = managedInst.capture(imgName,
						"test ManagedInstance.capture()");
				assertTrue(img.getName().equals(imgName));
				ManagedImage mgImg;
				try {
					mgImg = new ManagedImage(Integer.parseInt(img.getID()));
					mgImg.waitForAvailable();
					mgImg.delete();
				} catch (NumberFormatException e) {
					e.printStackTrace();
				} catch (ManagedImageException e) {
					e.printStackTrace();
				}
			} catch (ManagedInstanceException e) {
				System.out.println(e.getType());
			}
		} else {
			// failed due to previous failed case
			assertTrue(false);
		}
	}

	/**
	 * <p>
	 * Title: testeDestroy
	 * </p>
	 * <p>
	 * Description: destroy the instance
	 * </p>
	 */
	public void testgDestroy() {
		if (!is_failed) {
			try {
				ManagedInstance managedInst = new ManagedInstance(this.instID);
				managedInst.destory();
				assertTrue(true);
			} catch (ManagedInstanceException e) {
				assertTrue(false);
			}
		} else {
			assertTrue(false);
		}
	}

}
