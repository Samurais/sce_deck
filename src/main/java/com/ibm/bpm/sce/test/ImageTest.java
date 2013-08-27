package com.ibm.bpm.sce.test;

import java.io.FileNotFoundException;
import java.util.Map;

import com.ibm.bpm.sce.exceptions.ImageBuilderException;
import com.ibm.bpm.sce.imagebuilder.AbstractWindowsImageBuilder;
import com.ibm.sce.deck.exceptions.ManagedImageException;
import com.ibm.sce.deck.exceptions.ManagedInstanceException;
import com.ibm.sce.deck.resources.ManagedImage;
import com.ibm.sce.deck.tools.LogHelper;

/**
 * BPM image test entrance
 * 
 * @author hqghuang@cn.ibm.com
 */
public class ImageTest extends AbstractWindowsImageBuilder {

	private String bpmImageId;

	/**
	 * <p>
	 * Title: deploy an image and test the instance
	 * </p>
	 * <p>
	 * Description: define the instance and access it by SSH
	 * </p>
	 * 
	 * @param bpmImageId
	 * @param bpmImageLoc
	 * @param bpmInstanceName
	 * @param instType
	 * @param swRepoHost
	 * @param parms
	 * @throws ImageBuilderException
	 */
	public ImageTest(String bpmImageId, String bpmImageLoc,
			String bpmInstanceName, String instType, String swRepoHost,
			Map parms) throws ImageBuilderException {
		super(bpmImageId, bpmImageLoc, bpmInstanceName, instType, swRepoHost,
				parms);
		this.bpmImageId = bpmImageId;
	}

	/**
	 * <p>
	 * Title: runAutoTest
	 * </p>
	 * <p>
	 * Description: runAutoTest
	 * </p>
	 * 
	 * @param keyFile
	 * @param sshUser
	 * @param bpmuser
	 * @param bpmpwd
	 * @param subject
	 * @return
	 */
	public String runAutoTest(String keyFile, String sshUser, String bpmuser,
			String bpmpwd, String subject) {
		LogHelper.printInfo("BPM Image id is: " + bpmImageId);
		ManagedImage bldImage = null;

		// provision a instance from the BPM image
		deployBaseInstance();

		String instanceId = getMgrInst().getId();
		String instanceName = getMgrInst().getName();
		String instanceIp = getMgrInst().getIPAddr();
		LogHelper.printInfo("instanceId: " + instanceId);
		LogHelper.printInfo("instanceName: " + instanceName);
		LogHelper.printInfo("instanceIp: " + instanceIp);

		// Auto test the BPM instance
		InstanceTest instance = new InstanceTest(keyFile, sshUser, instanceIp,
				bpmuser, bpmpwd);
		instance.test(instanceIp);
		instance.notify(Constants.MAIL_TEAM_LIST, subject);
		// recapture the BPM image, for second-handle BPM test
		try {
			// this will upload the new autolog.bat to the instance
			uploadInstallationScripts();
		} catch (FileNotFoundException e1) {
			e1.printStackTrace();
		} catch (ManagedInstanceException e1) {
			e1.printStackTrace();
		}
		try {
			if (beforeSavingWindowsInst2Image()) {
				shutdownInst();
				bldImage = capture("DevBPMv85WindowsAtlas"
						+ Long.toString(System.currentTimeMillis()));
				return bldImage.getImage().getID();
			}
		} catch (ManagedImageException e) {
			LogHelper.printInfo(e.getMessage());
			e.printStackTrace();
		} catch (ManagedInstanceException e) {
			LogHelper.printInfo(e.getMessage());
			e.printStackTrace();
		}
		return null;
	}

	@Override
	public ManagedImage build() {
		return null;
	}

}
