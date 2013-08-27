package com.ibm.bpm.sce.imagebuilder;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.util.Date;
import java.util.Iterator;
import java.util.Map;

import com.ibm.bpm.sce.exceptions.ImageBuilderException;
import com.ibm.cloud.api.rest.client.bean.Image;
import com.ibm.json.java.JSONObject;
import com.ibm.sce.deck.exceptions.ManagedImageException;
import com.ibm.sce.deck.exceptions.ManagedInstanceException;
import com.ibm.sce.deck.exceptions.SCEClientException;
import com.ibm.sce.deck.resources.ManagedImage;
import com.ibm.sce.deck.resources.ManagedInstance;
import com.ibm.sce.deck.tools.ManagedLogger;
import com.ibm.sce.deck.tools.ManagedProperties;
import com.ibm.sce.deck.tools.ZipHandler;

public abstract class AbstractWindowsImageBuilder {

	private static final String STATUS_PROVISION = "provision_base_image";
	private static final String STATUS_UPLOAD = "upload_files";
	private static final String STATUS_EXEC_CMD = "execute_commands";
	private static final String CAPTURE_IMAGE = "capture_instance";
	private String swRepoHost;
	private String bpmImageId;
	private String bpmImageLoc;
	private String bpmInstanceName;
	private String instType;
	private String status;
	private String instUser;
	private String instPassword;
	private ManagedInstance mgrInst;
	private Map<String, String> parms;

	protected ManagedLogger mgrLogger = ManagedLogger.getInstance();
	protected static ManagedProperties mgrProps = new ManagedProperties();
	protected static final String className = AbstractWindowsImageBuilder.class
			.getName();
	private static String installerInRepoPath = "/home/idcuser/installers";
	private static String installer2InstancePath = "/cygdrive/c/installer";

	/**
	 * <p>
	 * Title: AbstractImageBuilder
	 * </p>
	 * <p>
	 * Description: provide a set of methods to enable build a image
	 * automaticly.
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
	public AbstractWindowsImageBuilder(final String bpmImageId,
			final String bpmImageLoc, final String bpmInstanceName,
			final String instType, final String swRepoHost,
			final Map<String, String> parms) throws ImageBuilderException {
		// check parms
		if ((!parms.containsKey("UserName"))
				|| (!parms.containsKey("Password"))) {
			throw new ImageBuilderException(
					ImageBuilderException.PARAMS_NOT_VALID);
		} else {
			if (((String) parms.get("UserName")).isEmpty()
					|| ((String) parms.get("Password")).isEmpty()) {
				throw new ImageBuilderException(
						ImageBuilderException.PARAMS_NOT_VALID);
			} else {
				setInstUser((String) parms.get("UserName"));
				setInstPassword((String) parms.get("Password"));
			}
		}
		setBpmImageId(bpmImageId);
		setBpmImageLoc(bpmImageLoc);
		setBpmInstanceName(bpmInstanceName);
		setInstType(instType);
		setSwRepoHost(swRepoHost);
		setParms(parms);
		// mgrInst = new ManagedInstance(getBpmInstanceName(), getInstType(),
		// getBpmImageId(), getBpmImageLoc(), "SCEDeck", parms);
		mgrInst = new ManagedInstance(getBpmInstanceName(), getInstType(),
				getBpmImageId(), getBpmImageLoc(), null, parms);
	}

	/**
	 * <p>
	 * Title:
	 * </p>
	 * <p>
	 * Description:
	 * </p>
	 * 
	 * @param instanceId
	 * @param swRepoHost
	 * @param instUser
	 * @param instPassword
	 * @throws ManagedInstanceException
	 */
	public AbstractWindowsImageBuilder(final String instanceId,
			final String swRepoHost, final String instUser,
			final String instPassword) throws ManagedInstanceException {
		mgrInst = new ManagedInstance(instanceId);
		setSwRepoHost(swRepoHost);
		setInstUser(instUser);
		setInstPassword(instPassword);
	}

	/**
	 * <p>
	 * Title: deployBaseInstance
	 * </p>
	 * <p>
	 * Description: deploy an instance from base image, return when the instance
	 * is ready for using
	 * </p>
	 */
	public void deployBaseInstance() {
		if (mgrInst.getIPAddr() == null) {
			try {
				mgrInst.deploy();
				mgrInst.waitForActive();
			} catch (ManagedInstanceException e) {
				e.printStackTrace();
			}
		}

	}

