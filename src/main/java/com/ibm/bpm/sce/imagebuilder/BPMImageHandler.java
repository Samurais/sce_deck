package com.ibm.bpm.sce.imagebuilder;

import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.InputStream;
import com.ibm.json.java.JSONArray;
import com.ibm.json.java.JSONObject;
import com.ibm.ram.common.data.UserInformation;
import com.ibm.sce.deck.exceptions.ManagedImageException;
import com.ibm.sce.deck.exceptions.SCEClientException;
import com.ibm.sce.deck.resources.ManagedImage;
import com.ibm.sce.deck.tools.ManagedLogger;

/**
 * @author Hai Liang BJ Wang/China/IBM Aug 8, 2013
 */
public class BPMImageHandler {

	private static ManagedImage mgrImg;
	private static UserInformation[] owners;
	private static String ownerConfigFile;
	private static String assetFolder;
	private final static String className = BPMImageHandler.class.getName();
	private static ManagedLogger mgrLogger = ManagedLogger.getInstance();

	private BPMImageHandler() {

	}

	/**
	 * <p>
	 * Title: Customize the BPM Image
	 * </p>
	 * <p>
	 * Description:upload the asset from RTC, change the image's visibility,add
	 * owners
	 * </p>
	 * 
	 * @param img
	 */
	public BPMImageHandler(ManagedImage mgrImg, String ownerConfigFile,
			String assetFolder) {
		this.mgrImg = mgrImg;
		this.ownerConfigFile = ownerConfigFile;
		this.assetFolder = assetFolder;
	}

	/**
	 * <p>
	 * Title: process
	 * </p>
	 * <p>
	 * Description: process the bpm image - upload assets ,share ,add owners
	 * </p>
	 * 
	 * @throws ManagedImageException
	 * @throws SCEClientException
	 * @throws IOException
	 * @throws FileNotFoundException
	 */
	public void process() throws ManagedImageException, SCEClientException,
			FileNotFoundException, IOException {

		mgrLogger.info(className, "prcess image id - "
				+ mgrImg.getImage().getID());

		mgrLogger.info(className, "upload asset - "
				+ mgrImg.getImage().getName() + " " + assetFolder);
		mgrImg.uploadAsset(assetFolder);

		mgrLogger.info(className, "share image");
		mgrImg.share();

		mgrLogger.info(className, "add owners");
		addOwners();

	}

	/**
	 * <p>
	 * Title: addOwners
	 * </p>
	 * <p>
	 * Description: add image owners
	 * </p>
	 * 
	 * @throws SCEClientException
	 * @throws FileNotFoundException
	 * @throws IOException
	 */
	protected void addOwners() throws SCEClientException,
			FileNotFoundException, IOException {
		setOwners();
		for (int i = 0; i < owners.length; i++) {
			mgrLogger.info(className, "add owner - " + owners[i].getEmail());
			mgrImg.addOwner(owners[i]);
		}
	}

	/**
	 * <p>
	 * Title: setOwners
	 * </p>
	 * <p>
	 * Description:set the owners list , the user in the list will be added as
	 * owner of the image
	 * </p>
	 * 
	 * @param ownersConfigFilePath
	 * @throws FileNotFoundException
	 * @throws IOException
	 */
	protected void setOwners() throws FileNotFoundException, IOException {
		InputStream is = new FileInputStream(ownerConfigFile);
		new JSONArray();
		JSONArray bpmOwners = JSONArray.parse(is);
		owners = new UserInformation[bpmOwners.size()];
		for (int i = 0; i < bpmOwners.size(); i++) {
			JSONObject user = (JSONObject) bpmOwners.get(i);
			owners[i] = getUserInformation((String) user.get("name"),
					(String) user.get("uid"));
		}
	}

	/**
	 * <p>
	 * Title: getUserInformation
	 * </p>
	 * <p>
	 * Description:
	 * </p>
	 * 
	 * @param name
	 * @param uid
	 * @return
	 */
	protected UserInformation getUserInformation(String name, String uid) {
		UserInformation usr = new UserInformation();
		usr.setEmail(uid);
		usr.setName(name);
		usr.setUid(uid);
		usr.setImageURL("/theme/images/dummyImage.jpg");
		return usr;
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
	public static void main(String[] args) {
		ManagedImage img;
		try {
			img = new ManagedImage(20107321);
			String asserFolder = new String("bpm_windows_image/asset");
			String bpmOwner = new String(
					"src/main/resources/sce_developers.json");
			BPMImageHandler bpmImgHandler = new BPMImageHandler(img, bpmOwner,
					asserFolder);
			bpmImgHandler.process();
		} catch (ManagedImageException e1) {
			e1.printStackTrace();
		} catch (FileNotFoundException e) {
			e.printStackTrace();
		} catch (IOException e) {
			e.printStackTrace();
		} catch (SCEClientException e) {
			e.printStackTrace();
		}

	}

}
