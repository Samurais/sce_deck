package com.ibm.sce.middlewares;

import com.ibm.sce.deck.resources.ManagedInstance;

/**
 * @author Hai Liang BJ Wang/China/IBM Aug 6, 2013
 */
public interface IMiddlewareAdmin {

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
	public boolean uploadInstallationPackages();

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
	public boolean uploadManagementScripts();

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
	public boolean install();

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
	public boolean configure();

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
	public boolean register();

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
	public boolean start();

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
	public boolean stop();

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
	public boolean uninstall();

	/**
	* <p>Title: setInstance</p>
	* <p>Description: </p>
	* @param mgrInst
	*/ 
	public void setInstance(ManagedInstance mgrInst);
}
