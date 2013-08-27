package com.ibm.sce.middlewares;

import com.ibm.sce.deck.resources.ManagedInstance;

/**
 * @author Hai Liang BJ Wang/China/IBM Aug 6, 2013
 */
public final class DefaultMiddlewareAdmin implements IMiddlewareAdmin {

	private static ManagedInstance mgrInst;

	/**
	 * <p>
	 * Title: uploadInstallationPackages
	 * </p>
	 * <p>
	 * Description: upload the installation packages into the Remote Instance
	 * </p>
	 * 
	 * @return
	 */
	public boolean uploadInstallationPackages() {
		boolean succ = true;
		return succ;
	}

	/**
	 * <p>
	 * Title: uploadManagementScripts
	 * </p>
	 * <p>
	 * Description: upload the scripts that are used to manage the lifecycle of
	 * the middleware
	 * </p>
	 * 
	 * @return
	 */
	public boolean uploadManagementScripts() {
		boolean succ = true;
		return succ;
	}

	/**
	 * <p>
	 * Title: install
	 * </p>
	 * <p>
	 * Description: install the middleware
	 * </p>
	 * 
	 * @return
	 */
	public boolean install() {
		boolean succ = true;
		return succ;
	}

	/**
	 * <p>
	 * Title: configure
	 * </p>
	 * <p>
	 * Description: configure the middleware
	 * </p>
	 * 
	 * @return
	 */
	public boolean configure() {
		boolean succ = true;
		return succ;
	}

	/**
	 * <p>
	 * Title: register
	 * </p>
	 * <p>
	 * Description: register the license if needed
	 * </p>
	 * 
	 * @return
	 */
	public boolean register() {
		boolean succ = true;
		return succ;
	}

	/**
	 * <p>
	 * Title: start
	 * </p>
	 * <p>
	 * Description: start the middleware
	 * </p>
	 * 
	 * @return
	 */
	public boolean start() {
		boolean succ = true;
		return succ;
	}

	/**
	 * <p>
	 * Title: stop
	 * </p>
	 * <p>
	 * Description: stop the middleware
	 * </p>
	 * 
	 * @return
	 */
	public boolean stop() {
		boolean succ = true;
		return succ;
	}

	/**
	 * <p>
	 * Title: uninstall
	 * </p>
	 * <p>
	 * Description: uninstall ,remove , clean the middleware
	 * </p>
	 * 
	 * @return
	 */
	public boolean uninstall() {
		boolean succ = true;
		return succ;
	}

	public void setInstance(ManagedInstance mgrInst) {
		this.mgrInst = mgrInst;
	}
}
