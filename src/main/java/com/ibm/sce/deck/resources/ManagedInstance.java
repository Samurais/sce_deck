package com.ibm.sce.deck.resources;

import java.io.IOException;
import java.util.List;
import java.util.Map;

import com.ibm.cloud.api.rest.client.bean.Instance;
import com.ibm.cloud.api.rest.client.bean.Instance.Status;
import com.ibm.cloud.api.rest.client.bean.Image;
import com.ibm.cloud.api.rest.client.exception.InsufficientResourcesException;
import com.ibm.cloud.api.rest.client.exception.InvalidConfigurationException;
import com.ibm.cloud.api.rest.client.exception.PaymentRequiredException;
import com.ibm.cloud.api.rest.client.exception.UnauthorizedUserException;
import com.ibm.cloud.api.rest.client.http.APIHTTPException;
import com.ibm.sce.deck.commands.ResetInstNameCommand;
import com.ibm.sce.deck.exceptions.ManagedInstanceException;
import com.ibm.sce.deck.exceptions.SCEClientException;
import com.ibm.sce.deck.tools.ManagedClient;
import com.ibm.sce.deck.tools.ManagedHTTPTransport;
import com.ibm.sce.deck.tools.ManagedLogger;
import com.ibm.sce.deck.tools.ManagedProperties;
import com.ibm.sce.deck.tools.SSHClient;
import com.ibm.sce.deck.tools.ssh.SSHResult;

/**
 * SCE Instance
 * 
 * @author Hai Liang BJ Wang/China/IBM May 14, 2013
 */
public class ManagedInstance {

	private String name;
	private String id;
	private String ipAddr;
	private Map<String, Object> parms;
	private final String instanceType;
	private final String publicKey;
	private final String imageID;
	private final String locationID;
	private Instance inst;
	private String CLASSNAME = ManagedInstance.class.getName();
	private Status status = Status.UNKNOWN;
	private static ManagedLogger mgrLogger = ManagedLogger.getInstance();
	private static final String CLASS_NAME = ManagedInstance.class.getName();

	/**
	 * <p>
	 * Title: ManagedInstance with an existing instance
	 * </p>
	 * <p>
	 * Description: Management of an existing instance .
	 * </p>
	 * 
	 * @param id
	 *            the instance id , you can find the id of an instance from SCE
	 *            WebConsole.
	 * @throws ManagedInstanceException
	 * 
	 */
	public ManagedInstance(final String id) throws ManagedInstanceException {
		this.id = id;
		loadInstByID();
		this.instanceType = inst.getInstanceType();
		this.name = inst.getName();
		this.imageID = inst.getImageID();
		this.locationID = inst.getLocation();
		this.publicKey = inst.getKeyName();
		this.ipAddr = inst.getIP();
	}

	/**
	 * <p>
	 * Title: loadInstByID
	 * </p>
	 * <p>
	 * Description: get a SCE Instane by ID
	 * </p>
	 * 
	 * @throws ManagedInstanceException
	 */
	private void loadInstByID() throws ManagedInstanceException {
		try {
			this.inst = ManagedClient.getSCEClient().describeInstance(this.id);
		} catch (Exception e) {
			ManagedInstanceException mgrInstanceException = new ManagedInstanceException(
					handleExceptions(e));
			mgrInstanceException.setMessage(e.getMessage());
			throw mgrInstanceException;
		}
	}

	/**
	 * <p>
	 * Title: ManagedInstance that has information to deploy
	 * </p>
	 * <p>
	 * Description: initialize an instance that doesn't exist , pass parameters
	 * that need to create instance .
	 * </p>
	 * 
	 * @param name
	 *            name of the instance
	 * @param instanceType
	 *            instance type such as COP64.2/4096/60, find more in User
	 *            Guide.
	 * @param imageID
	 *            the image id that this instance launched from.
	 * @param locationID
	 *            the location where run this instane .
	 * @see ManagedLocation
	 * @param publicKey
	 *            a ssh key name that created in SCE account.this key will later
	 *            be used to connect to instance.
	 * @param parms
	 *            a map that contains configuration parameters
	 * 
	 */

	public ManagedInstance(final String name, final String instanceType,
			final String imageID, final String locationID,
			final String publicKey, final Map parms) {
		this.name = name;
		this.instanceType = instanceType;
		this.imageID = imageID;
		this.locationID = locationID;
		this.publicKey = publicKey;
		this.parms = parms;
	}

