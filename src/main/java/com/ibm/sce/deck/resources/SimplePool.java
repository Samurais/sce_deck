package com.ibm.sce.deck.resources;

import java.util.Map;
import com.ibm.cloud.api.rest.client.DeveloperCloud;
import com.ibm.cloud.api.rest.client.DeveloperCloudClient;
import com.ibm.sce.deck.exceptions.ManagedInstanceException;
import com.ibm.sce.middlewares.IMiddlewareAdmin;

public class SimplePool {

	private static String imageId;
	private static String locationId;
	private static Map<String, String> parms;
	private static String keyName;
	private static int capacity;
	private static String instType;
	private static int maxSize;
	private static int minSize;
	private static int idlerSize;
	private static Map<String, ManagedInstance> instances;
	private static String idlerName;
	private static String accountName;
	private static String accountPassword;
	private static IMiddlewareAdmin middlewareAdmin;

	/**
	 * <p>
	 * Title: An Instance Pool
	 * 
	 * </p>
	 * <p>
	 * Description: Manage a group of instances as a pool, balance the pool by
	 * max,min and idler size
	 * </p>
	 * 
	 * @param imageId
	 * @param locationId
	 * @param parms
	 * @param keyName
	 * @param capacity
	 * @param instType
	 * @param maxSize
	 * @param minSize
	 * @param idlerSize
	 * @param idlerName
	 */
	public SimplePool(String imageId, String locationId,
			Map<String, String> parms, String keyName, int capacity,
			String instType, int maxSize, int minSize, int idlerSize,
			String idlerName, String accountName, String accountPassword,
			IMiddlewareAdmin middlewareAdmin) {
		setImageId(imageId);
		setLocationId(locationId);
		setParms(parms);
		setKeyName(keyName);
		setCapacity(capacity);
		setInstType(instType);
		setMaxSize(maxSize);
		setMinSize(minSize);
		setIdlerSize(idlerSize);
		setIdlerName(idlerName);
		setAccountName(accountName);
		setAccountPassword(accountPassword);
		setMiddlewareAdmin(middlewareAdmin);

	}

	private DeveloperCloudClient getCloudClient() {
		DeveloperCloudClient client = DeveloperCloud.getClient();
		client.setRemoteCredentials(getAccountName(), getAccountPassword());
		return client;
	}

	private IdleInstances getCloudIdlers() {
		return new IdleInstances(getIdlerName(), getCloudClient());
	}

	private void loadInstances() {
		IdleInstances idlers = getCloudIdlers();
		int cloudInstSize = idlers.getInstIds().size();
		for (int i = 0; i < idlers.getInstIds().size(); i++) {

		}

	}

	private void deployInstance() throws ManagedInstanceException {
		ManagedInstance intsTemp = new ManagedInstance(null, null, null, null,
				null, null);
		intsTemp.deploy();
		intsTemp.waitForActive();
		middlewareAdmin.setInstance(intsTemp);
		middlewareAdmin.uploadInstallationPackages();
		middlewareAdmin.uploadManagementScripts();
		middlewareAdmin.install();
		middlewareAdmin.configure();
	}

	public void balance() {
	}

	public static String getImageId() {
		return imageId;
	}

	public static String getIdlerName() {
		return idlerName;
	}

	public static void setIdlerName(String idlerName) {
		SimplePool.idlerName = idlerName;
	}

	public static String getLocationId() {
		return locationId;
	}

	public static Map<String, String> getParms() {
		return parms;
	}

	public static String getKeyName() {
		return keyName;
	}

	public static int getCapacity() {
		return capacity;
	}

	public static String getInstType() {
		return instType;
	}

	public static int getMaxSize() {
		return maxSize;
	}

	public static int getMinSize() {
		return minSize;
	}

	public static int getIdlerSize() {
		return idlerSize;
	}

	public void setImageId(String imageId) {
		this.imageId = imageId;
	}

	public void setLocationId(String locationId) {
		this.locationId = locationId;
	}

	public void setParms(Map<String, String> parms) {
		this.parms = parms;
	}

	public void setKeyName(String keyName) {
		this.keyName = keyName;
	}

	public void setCapacity(int capacity) {
		this.capacity = capacity;
	}

	public void setInstType(String instType) {
		this.instType = instType;
	}

	public void setMaxSize(int maxSize) {
		this.maxSize = maxSize;
	}

	public void setMinSize(int minSize) {
		this.minSize = minSize;
	}

	public void setIdlerSize(int idlerSize) {
		this.idlerSize = idlerSize;
	}

	public static String getAccountName() {
		return accountName;
	}

	public static String getAccountPassword() {
		return accountPassword;
	}

	public void setAccountName(String accountName) {
		this.accountName = accountName;
	}

	public void setAccountPassword(String accountPassword) {
		this.accountPassword = accountPassword;
	}

	public IMiddlewareAdmin getMiddlewareAdmin() {
		return middlewareAdmin;
	}

	public void setMiddlewareAdmin(IMiddlewareAdmin middlewareAdmin) {
		this.middlewareAdmin = middlewareAdmin;
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
	// public static void main(String[] args) {
	//
	// }

}
