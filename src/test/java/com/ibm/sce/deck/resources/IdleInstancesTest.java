package com.ibm.sce.deck.resources;

import com.ibm.cloud.api.rest.client.DeveloperCloudClient;
import com.ibm.sce.deck.resources.IdleInstances;
import com.ibm.sce.deck.tools.ManagedClient;

import junit.framework.TestCase;

/**
 * @author Hai Liang BJ Wang/China/IBM
 * Jul 15, 2013
 */
public class IdleInstancesTest extends TestCase {

	/**
	 * <p>
	 * Title: testGetInstIds
	 * </p>
	 * <p>
	 * Description: init an IdleInstances , try to fetch the idlers number
	 * </p>
	 */
	public void testGetInstIds() {
		IdleInstances ins;
		try {
			DeveloperCloudClient client = ManagedClient.getSCEClient();
			ins = new IdleInstances("idler", client);
			assertTrue(ins.getInstIds().size() >= 0);
		} catch (Exception e) {
			assertTrue(false);
		}
	}

}