	/**
	 * <p>
	 * Title: uploadBPMInstaller2BaseInstance
	 * </p>
	 * <p>
	 * Description: upload bpm installer into the instance,should be called
	 * after deployBaseImage return. This method return after the file is
	 * downloaded successfully.
	 * </p>
	 * 
	 * @param remoteFilePath
	 *            the absolute path in the bpm installer host machine
	 * @param localFilePath
	 *            the absolute file path in the base instance
	 * @return true if the file is transfered successfully, false if the
	 *         instance does not exist, ssh connection is failed or the file
	 *         does not exist.
	 */
	protected boolean uploadBPMInstaller2BaseInstance(String remoteFilePath,
			String localFilePath) {
		if (mgrInst.getIPAddr() != null) {
			return mgrInst.scpFrom(getSwRepoHost(), remoteFilePath,
					localFilePath);
		}
		return false;
	}

	/**
	 * <p>
	 * Title: captureBaseInstance
	 * </p>
	 * <p>
	 * Description: save the instance to an image
	 * </p>
	 * 
	 * @param name
	 *            image name in sce is unique ,better add timestamp in the name
	 * @param description
	 *            add a simple description about what this image has .
	 * @return image that is newly created
	 * @throws ManagedInstanceException
	 */
	protected Image captureBaseInstance(String name, String description)
			throws ManagedInstanceException {
		Image img = null;
		if (mgrInst.getIPAddr() != null) {
			img = mgrInst.capture(name, description);
		}
		return img;

	}

	/**
	 * <p>
	 * Title: uploadLocalFile2BaseInstance
	 * </p>
	 * <p>
	 * Description: upload local file to Base Instance
	 * </p>
	 * 
	 * @param remoteFilePath
	 * @param localFilePath
	 */
	protected void uploadLocalFile2BaseInstance(String remoteFilePath,
			String localFilePath) {
		if (mgrInst.getIPAddr() != null) {
			mgrInst.upload(localFilePath, remoteFilePath);
		}

	}

	/**
	 * <p>
	 * Title: build
	 * </p>
	 * <p>
	 * Description: implemented by child class. The core logic to customize an
	 * instance is done here.Mostly it chains others in Image Builder.
	 * </p>
	 * 
	 * @return
	 */
	public abstract ManagedImage build();

	/**
	 * <p>
	 * Title: waitForFileSignal
	 * </p>
	 * <p>
	 * Description: monitor a file in the remote instance , if the file exist ,
	 * method exit.
	 * </p>
	 * 
	 * @param fileSignal
	 */
	public void waitForFileSignal(final String fileSignal) {
		boolean isDone = false;
		while (!isDone) {
			try {
				isDone = getMgrInst().isPathExist(fileSignal);
				Thread.sleep(1000 * 60 * 5);
			} catch (InterruptedException e) {
				e.printStackTrace();
			}
		}

	}

