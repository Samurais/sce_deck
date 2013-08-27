package com.ibm.bpm.sce.imagebuilder;

import java.io.FileNotFoundException;

import com.ibm.sce.deck.exceptions.ManagedImageException;
import com.ibm.sce.deck.exceptions.ManagedInstanceException;
import com.ibm.sce.deck.resources.ManagedImage;

/**
 * @author Hai Liang BJ Wang/China/IBM Jul 18, 2013
 */
public class ExistingInstance2Bpmv85ImageBuilder extends
		AbstractWindowsImageBuilder {
	private static final String className = ExistingInstance2Bpmv85ImageBuilder.class
			.getName();

	public ExistingInstance2Bpmv85ImageBuilder(final String instanceId,
			final String swRepoHost, final String instUser,
			final String instPassword) throws ManagedInstanceException {
		super(instanceId, swRepoHost, instUser, instPassword);
	}

	/*
	 * （none Javadoc） <p>Title: build</p> <p>Description: install bpm in
	 * instance</p>
	 * 
	 * @return true if the image is built
	 * 
	 * @see com.ibm.bpm.sce.imagebuilder.AbstractWindowsImageBuilder#build()
	 */
	@Override
	public ManagedImage build() {
		ManagedImage bldImage = null;
		boolean succ = false;
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
		 * save
		 */
		try {
			if (beforeSavingWindowsInst2Image()) {
				/*
				 * clean
				 */
				cleanDevEnvironment();
				bldImage = capture("BPMv85WindowsAtlas"
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

}