	/**
	 * <p>
	 * Title: deploy
	 * </p>
	 * <p>
	 * Description:deploy this instance by image id , location id , ssh key name
	 * and instance type
	 * </p>
	 * 
	 * @throws ManagedInstanceException
	 */
	public void deploy() throws ManagedInstanceException {
		List<Instance> insts;
		try {
			insts = ManagedClient.getSCEClient().createInstance(name,
					locationID, imageID, instanceType, publicKey, parms);
		} catch (Exception e) {
			throw new ManagedInstanceException(handleExceptions(e));
		}
		this.inst = insts.get(0);
		this.id = this.inst.getID();
		this.status = this.inst.getStatus();
		mgrLogger.info(CLASS_NAME, "new instance creation is submitted -"
				+ name + locationID + imageID + instanceType + publicKey);
		mgrLogger.info(CLASS_NAME, "new instance id -" + inst.getID());

	}

	/**
	 * <p>
	 * Title: updateStatus
	 * </p>
	 * <p>
	 * Description: get the status of a instance
	 * </p>
	 * 
	 * @return
	 */
	public void updateStatus() {
		try {
			this.inst = ManagedClient.getSCEClient().describeInstance(this.id);
			this.status = this.inst.getStatus();
			mgrLogger.debug(CLASS_NAME, "instance id :" + this.id + " status:"
					+ status.resourceKeyForName());
			this.name = this.inst.getName();
			this.ipAddr = this.inst.getIP();
		} catch (Exception e) {
			mgrLogger.err(CLASSNAME, "exceptions - getStatus");
			mgrLogger.err(CLASSNAME, e.getMessage());
		}

	}

	/**
	 * <p>
	 * Title: stop
	 * </p>
	 * <p>
	 * Description: stop an instance
	 * </p>
	 * 
	 * @throws ManagedInstanceException
	 */
	public void stop() throws ManagedInstanceException {
		updateStatus();
		if (this.inst.getStatus() == Instance.Status.ACTIVE) {
			try {
				ManagedClient.getSCEClient().stopInstance(this.id);
			} catch (Exception e) {
				ManagedInstanceException mgrInstanceException = new ManagedInstanceException(
						handleExceptions(e));
				mgrInstanceException.setMessage(e.getMessage());
				throw mgrInstanceException;
			}
		}

	}

	/**
	 * <p>
	 * Title: waitForStopped
	 * </p>
	 * <p>
	 * Description:wait for the instance to be stopped.
	 * </p>
	 * 
	 * @return true if the instance is stopped successfully
	 */
	public boolean waitForStopped() {
		boolean succ = false;
		boolean wait = true;
		while (wait) {
			try {
				Thread.sleep(1000 * 60 * 3);
				updateStatus();
				if (this.status == Status.STOPPED) {
					succ = true;
					wait = false;
					mgrLogger.debug(CLASS_NAME, this.id + " " + this.name
							+ "stopped .");
				}
				if (this.status == Status.REJECTED || status == Status.FAILED) {
					wait = false;
				}
			} catch (InterruptedException e) {
				mgrLogger.err(CLASS_NAME, e.toString());
			}
		}
		return succ;
	}

	/**
	 * <p>
	 * Title: waitForActive
	 * </p>
	 * <p>
	 * Description: when a instance is deployed , wait for this instance in
	 * Active status.
	 * </p>
	 * 
	 * @return return true if provision success,if the instance is rejected or
	 *         failed , return false
	 */
	public boolean waitForActive() {
		boolean succ = false;
		boolean wait = true;
		while (wait) {
			try {
				Thread.sleep(1000 * 60 * 3);
				updateStatus();
				if (this.status == Status.ACTIVE) {
					succ = true;
					wait = false;
					this.ipAddr = this.inst.getIP();
					// Sleep some time to wait the instance is ejected with SSH
					// key
					Thread.sleep(1000 * 60 * 6);
					mgrLogger.debug(CLASS_NAME, this.id + " " + this.name
							+ "is active now.");
				}
				if (this.status == Status.REJECTED || status == Status.FAILED
						|| status == Status.DEPROVISIONING
						|| status == Status.REMOVED) {
					wait = false;
				}
			} catch (InterruptedException e) {
				mgrLogger.err(CLASS_NAME, e.toString());
			}
		}
		return succ;
	}

	/**
	 * <p>
	 * Title: destory
	 * </p>
	 * <p>
	 * Description: destory this instance
	 * </p>
	 * 
	 * @throws ManagedInstanceException
	 */
	public void destory() throws ManagedInstanceException {
		try {
			ManagedClient.getSCEClient().deleteInstance(this.id);
		} catch (Exception e) {
			ManagedInstanceException mgrInstanceException = new ManagedInstanceException(
					handleExceptions(e));
			mgrInstanceException.setMessage(e.getMessage());
			throw mgrInstanceException;
		}

	}

	/**
	 * <p>
	 * Title: waitForDestorying
	 * </p>
	 * <p>
	 * Description: wait for the instance to be destoryed.
	 * </p>
	 */
	public void waitForDestorying() {

	}