	/**
	 * <p>
	 * Title: upload
	 * </p>
	 * <p>
	 * Description: upload files into instance
	 * </p>
	 * 
	 * @throws FileNotFoundException
	 */
	@SuppressWarnings("unchecked")
	protected void uploadInstallationPackages() throws FileNotFoundException {
		/*
		 * make sure the target file path exist in Instance
		 */
		if (!getMgrInst().isPathExist(installer2InstancePath)) {
			try {
				getMgrInst().exec("mkdir -p " + installer2InstancePath);
			} catch (ManagedInstanceException e) {
				mgrLogger.err(className, e.getMessage());
			}
		}

		// scp files from BPM Installation Pkg host to Instance

		JSONObject installationPkgs = new JSONObject();
		/**
		 * tools
		 */
		installationPkgs.put(installerInRepoPath + "/Tools/Unzip/unzip.exe",
				installer2InstancePath);
		installationPkgs.put(installerInRepoPath + "/Tools/Unzip/7za.exe",
				installer2InstancePath);
		/**
		 * bpm packages
		 */
		installationPkgs.put(installerInRepoPath
				+ "/BPMv85/bpmAll.dvd.8500.windows.x86.disk1.zip",
				installer2InstancePath);
		installationPkgs.put(installerInRepoPath
				+ "/BPMv85/bpmAll.dvd.8500.windows.x86.disk2.zip",
				installer2InstancePath);
		installationPkgs.put(installerInRepoPath
				+ "/BPMv85/bpmAll.dvd.8500.windows.x86.disk3.zip",
				installer2InstancePath);
		installationPkgs.put(installerInRepoPath
				+ "/BPMv85/ProcessDesigner8500.zip", installer2InstancePath);
		installationPkgs.put(installerInRepoPath + "/BPMv85/BPM8500Ifixes.zip",
				installer2InstancePath);
		/**
		 * DB2
		 */
		installationPkgs.put(installerInRepoPath
				+ "/DB2v10/DB2_ESE_10.1_fp2_Win_x86-64.zip",
				installer2InstancePath);
		/**
		 * iid packages
		 */

		installationPkgs.put(installerInRepoPath
				+ "/IIDv85/iid.dvd.8500.disk1.zip", installer2InstancePath);
		installationPkgs.put(installerInRepoPath
				+ "/IIDv85/iid.dvd.8500.disk2.zip", installer2InstancePath);
		installationPkgs.put(installerInRepoPath
				+ "/IIDv85/iid.dvd.8500.disk3.zip", installer2InstancePath);
		installationPkgs.put(installerInRepoPath
				+ "/IIDv85/iid.dvd.8500.windows.x86.disk1.zip",
				installer2InstancePath);
		installationPkgs.put(installerInRepoPath
				+ "/IIDv85/iid.dvd.8500.windows.x86.disk2.zip",
				installer2InstancePath);
		installationPkgs.put(installerInRepoPath
				+ "/IIDv85/iid.dvd.8500.windows.x86.disk3.zip",
				installer2InstancePath);
		/*
		 * upload files into the existing instance
		 */
		mgrLogger.info(className, "upload bpm installation pkgs");
		for (Iterator iter = installationPkgs.keySet().iterator(); iter
				.hasNext();) {
			String source = new String(iter.next().toString());
			String target = new String((String) installationPkgs.get(source));
			mgrLogger.info(className, "upload " + source + " to " + target);
			uploadBPMInstaller2BaseInstance(source, target);
		}
	}

	/**
	 * <p>
	 * Title: uploadInstallationScripts
	 * </p>
	 * <p>
	 * Description:
	 * </p>
	 * 
	 * @throws FileNotFoundException
	 * @throws ManagedInstanceException
	 */
	public void uploadInstallationScripts() throws FileNotFoundException,
			ManagedInstanceException {
		/*
		 * make sure the target file path exist in Instance
		 */
		if (!getMgrInst().isPathExist(installer2InstancePath)) {
			try {
				getMgrInst().exec("mkdir -p " + installer2InstancePath);
			} catch (ManagedInstanceException e) {
				mgrLogger.err(className, e.getMessage());
			}
		}

		/*
		 * upload installation scripts into instance
		 */
		String installationScripts = mgrProps
				.getProperty("bpm_installation_scripts");
		// clean old zip file
		File f = new File(installationScripts);
		String installationScriptsZip = f.getName() + ".zip";
		File zipf = new File(installationScriptsZip);
		if (zipf.exists()) {
			zipf.delete();
		}
		// package zip -zipf
		ZipHandler zip = new ZipHandler();
		zip.doZip(installationScripts);

		if (zipf.exists()) {
			mgrLogger.info(className, "upload bpm installation scripts");
			uploadLocalFile2BaseInstance(installer2InstancePath,
					installationScriptsZip);
			zipf.delete();
			mgrLogger.info(className,
					"finish uploading bpm installation scripts");
			// TODO use parameters , currently the script file is hard code
			mgrLogger
					.debug(className,
							"extract the installation scripts to C:\\installer\\Script .");
			getMgrInst().exec(
					"cd / && /cygdrive/c/IBM/BPM/v8.5/java/bin/jar.exe -xvf  "
							+ "C:/installer/" + installationScriptsZip);
			getMgrInst().exec(
					"mv /cygdrive/c/cygwin/bpm_windows_image/installer  "
							+ installer2InstancePath + "/Script");
			getMgrInst().exec(
					"cd " + installer2InstancePath
							+ "/Script&&chmod -R 777 `pwd`");
			mgrLogger.debug(className,
					"extracting the installation scripts is done.");
			mgrLogger.debug(className,
					"copy kms_license and autolog.bat to C:\\bat .");
			getMgrInst().exec(
					"cp " + installer2InstancePath
							+ "/Script/activation_kms.bat /cygdrive/c/bat");
			getMgrInst().exec(
					"cp " + installer2InstancePath
							+ "/Script/autolog.bat /cygdrive/c/bat");
			mgrLogger
					.debug(className, "copy remove_cygwin.bat to C:\\cygwin .");
			getMgrInst().exec(
					"cp " + installer2InstancePath
							+ "/Script/remove_cygwin.bat /cygdrive/c/cygwin");

		} else {
			throw new FileNotFoundException(installationScriptsZip);
		}

	}

