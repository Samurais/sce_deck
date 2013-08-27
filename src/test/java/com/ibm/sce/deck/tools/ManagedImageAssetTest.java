package com.ibm.sce.deck.tools;

import java.util.Date;

import com.ibm.ram.common.data.UserInformation;
import com.ibm.sce.deck.exceptions.SCEClientException;

import junit.framework.TestCase;

/**
 * @author Hai Liang BJ Wang/China/IBM Jul 31, 2013
 */
public class ManagedImageAssetTest extends TestCase {

	ManagedImageAsset client;

	/**
	 * <p>
	 * Title: testGetAsset
	 * </p>
	 * <p>
	 * Description:
	 * </p>
	 */
	public void testGetAsset() {

	}

	/**
	 * <p>
	 * Title: testRename
	 * </p>
	 * <p>
	 * Description:
	 * </p>
	 */
	public void testRename() {
		try {
			client = new ManagedImageAsset();
			String guid = "DEAF1418-F923-FDEF-5C3C-B5E1DC702942";
			String newName = "new name " + (new Date()).toString();
			client.resetAssetName(guid, newName);
			assertTrue(client.getAsset(guid).getName().equals(newName));
		} catch (SCEClientException e) {
			e.printStackTrace();
		}
	}

	/**
	 * <p>
	 * Title: testChangeCommunity
	 * </p>
	 * <p>
	 * Description:
	 * </p>
	 */
	public void testChangeCommunity() {
		try {
			client = new ManagedImageAsset();
			String guid = "DEAF1418-F923-FDEF-5C3C-B5E1DC702942";
			String communityName = "Primary Enterprise Community 20000427";
			client.resetCommunityName(guid, communityName);
			assertTrue(client.getAsset(guid).getCommunityName().equals(
					communityName));
		} catch (SCEClientException e) {
			e.printStackTrace();
		}
	}

	/**
	 * <p>
	 * Title: testAddOwner
	 * </p>
	 * <p>
	 * Description:
	 * </p>
	 */
	public void testAddOwner() {
		try {
			client = new ManagedImageAsset();
			String guid = "DEAF1418-F923-FDEF-5C3C-B5E1DC702942";
			// owner
			UserInformation usr = new UserInformation();
			usr.setEmail("qianfeng@cn.ibm.com");
			usr.setImageURL("/theme/images/dummyImage.jpg");
			usr.setName("Qian Feng");
			usr.setUid("qianfeng@cn.ibm.com");
			client.addOwner(guid, usr);

		} catch (SCEClientException e) {
			e.printStackTrace();
		}
	}

	public void testUpdateContents() {
		try {
			client = new ManagedImageAsset();
			String guid = "DEAF1418-F923-FDEF-5C3C-B5E1DC702942";
			String targetFilePath = "sce_developers.json";
			String sourceFilePath = "src/main/resources/sce_developers.json";
			client.uploadFile2AssetContent(guid, sourceFilePath);

		} catch (SCEClientException e) {
			e.printStackTrace();
		}
	}

	public void tearDown() {
		client = null;
	}
}