	/**
	 * <p>
	 * Title: refreshIPaddr
	 * </p>
	 * <p>
	 * Description: get IP Address remotely and set it locally
	 * </p>
	 */
	public void refreshIPaddr() {
		if (this.ipAddr == null || (this.ipAddr.isEmpty())) {
			updateStatus();
			this.ipAddr = this.inst.getIP();
		}
	}

	/**
	 * <p>
	 * Title: isActive
	 * </p>
	 * <p>
	 * Description: check if the instance is active
	 * </p>
	 * 
	 * @return true if the instance is active
	 */
	public boolean isActive() {
		boolean succ = false;
		updateStatus();
		if (this.status == Status.ACTIVE) {
			succ = true;
		}
		return succ;
	}

	/**
	 * <p>
	 * Title: exec
	 * </p>
	 * <p>
	 * Description: execute a shell command in the instance
	 * </p>
	 * 
	 * @param cmdStr
	 *            Command in String Format
	 * @return a container that hold the results
	 * @throws ManagedInstanceException
	 * @see SSHResult
	 */
	public SSHResult exec(final String cmdStr) throws ManagedInstanceException {
		refreshIPaddr();
		if (this.ipAddr != null && (!this.ipAddr.isEmpty())) {
			SSHClient sshClient = new SSHClient(this.ipAddr);
			return sshClient.exec(cmdStr);
		} else {
			throw new ManagedInstanceException(
					ManagedInstanceException.INSTANCE_ACCESS_FAILURE);
		}
	}

	/**
	 * <p>
	 * Title: upload
	 * </p>
	 * <p>
	 * Description: upload a file into the instance
	 * </p>
	 * 
	 * @param localFile
	 *            local file path
	 * @param remoteAbsolutePath
	 *            the remote file path
	 */
	public void upload(String localFile, String remoteAbsolutePath) {
		refreshIPaddr();
		SSHClient sshClient = new SSHClient(this.ipAddr);
		sshClient.upload(localFile, remoteAbsolutePath);
	}

	/**
	 * <p>
	 * Title: download
	 * </p>
	 * <p>
	 * Description: download a file from instance
	 * </p>
	 * 
	 * @param localFile
	 *            local file path
	 * @param remoteAbsolutePath
	 *            remote file path
	 * @throws ManagedInstanceException
	 */
	public void download(String localFile, String remoteAbsolutePath)
			throws ManagedInstanceException {
		refreshIPaddr();
		if (isPathExist(remoteAbsolutePath)) {
			SSHClient sshClient = new SSHClient(this.ipAddr);
			sshClient.download(localFile, remoteAbsolutePath);
		} else {
			throw new ManagedInstanceException(
					ManagedInstanceException.PATH_NOT_EXIST_IN_INSTANCE);
		}
	}

	/**
	 * <p>
	 * Title: scpFrom
	 * </p>
	 * <p>
	 * Description: copy file from a remote vm that use the shared ssh key set
	 * in managed_sce.properties via scp .
	 * 
	 * idcuser
	 * </p>
	 * 
	 * @param remoteIP
	 * @param remoteFilePath
	 * @param localFilePath
	 * @return true if the file is transfered successfully. false if the
	 *         connection is failed or the target file is not exist.
	 */
	public boolean scpFrom(final String remoteIP, final String remoteFilePath,
			final String localFilePath) {
		// upLoad the privateKey
		boolean succ = false;
		ManagedProperties mgProps = new ManagedProperties();
		String upKeyPath = mgProps.getProperty("sce_private_key");
		upload(upKeyPath, "~/sshkey");
		try {
			exec("chmod 600 ~/sshkey");
			// change permission of key to 600
			StringBuffer scpSb = new StringBuffer();
			scpSb
					.append("scp -i ~/sshkey -o StrictHostKeyChecking=no idcuser@");
			scpSb.append(remoteIP);
			scpSb.append(":");
			scpSb.append(remoteFilePath);
			scpSb.append(" ");
			scpSb.append(localFilePath);
			SSHResult sshResult = exec(scpSb.toString());
			if (sshResult.getReturnCode() != 0) {
				succ = false;
			} else {
				succ = true;
			}
		} catch (ManagedInstanceException e) {
			mgrLogger.err(CLASS_NAME, e.toString());
		}
		return succ;
	}

	/**
	 * <p>
	 * Title: isPathExist
	 * </p>
	 * <p>
	 * Description:check if the given path exist
	 * </p>
	 * 
	 * @param remoteAbsolutePath
	 * @return true if the path exist , false if not.
	 */
	public boolean isPathExist(String remoteAbsolutePath) {
		boolean succ = false;
		SSHResult sshr;
		try {
			sshr = exec("ls -a " + remoteAbsolutePath);
			String str = sshr.getOut();
			if (str != null && !str.isEmpty()) {
				succ = true;
			}
		} catch (ManagedInstanceException e) {
			mgrLogger.err(CLASS_NAME, e.getType());
		}
		return succ;
	}