	/**
	 * <p>
	 * Title: cleanDevEnvironment
	 * </p>
	 * <p>
	 * Description: the instance has cygwin and ssh service , these tools are
	 * used during development phase.Before the image is deliveried to
	 * customers, these files and service should be removed. RTC Defect -148580:
	 * BPM85SCEFVT: (Automation) Clean the legacy useless asset files and dev
	 * files for BPM image
	 * </p>
	 * 
	 * @throws ManagedInstanceException
	 */
	protected void cleanDevEnvironment() throws ManagedInstanceException {
		mgrLogger.info(className, "run /cygdrive/c/cygwin/remove_cygwin.bat.");
		getMgrInst().exec("nohup /cygdrive/c/cygwin/remove_cygwin.bat &");
		waitForFileSignal("/cygdrive/c/cygwin/cygwin_rm.done");
		mgrLogger.info(className, "shut down in 600 seconds");
		getMgrInst().exec(
				"nohup /cygdrive/c/Windows/system32/shutdown.exe /t 600 /s &");
		mgrLogger.info(className, "set firewall and delete folders");
		getMgrInst()
				.exec(
						"nohup netsh advfirewall firewall delete rule name=\"tcp\" ; rm -rf --no-preserve-root /cygdrive/c/cygwin/ &");
		try {
			Thread.sleep(1000 * 1000);

		} catch (InterruptedException e) {
			mgrLogger.info(className, e.getMessage());
		}
	}

	/**
	 * <p>
	 * Title: shutdownInst
	 * </p>
	 * <p>
	 * Description: shut down machine
	 * </p>
	 * 
	 * @throws ManagedInstanceException
	 */
	protected void shutdownInst() throws ManagedInstanceException {
		mgrLogger.info(className, "shutdown the instance");
		getMgrInst().exec("/cygdrive/c/Windows/system32/shutdown.exe /p");
		mgrLogger.debug(className, "wait until the instance stopped");
		try {
			Thread.sleep(60 * 1000 * 5);
		} catch (Exception e) {
			mgrLogger.debug(className, e.getMessage());
		}
		mgrLogger.debug(className, "the instance stopped successfully.");
	}

	/**
	 * <p>
	 * Title: beforeSavingWindowsInst2Image
	 * </p>
	 * <p>
	 * Description: do some tasks before saving windows instance, or the image
	 * would not work well.
	 * </p>
	 */
	protected boolean beforeSavingWindowsInst2Image() {
		boolean succ = false;
		try {
			/*
			 * sync time
			 */
			mgrLogger.info(className, "Sync Time");
			mgrLogger.info(className, getMgrInst()
					.exec("w32tm /resync /nowait").getOut());
			Thread.sleep(1000 * 60);
			/*
			 * call slmgr sliently in windows instance
			 */
			mgrLogger.info(className, "run slmgr to activate ms license");
			getMgrInst().exec("/cygdrive/c/bat/activation_kms.bat");
			Thread.sleep(1000 * 60);
			/*
			 * run autolog
			 */
			mgrLogger.info(className, "run AUTOLOG.BAT");
			getMgrInst().exec(
					"nohup /cygdrive/c/bat/autolog.bat " + getInstPassword()
							+ " &");
			boolean isDone = false;
			while (!isDone) {
				Thread.sleep(60000 * 2);
				if (getMgrInst().isPathExist("/cygdrive/c/cygwin/autolog.done")) {
					isDone = true;
				}
				if (getMgrInst().isPathExist("/cygdrive/c/cygwin/autolog.fail")) {
					mgrLogger
							.err(
									className,
									"can not execute autolog in windows instance , maybe administrator password is wrong.");
					throw new ManagedInstanceException(
							ManagedInstanceException.FAIL_TO_RUN_AUTOLOG);
				}
			}
			if (isDone == true) {
				mgrLogger.debug(className, "autolog finishes successfully.");
				getMgrInst().exec("rm -rf /cygdrive/c/bat/autolog.bat");
			}
			succ = isDone;
		} catch (ManagedInstanceException e) {
			succ = false;
			e.printStackTrace();
		} catch (InterruptedException e) {
			succ = false;
			e.printStackTrace();
		}
		return succ;
	}

