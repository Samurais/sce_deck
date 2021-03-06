package com.ibm.bpm.sce.imagebuilder;

import java.io.FileNotFoundException;
import java.util.Map;

import com.ibm.bpm.sce.exceptions.ImageBuilderException;
import com.ibm.sce.deck.exceptions.ManagedImageException;
import com.ibm.sce.deck.exceptions.ManagedInstanceException;
import com.ibm.sce.deck.resources.ManagedImage;

/**
 * @author Hai Liang BJ Wang/China/IBM Jul 18, 2013
 */
public class DevWindowsImageBuilder extends AbstractWindowsImageBuilder {
	protected static final String className = DevWindowsImageBuilder.class
			.getName();

	public DevWindowsImageBuilder(String bpmImageId, String bpmImageLoc,
			String bpmInstanceName, String instType, String swRepoHost,
			Map<String, String> parms) throws ImageBuilderException {
		super(bpmImageId, bpmImageLoc, bpmInstanceName, instType, swRepoHost,
				parms);
	}

	/*
	 * （none Javadoc） <p>Title: build</p> <p>Description: chain the building
	 * process - provision,upload files , execute commands ...</p>
	 * 
	 * @return ManagedImage
	 * 
	 * @see com.ibm.bpm.sce.objects.AbstractWindowsImageBuilder#build()
	 */
	public ManagedImage build() {
		boolean succ = false;
		ManagedImage bldImage = null;
		/**
		 * deploy
		 */
		deployBaseInstance();
		/**
		 * upload installation packages
		 */
		try {
			mgrLogger.info(className, "start to upload files.");
			uploadInstallationPackages();
			mgrLogger.info(className, "upload files are done.");
		} catch (FileNotFoundException e) {
			e.printStackTrace();
		}

		/**
		 * upload and extract installation scripts
		 */
		try {
			uploadInstallationScripts();
		} catch (FileNotFoundException e) {
			e.printStackTrace();
		} catch (ManagedInstanceException e) {
			e.printStackTrace();
		}

		/**
		 * install DB2
		 */
		try {
			mgrLogger.info(className, "start to install db2.");
			getMgrInst()
					.exec(
							"nohup /cygdrive/c/installer/Script/database/install_db2.bat &");
			waitForFileSignal("/cygdrive/c/installer/db2.done");
			mgrLogger.info(className, "finish installing db2.");
		} catch (ManagedInstanceException e) {
			e.printStackTrace();
			mgrLogger.err(className, e.toString());
		}
		/**
		 * install BPM
		 */
		try {
			mgrLogger.info(className, "start to install BPM.");
			getMgrInst().exec(
					"nohup /cygdrive/c/installer/Script/bpm/install_bpm.bat &");
			waitForFileSignal("/cygdrive/c/installer/bpm.done");
			mgrLogger.info(className, "finish installing BPM.");
		} catch (ManagedInstanceException e) {
			mgrLogger.err(className, e.toString());
		}
		/**
		 * install IID
		 */
		try {
			mgrLogger.info(className, "start to install IID.");
			getMgrInst().exec(
					"nohup /cygdrive/c/installer/Script/iid/install_iid.bat &");
			getMgrInst()
					.exec(
							"nohup /cygdrive/c/installer/Script/iid/follow_install_iid.bat &");
			waitForFileSignal("/cygdrive/c/installer/iid.done");
			mgrLogger.info(className, "finish installing IID.");
		} catch (ManagedInstanceException e) {
			mgrLogger.err(className, e.toString());
		}
		/*
		 * post install middlewares - DB2 , IID , BPM
		 */
		postInstallMiddlewares();
		/*
		 * clean
		 */

		/*
		 * save
		 */
		try {
			if (beforeSavingWindowsInst2Image()) {
				shutdownInst();
				bldImage = capture("DevBPMv85WindowsAtlas"
						+ Long.toString(System.currentTimeMillis()));
			}
		} catch (ManagedImageException e) {
			succ = false;
			e.printStackTrace();
		} catch (ManagedInstanceException e) {
			succ = false;
			e.printStackTrace();
		}

		return bldImage;
	}
	/**
	 * <p>
	 * Title: main
	 * </p>
	 * <p>
	 * Description: Build BPM SCE Image of v85
	 * </p>
	 * 
	 * @param args
	 */
	// public static void main(String[] args) {
	// String repo=new String("");
	// String instId=new String("445166");
	// StandardWindowsImageBuilder builder=new
	// StandardWindowsImageBuilder();
	// }
}