	private String handleExceptions(Exception e) {
		String exceptionType = new String();
		if (e instanceof InsufficientResourcesException) {
			exceptionType = ManagedInstanceException.RESOURCE_LIMITATION;
		} else if (e instanceof InvalidConfigurationException) {
			System.out.println(e.getMessage());
			System.out.println(e.getCause());
			System.out.println(e.toString());
			exceptionType = ManagedInstanceException.INVALIDCONFIGURATION;
		} else if (e instanceof PaymentRequiredException) {
			exceptionType = ManagedInstanceException.BILLING_NEEDED;
		} else if (e instanceof UnauthorizedUserException) {
			exceptionType = ManagedInstanceException.AUTH_FAILED;
		} else if (e instanceof SCEClientException) {
			exceptionType = ManagedInstanceException.SCECLIENT;
		} else {
			exceptionType = ManagedInstanceException.UNKNOWN;
		}
		return exceptionType;
	}

	/**
	 * <p>
	 * Title: capture
	 * </p>
	 * <p>
	 * Description:Saves the Instance to a new private Image with the specified
	 * name and description. The new image will take a finite time to create.
	 * Wait for the image to change to an AVAILABLE state before using the image
	 * to create an instance from. During this time the state of the instance
	 * will change to CAPTURING.
	 * </p>
	 * 
	 * @param imageName
	 *            image name
	 * @param imageDesc
	 *            image description
	 * @return Image
	 * @see com.ibm.cloud.api.rest.client.bean.Image
	 * @throws ManagedInstanceException
	 */
	public Image capture(String imageName, String imageDesc)
			throws ManagedInstanceException {
		try {
			return ManagedClient.getSCEClient().saveInstance(getId(),
					imageName, imageDesc);
		} catch (Exception e) {
			throw new ManagedInstanceException("Fail to save image");
		}
	}

	public String getIPAddr() {
		return this.ipAddr;
	}

	public String getId() {
		return id;
	}

	public void setId(String id) {
		this.id = id;
	}

	/**
	 * <p>
	 * Title: resetName
	 * </p>
	 * <p>
	 * Description: reset the instance name
	 * </p>
	 */
	public void resetName(String newName) {
		ResetInstNameCommand cmd = new ResetInstNameCommand(id, newName);
		try {
			try {
				ManagedHTTPTransport.exec(cmd);
			} catch (SCEClientException e) {
				e.printStackTrace();
			}
		} catch (IOException e) {
			e.printStackTrace();
		} catch (APIHTTPException e) {
			e.printStackTrace();
		}
	}

	public String getName() {
		return name;
	}

	/**
	 * <p>
	 * Title: main
	 * </p>
	 * <p>
	 * Description:test instance objects
	 * </p>
	 * 
	 * @param args
	 */
	public static void main(String[] args) {
		ManagedProperties managedProps = new ManagedProperties();
		String redHatImageID = "20025211";
		String instType = "COP64.2/4096/60";
		String instName = "testlogin";
		/**
		 * test provision
		 */
		// try {
		// ManagedInstance managedInst;
		// managedInst = new ManagedInstance(instName, instType,
		// redHatImageID, ManagedLocation.SINGAPORE.getId(),
		// managedProps.getProperty("sce_ssh_key"), null);
		// managedInst.deploy();
		// } catch (ManagedInstanceException e) {
		// e.printStackTrace();
		// }

		/**
		 * test download
		 */
		// ManagedInstance managedInst2;
		// try {
		// managedInst2 = new ManagedInstance("440216");
		// managedInst2.download("/home/hailiang/tmp/", "~/test_upload.sh");
		// } catch (ManagedInstanceException e) {
		// System.out.println(e.getType());
		// }

		/**
		 * test exec
		 */
		ManagedInstance managedInst2;
		try {
			managedInst2 = new ManagedInstance("445840");
			System.out.println(managedInst2.exec("ls /").getOut());
		} catch (ManagedInstanceException e) {
			System.out.println(e.getType());
		}

		/**
		 * test scpFrom
		 */
		// ManagedInstance managedInst2;
		// try {
		// managedInst2 = new ManagedInstance("440222");
		// String remoteIP = new String("170.225.163.85");
		// String remoteFP = new String("~/tmp/test");
		// String localFP = new String("/tmp/test");
		// managedInst2.scpFrom(remoteIP, remoteFP, localFP);
		// } catch (ManagedInstanceException e) {
		// System.out.println(e.getType());
		// }

	}

}