	/**
	 * <p>
	 * Title: capture
	 * </p>
	 * <p>
	 * Description: save the instance as an image
	 * </p>
	 * 
	 * @return
	 * @throws ManagedInstanceException
	 * @throws ManagedImageException
	 * @return ManagedImage
	 * @see ManagedImage
	 */
	protected ManagedImage capture(String newImageName)
			throws ManagedInstanceException, ManagedImageException {
		// capture the instance
		mgrLogger.debug(className, "begin to capture the image - "
				+ newImageName);
		captureBaseInstance(newImageName, mgrProps
				.getProperty("sce_account_username")
				+ "#Build from SCE Deck#" + ((new Date()).toString()));
		ManagedImage mgrImg = new ManagedImage(newImageName);
		mgrLogger.debug(className, "wait for the image to be available - id:"
				+ mgrImg.getImage().getID());
		mgrImg.waitForAvailable();
		/*
		 * handle the image content , community, owners
		 */
		try {
			mgrLogger.info(className, "modify the image properties and assets");
			String asserFolder = mgrProps
					.getProperty("bpm_image_asset_content");
			String bpmOwner = mgrProps.getProperty("bpm_image_developers");
			BPMImageHandler bpmImgHandler = new BPMImageHandler(mgrImg,
					bpmOwner, asserFolder);
			bpmImgHandler.process();
		} catch (ManagedImageException e1) {
			e1.printStackTrace();
		} catch (FileNotFoundException e) {
			e.printStackTrace();
		} catch (IOException e) {
			e.printStackTrace();
		} catch (SCEClientException e) {
			e.printStackTrace();
		}
		mgrLogger.debug(className, "Image is available now - id:"
				+ mgrImg.getImage().getID());
		return mgrImg;
	}

	/**
	 * <p>
	 * Title: postInstallMiddles
	 * </p>
	 * <p>
	 * Description: do the tasks after installing middlewares
	 * </p>
	 */
	protected void postInstallMiddlewares() {
		try {
			mgrLogger
					.info(className,
							"run tasks - post_install_middlewares.bat after installing bpm,db2,iid.");
			getMgrInst()
					.exec(
							"nohup /cygdrive/c/installer/Script/post_install_middlewares.bat &");
			waitForFileSignal("/cygdrive/c/cygwin/post_install.done");
			mgrLogger
					.info(className,
							"finish running /cygdrive/c/installer/Script/post_install_middlewares.bat.");
		} catch (ManagedInstanceException e) {
			mgrLogger.err(className, e.toString());
		}

	}

	/**
	 * <p>
	 * Title: getSwRepoHost
	 * </p>
	 * <p>
	 * Description: return the machine ip address that host Installation
	 * Packages
	 * </p>
	 * 
	 * @return
	 */
	public String getSwRepoHost() {
		return swRepoHost;
	}

	public String getBpmImageId() {
		return bpmImageId;
	}

	public String getBpmImageLoc() {
		return bpmImageLoc;
	}

	public String getBpmInstanceName() {
		return bpmInstanceName;
	}

	public String getInstType() {
		return instType;
	}

	public String getStatus() {
		return status;
	}

	public ManagedInstance getMgrInst() {
		return mgrInst;
	}

	public Map<String, String> getParms() {
		return parms;
	}

	public void setSwRepoHost(String swRepoHost) {
		this.swRepoHost = swRepoHost;
	}

	public void setBpmImageId(String bpmImageId) {
		this.bpmImageId = bpmImageId;
	}

	public void setBpmImageLoc(String bpmImageLoc) {
		this.bpmImageLoc = bpmImageLoc;
	}

	public void setBpmInstanceName(String bpmInstanceName) {
		this.bpmInstanceName = bpmInstanceName;
	}

	public void setInstType(String instType) {
		this.instType = instType;
	}

	public void setParms(Map<String, String> parms) {
		this.parms = parms;
	}

	public String getInstUser() {
		return instUser;
	}

	public String getInstPassword() {
		return instPassword;
	}

	public void setInstUser(String instUser) {
		this.instUser = instUser;
	}

	public void setInstPassword(String instPassword) {
		this.instPassword = instPassword;
	}

}
