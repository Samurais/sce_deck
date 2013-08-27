package com.ibm.sce.deck.resources;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import com.ibm.cloud.api.rest.client.bean.Image;
import com.ibm.cloud.api.rest.client.exception.UnauthorizedUserException;
import com.ibm.cloud.api.rest.client.exception.UnknownImageException;
import com.ibm.ram.common.data.UserInformation;
import com.ibm.sce.deck.exceptions.ManagedImageException;
import com.ibm.sce.deck.exceptions.SCEClientException;
import com.ibm.sce.deck.tools.ManagedClient;
import com.ibm.sce.deck.tools.ManagedImageAsset;

/**
 * @author Hai Liang BJ Wang/China/IBM Jul 17, 2013
 */
public class ManagedImage {

	private static Image image;
	private static String imageId;
	private static String imageName;
	private static final String PARSE_RAM_UID_URL_FLAG = "artifact";
	private static final String IMAGE_SHARED_COMMUNITY = "Primary Enterprise Community 20000427";
	private static final String IMAGE_PRIVATE_COMMUNITY = "Cloud Computing Private Image Community";

	private static String assetUuid;

	private ManagedImage() {

	}

	/**
	 * <p>
	 * Title:ManagedImage
	 * </p>
	 * <p>
	 * Description: create ManagedImage with Image Name
	 * </p>
	 * 
	 * @param imageName
	 * @throws ManagedImageException
	 */
	public ManagedImage(final String imageName) throws ManagedImageException {
		this.imageName = imageName;
		loadImageByName(imageName);
		this.imageId = image.getID();
	}

	/**
	 * <p>
	 * Title:ManagedImage
	 * </p>
	 * <p>
	 * Description: create ManagedImage with Image Id
	 * </p>
	 * 
	 * @param imageId
	 * @throws ManagedImageException
	 */
	public ManagedImage(int imageId) throws ManagedImageException {
		this.imageId = String.valueOf(imageId);
		loadImageById(this.imageId);
		this.imageName = this.image.getName();
	}

	/**
	 * <p>
	 * Title: loadImage
	 * </p>
	 * <p>
	 * Description: get the Image by id
	 * </p>
	 * 
	 * @param imageId
	 * @throws ManagedImageException
	 */
	private void loadImageById(final String imageId)
			throws ManagedImageException {
		try {
			this.image = ManagedClient.getSCEClient().describeImage(imageId);
		} catch (Exception e) {
			throw new ManagedImageException(handleExceptions(e));
		}
	}

	/**
	 * <p>
	 * Title: loadImage
	 * </p>
	 * <p>
	 * Description: get the Image by name
	 * </p>
	 * 
	 * @param imageId
	 * @throws ManagedImageException
	 */
	private void loadImageByName(final String imageName)
			throws ManagedImageException {
		Map<String, String> imgParams = new HashMap();
		imgParams.put("imageName", imageName);
		try {
			List<Image> imgs = ManagedClient.getSCEClient().describeImages(
					imgParams);
			for (int i = 0; i < imgs.size(); i++) {
				this.image = imgs.get(i);
			}
		} catch (Exception e) {
			throw new ManagedImageException(handleExceptions(e));
		}
	}

	/**
	 * <p>
	 * Title: waitForAvailable
	 * </p>
	 * <p>
	 * Description: return if the Image is in available state
	 * </p>
	 * 
	 * @throws ManagedImageException
	 */
	public void waitForAvailable() throws ManagedImageException {
		boolean isAvailable = false;
		while (!isAvailable) {
			try {
				Thread.sleep(1000 * 60 * 5);
				this.image = ManagedClient.getSCEClient()
						.describeImage(imageId);
			} catch (Exception e) {
				throw new ManagedImageException(handleExceptions(e));
			}
			if (this.image.getState().equals(Image.State.AVAILABLE)) {
				isAvailable = true;
			}
		}

	}

	/**
	 * <p>
	 * Title: reload
	 * </p>
	 * <p>
	 * Description: reload the image object from SCE Server
	 * </p>
	 * 
	 * @throws ManagedImageException
	 */
	public void reload() throws ManagedImageException {
		loadImageById(imageId);
	}

	/**
	 * <p>
	 * Title: getImageAssetUUID
	 * </p>
	 * <p>
	 * Description: get Asset UUId of image by parsing the manifest url which
	 * contains the UUID.
	 * </p>
	 * 
	 * @return true if get the value
	 */
	public boolean getImageAssetUUID() {
		boolean succ = false;
		String manifest = image.getManifest().toString();
		String[] strArr = manifest.split("/");
		for (int i = 0; i < strArr.length; i++) {
			System.out.println();
			if (strArr[i].equalsIgnoreCase(PARSE_RAM_UID_URL_FLAG)) {
				assetUuid = new String(strArr[i + 1]);
				succ = true;
				break;
			}
		}
		return succ;
	}

