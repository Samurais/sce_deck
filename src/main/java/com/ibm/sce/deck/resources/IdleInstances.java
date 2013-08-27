package com.ibm.sce.deck.resources;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

import com.ibm.cloud.api.rest.client.DeveloperCloudClient;
import com.ibm.cloud.api.rest.client.bean.Instance;
import com.ibm.cloud.api.rest.client.exception.InvalidStateException;
import com.ibm.cloud.api.rest.client.exception.UnauthorizedUserException;
import com.ibm.cloud.api.rest.client.exception.UnknownErrorException;
import com.ibm.cloud.api.rest.client.exception.UnknownInstanceException;
import com.ibm.sce.deck.exceptions.SCEClientException;
import com.ibm.sce.deck.tools.ManagedClient;

/**
 * @author Hai Liang BJ Wang/China/IBM Jul 15, 2013
 */
public class IdleInstances {
	private ArrayList<String> instIds;
	private String idlerName;
	private DeveloperCloudClient cloudClient;

	/**
	 * <p>
	 * Title: IdleInstances
	 * </p>
	 * <p>
	 * Description:Instance that does not contain any workloads, basic an
	 * Instance launched from base image and do nothing inside can be regarded
	 * as an idle instance.An idle instance is the ready-for-use member of the
	 * instance pool.
	 * </p>
	 * 
	 * @param idlerName
	 *            name of idleInstance in the pool, the idle instance all use
	 *            the same name as they have no difference except ip
	 * @param cloudClient
	 *            a client that can be used to access SCE Services and
	 *            Resources.
	 */
	public IdleInstances(final String idlerName,
			final DeveloperCloudClient cloudClient) {
		this.idlerName = idlerName;
		this.cloudClient = cloudClient;
		this.instIds = new ArrayList<String>();
		loadIdlerIds();
	}

	/**
	 * <p>
	 * Title: getInstCounts
	 * </p>
	 * <p>
	 * Description: get the instance number for a specific SCE Account
	 * </p>
	 * 
	 * @return
	 * @throws UnauthorizedUserException
	 * @throws UnknownErrorException
	 * @throws IOException
	 */
	public int getInstCounts() throws UnauthorizedUserException,
			UnknownErrorException, IOException {
		List<Instance> insts = cloudClient.describeInstances();
		return insts.size();
	}

	/**
	 * <p>
	 * Title: loadIdlerIds
	 * </p>
	 * <p>
	 * Description: load the IDs of idler instances in a list
	 * </p>
	 */
	public void loadIdlerIds() {
		try {
			if (this.instIds.size() > 0) {
				this.instIds.clear();
			}
			List<Instance> insts = cloudClient.describeInstances();
			for (int i = 0; i < insts.size(); i++) {
				Instance inst = insts.get(i);
				if (inst.getName().equals(this.idlerName))
					this.instIds.add(inst.getID());
			}
		} catch (UnauthorizedUserException e) {
			e.printStackTrace();
		} catch (UnknownErrorException e) {
			e.printStackTrace();
		} catch (IOException e) {
			e.printStackTrace();
		}
	}

	public void destroy() {
		for (int i = 0; i < this.instIds.size(); i++) {
			try {
				this.cloudClient.deleteInstance((String) this.instIds.get(i));
			} catch (InvalidStateException e) {
				e.printStackTrace();
			} catch (UnauthorizedUserException e) {
				e.printStackTrace();
			} catch (UnknownErrorException e) {
				e.printStackTrace();
			} catch (UnknownInstanceException e) {
				e.printStackTrace();
			} catch (IOException e) {
				e.printStackTrace();
			}
		}

	}

	public ArrayList<String> getInstIds() {
		return instIds;
	}

	/**
	 * <p>
	 * Title: main
	 * </p>
	 * <p>
	 * Description: test destroy methods
	 * </p>
	 * 
	 * @param args
	 */
	public static void main(String[] args) {
		IdleInstances ins;
		DeveloperCloudClient client;
		try {
			client = ManagedClient.getSCEClient();
			ins = new IdleInstances("BPMv85WindowsBase", client);
			ins.destroy();
		} catch (SCEClientException e) {
			e.printStackTrace();
		}
	}
}