	/**
	 * <p>
	 * Title: isShared
	 * </p>
	 * <p>
	 * Description: check if the image is shared
	 * </p>
	 * 
	 * @return true if the image is shared
	 * @throws ManagedImageException
	 */
	public boolean isShared() throws ManagedImageException {
		boolean succ = false;
		reload();
		if (this.image.getVisibility().equals(Image.Visibility.SHARED)) {
			succ = true;
		}
		return succ;
	}

	/**
	 * <p>
	 * Title: share
	 * </p>
	 * <p>
	 * Description: share the image,change its community
	 * </p>
	 * 
	 * @throws ManagedImageException
	 * @throws SCEClientException
	 */
	public void share() throws ManagedImageException, SCEClientException {
		if (!isShared()) {
			if (getImageAssetUUID()) {
				ManagedImageAsset client = new ManagedImageAsset();
				client.resetCommunityName(assetUuid, IMAGE_SHARED_COMMUNITY);
			}
		}
	}

	/**
	 * <p>
	 * Title: addOwner
	 * </p>
	 * <p>
	 * Description: addOwner by SCE userId
	 * </p>
	 * 
	 * @param ownerId
	 * @throws SCEClientException
	 */
	public void addOwner(UserInformation user) throws SCEClientException {
		if (assetUuid.isEmpty() || assetUuid == null) {
			getImageAssetUUID();
		}
		if ((!assetUuid.isEmpty()) && assetUuid != null) {
			ManagedImageAsset client = new ManagedImageAsset();
			client.addOwner(assetUuid, user);
		}
	}

	/**
	 * <p>
	 * Title: getImage
	 * </p>
	 * <p>
	 * Description: Image Object
	 * </p>
	 * 
	 * @return
	 */
	public Image getImage() {
		return this.image;

	}

	public void delete() throws ManagedImageException {
		try {
			ManagedClient.getSCEClient().deleteImage(imageId);
		} catch (Exception e) {
			throw new ManagedImageException(handleExceptions(e));
		}

	}

	/**
	 * <p>
	 * Title: uploadAsset
	 * </p>
	 * <p>
	 * Description: upload the asset from a local folder , overwrite the old
	 * files in asset.
	 * </p>
	 * 
	 * @param assetFolder
	 * @return
	 * @throws SCEClientException
	 * @throws ManagedImageException
	 */
	public boolean uploadAsset(final String assetFolder)
			throws SCEClientException, ManagedImageException {
		boolean succ = false;
		getImageAssetUUID();
		if ((!assetUuid.isEmpty()) && assetUuid != null) {
			ManagedImageAsset client = new ManagedImageAsset();
			client.uploadAssetContentTotally(assetUuid, assetFolder);
		}
		return succ;

	}

	/**
	 * <p>
	 * Title: handleExceptions
	 * </p>
	 * <p>
	 * Description: handle exceptions
	 * </p>
	 * 
	 * @param e
	 * @return exception type
	 */
	private String handleExceptions(Exception e) {
		String exceptionType = new String();
		if (e instanceof UnauthorizedUserException) {
			exceptionType = ManagedImageException.UNAUTHORIZEDUSER;
		} else if (e instanceof UnknownImageException) {
			exceptionType = ManagedImageException.UNKNOWNIMAGE;
		} else if (e instanceof SCEClientException) {
			exceptionType = ManagedImageException.SCECLIENT;
		} else {
			exceptionType = ManagedImageException.UNKNOWNERROR;
		}
		return exceptionType;
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
	// ManagedInstance managedInst;
	// String instId = "440288";
	// int imgId = 20106095;
	// /**
	// * try to load image by Image ID
	// */
	// // try {
	// // managedInst = new ManagedInstance(instId);
	// // Image img = managedInst.capture("testSaveImage",
	// // "test ManagedInstance.capture()");
	// // System.out.println("save it");
	// //
	// // } catch (ManagedInstanceException e) {
	// // System.out.println(e.getType());
	// // }
	// /**
	// * get Image info
	// */
	// ManagedImage mgImg;
	// try {
	// mgImg = new ManagedImage(imgId);
	// Image img = mgImg.getImage();
	//
	// System.out.println();
	//
	// } catch (ManagedImageException e) {
	// e.printStackTrace();
	// }
	// /**
	// * get type
	// */
	// // Visibility vis = img.getVisibility();
	// // System.out.println(vis.toString());
	// // } catch (ManagedImageException e) {
	// // e.printStackTrace();
	// // }
	// /**
	// * delete image
	// */
	// // mgImg.delete();
	// }
}
