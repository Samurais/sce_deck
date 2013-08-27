package com.ibm.sce.deck.tools;

import java.io.File;
import java.util.logging.Level;

import org.eclipse.core.runtime.NullProgressMonitor;

import com.ibm.cloud.cmd.tool.PasswordFileProcessor;
import com.ibm.cloud.cmd.tool.Security.EncryptionException;
import com.ibm.cloud.cmd.tool.exception.FileOperationException;
import com.ibm.cloud.cmd.tool.exception.UserNameNotMatchedException;
import com.ibm.ram.client.LocalFileArtifact;
import com.ibm.ram.client.LocalFolderArtifact;
import com.ibm.ram.client.RAMAsset;
import com.ibm.ram.client.RAMFolderArtifact;
import com.ibm.ram.client.RAMSession;
import com.ibm.ram.common.data.Artifact;
import com.ibm.ram.common.data.AssetAttribute;
import com.ibm.ram.common.data.AssetIdentification;
import com.ibm.ram.common.data.UserInformation;
import com.ibm.sce.deck.exceptions.ManagedImageException;
import com.ibm.sce.deck.exceptions.SCEClientException;

/**
 * @author Hai Liang BJ Wang/China/IBM Jul 31, 2013
 */
public class ManagedImageAsset {
	private static ManagedProperties mgrProps = new ManagedProperties();
	private static ManagedLogger logger = ManagedLogger.getInstance();
	private static final String className = ManagedImageAsset.class.getName();
	private static final String LS = System.getProperty("line.separator");
	private static String userName;
	private static String password;

	/**
	 * <p>
	 * Title:
	 * </p>
	 * <p>
	 * Description:
	 * </p>
	 * 
	 * @throws SCEClientException
	 */
	public ManagedImageAsset() throws SCEClientException {
		try {
			userName = mgrProps.getProperty("sce_account_username");
			if (mgrProps.getProperty("sce_account_has_passphrase")
					.equalsIgnoreCase("true")) {
				String unlockPassphrase = mgrProps
						.getProperty("sce_account_unlock_passphrase");
				String filePath = mgrProps
						.getProperty("sce_account_lock_file_path");

				password = PasswordFileProcessor.getRealPassword(
						unlockPassphrase, filePath, userName);

			} else {
				password = mgrProps.getProperty("sce_account_pwd");
			}
			if (password.isEmpty() || (password == null)
					|| (userName.isEmpty()) || (userName == null)) {
				logger.err(ManagedClient.class.getName(),
						">> Failure to get user info for account ");
				throw new SCEClientException(SCEClientException.NOUSER);
			}
		} catch (FileOperationException e) {
			e.printStackTrace();
		} catch (EncryptionException e) {
			e.printStackTrace();
		} catch (UserNameNotMatchedException e) {
			e.printStackTrace();
		}

	}

	/**
	 * <p>
	 * Title: getRAMSession
	 * </p>
	 * <p>
	 * Description: return an RAMSession using properties in
	 * managed_sce.properties
	 * </p>
	 * 
	 * @return
	 */
	private RAMSession getRAMSession() {
		RAMSession session = null;
		/*
		 * connect session
		 */
		try {
			session = new RAMSession(ManagedConstants.SCE_RAM_ENDPOINT,
					userName, password);
		} catch (Exception e) {
			logger.err(className, Level.SEVERE + "Error connecting"
					+ e.toString());
		}
		return session;

	}

	/**
	 * <p>
	 * Title: getAsset
	 * </p>
	 * <p>
	 * Description: get an image asset by asset id
	 * </p>
	 * 
	 * @param guid
	 *            The RAM Asset globally unique identifier
	 * @return RAMAsset image asset
	 */
	public RAMAsset getAsset(final String guid) {
		RAMSession session = getRAMSession();
		RAMAsset asset = null;
		/*
		 * get asset
		 */
		if (session != null) {
			try {
				AssetIdentification assetID = new AssetIdentification();
				assetID.setGUID(guid);
				asset = session.getAsset(assetID);

				// System.out.println(Level.INFO + "Got asset " +
				// asset.getName()
				// + " with ID " + asset.getAssetAttribute("Image Id"));
				AssetAttribute[] assetAttributes = asset.getAssetAttributes();
				StringBuilder sb = new StringBuilder();
				for (int i = 0; i < assetAttributes.length; i++) {
					StringBuilder valueString = new StringBuilder();
					String[] values = assetAttributes[i].getValues();
					if (values != null) {
						for (int j = 0; j < values.length; j++) {
							valueString.append(values[j] + " ");
						}
					}
					sb.append(assetAttributes[i].getName() + " : "
							+ valueString + LS);
				}
			} catch (Exception e) {
				System.out.println(Level.SEVERE + "Error getting asset"
						+ e.toString());
			} finally {
				session.release();
			}
		}
		return asset;
	}

	/**
	 * <p>
	 * Title: resetAssetName
	 * </p>
	 * <p>
	 * Description: reset asset name by id
	 * </p>
	 * 
	 * @param guid
	 * @param assetName
	 * @return true if set the name successfully.
	 */
	public boolean resetAssetName(final String guid, final String assetName) {
		boolean succ = false;
		RAMSession session = getRAMSession();
		if (session != null) {
			try {
				AssetIdentification assetID = new AssetIdentification();
				assetID.setGUID(guid);
				RAMAsset asset = session.getAsset(assetID);
				logger.debug(className, "reset asset name to " + assetName);
				asset.setName(assetName);
				session.put(asset, new NullProgressMonitor());
				succ = true;
			} catch (Exception e) {
				logger.err(className, "Error getting asset" + e.toString());
			} finally {
				session.release();
			}
		}
		return succ;
	}

	/**
	 * <p>
	 * Title: resetCommunityName
	 * </p>
	 * <p>
	 * Description:
	 * </p>
	 * 
	 * @param guid
	 * @param communityName
	 *            "Cloud Computing Private Image Community" FOR PRIVATE and
	 *            "Primary Enterprise Community 20000427" for SHARED
	 * @return
	 */
	public boolean resetCommunityName(final String guid,
			final String communityName) {
		boolean succ = false;
		RAMSession session = getRAMSession();
		if (session != null) {
			try {
				AssetIdentification assetID = new AssetIdentification();
				assetID.setGUID(guid);
				RAMAsset asset = session.getAsset(assetID);
				logger.debug(className, "change asset Community to "
						+ communityName);
				asset.setCommunityName(communityName);
				session.put(asset, new NullProgressMonitor());
				succ = true;
			} catch (Exception e) {
				logger.err(className, "Error getting asset" + e.toString());
			} finally {
				session.release();
			}
		}
		return succ;
	}

	/**
	 * <p>
	 * Title: addOwners
	 * </p>
	 * <p>
	 * Description: add owner list
	 * </p>
	 * 
	 * @param guid
	 * @param owners
	 * @return
	 * 
	 *         TODO add owner to asset
	 */
	public boolean addOwner(final String guid, final UserInformation owner) {
		boolean succ = false;
		RAMSession session = getRAMSession();
		if (session != null) {
			try {
				AssetIdentification assetID = new AssetIdentification();
				assetID.setGUID(guid);
				RAMAsset asset = session.getAsset(assetID);
				UserInformation[] usrs = asset.getOwners();
				UserInformation[] updatedUsrs = new UserInformation[usrs.length + 1];
				for (int i = 0; i < usrs.length; i++) {
					updatedUsrs[i] = usrs[i];
				}
				updatedUsrs[usrs.length] = owner;
				asset.setOwners(updatedUsrs);
				session.put(asset, new NullProgressMonitor());
				succ = true;
			} catch (Exception e) {
				logger.err(className, "Error getting asset" + e.toString());
			} finally {
				session.release();
			}
		}
		return succ;

	}

	/**
	 * <p>
	 * Title: addOwners
	 * </p>
	 * <p>
	 * Description: add owner list
	 * </p>
	 * 
	 * @param guid
	 * @param owners
	 * @return
	 * 
	 *         TODO add owner to asset
	 */
	public UserInformation[] getOwners(final String guid) {
		RAMSession session = getRAMSession();
		UserInformation[] usrs = null;
		if (session != null) {
			try {
				AssetIdentification assetID = new AssetIdentification();
				assetID.setGUID(guid);
				RAMAsset asset = session.getAsset(assetID);
				usrs = asset.getOwners();
			} catch (Exception e) {
				logger.err(className, "Error getting asset" + e.toString());
			} finally {
				session.release();
			}
		}
		return usrs;
	}

	/**
	 * <p>
	 * Title: uploadFile2AssetContent
	 * </p>
	 * <p>
	 * Description: RAM API Online -
	 * https://www-147.ibm.com/cloud/enterprise/ram
	 * .help/index.jsp?topic=/com.ibm.ram.doc/topics/t_using_api.html
	 * </p>
	 * 
	 * @param guid
	 * @param sourceFilePath
	 * @return
	 */
	public boolean uploadFile2AssetContent(String guid, String sourceFilePath) {
		boolean succ = false;
		RAMSession session = getRAMSession();
		if (session != null) {
			try {
				AssetIdentification assetID = new AssetIdentification();
				assetID.setGUID(guid);
				RAMAsset asset = session.getAsset(assetID);
				RAMFolderArtifact root = (RAMFolderArtifact) asset
						.getArtifactsRoot();

				// Create an artifact from a single file
				File file = new File(sourceFilePath);
				LocalFileArtifact fileArtifact = new LocalFileArtifact(file);
				// fileArtifact.setName(targetFilePath);
				root.addArtifact(fileArtifact);
				asset.setArtifactsRoot(root);

				// Create URL artifacts
				// RAMURLArtifact ibmLink = new RAMURLArtifact(
				// "http://www.example.com");
				// ibmLink.setName("IBM");
				// root.addArtifact("links", ibmLink);

				logger.debug(className, guid + " update content - "
						+ sourceFilePath);
				session.put(asset, new NullProgressMonitor());
				succ = true;
			} catch (Exception e) {
				logger.err(className, "Error getting asset" + e.toString());
			} finally {
				session.release();
			}
		}
		return succ;

	}

	/**
	 * <p>
	 * Title: removeAllContents4Asset
	 * </p>
	 * <p>
	 * Description: remove all the artifacts in Asset
	 * </p>
	 */
	public void removeAllContents4Asset(String guid) {
		boolean succ = false;
		RAMSession session = getRAMSession();
		if (session != null) {
			try {
				AssetIdentification assetID = new AssetIdentification();
				assetID.setGUID(guid);
				RAMAsset asset = session.getAsset(assetID);
				RAMFolderArtifact root = (RAMFolderArtifact) asset
						.getArtifactsRoot();
				// Create folder artifact to include all the files in the folder
				logger.debug(className, guid + "delete all contents in asset");
				Artifact[] arts = root.getChildren();
				for (int i = 0; i < arts.length; i++) {
					root.removeArtifact(arts[i]);
				}
				asset.setArtifactsRoot(root);
				session.put(asset, new NullProgressMonitor());
				succ = true;
			} catch (Exception e) {
				logger.err(className, "Error getting asset" + e.toString());
			} finally {
				session.release();
			}
		}
	}

	/**
	 * <p>
	 * Title: uploadFolder2AssetContent
	 * </p>
	 * <p>
	 * Description: Upload a folder into an Asset as Contents. RAM API Online -
	 * https://www-147.ibm.com/cloud/enterprise/ram
	 * .help/index.jsp?topic=/com.ibm.ram.doc/topics/t_using_api.html
	 * </p>
	 * 
	 * @param guid
	 * @param sourceFilePath
	 * @return
	 */
	public boolean uploadFolder2AssetContent(String guid,
			String sourceFolderPath) {
		boolean succ = false;
		RAMSession session = getRAMSession();
		if (session != null) {
			try {
				AssetIdentification assetID = new AssetIdentification();
				assetID.setGUID(guid);
				RAMAsset asset = session.getAsset(assetID);
				RAMFolderArtifact root = (RAMFolderArtifact) asset
						.getArtifactsRoot();
				// Create folder artifact to include all the files in the folder
				logger.debug(className, guid
						+ "upload a folder into an Asset as Contents - "
						+ sourceFolderPath);
				File folder = new File(sourceFolderPath);
				LocalFolderArtifact folderArtifact = new LocalFolderArtifact(
						folder);
				root.addArtifact(folderArtifact);
				asset.setArtifactsRoot(root);

				// Create URL artifacts
				// RAMURLArtifact ibmLink = new RAMURLArtifact(
				// "http://www.example.com");
				// ibmLink.setName("IBM");
				// root.addArtifact("links", ibmLink);

				session.put(asset, new NullProgressMonitor());
				succ = true;
			} catch (Exception e) {
				logger.err(className, "Error getting asset" + e.toString());
			} finally {
				session.release();
			}
		}
		return succ;

	}

	/**
	 * <p>
	 * Title: uploadAssetContent
	 * </p>
	 * <p>
	 * Description: upload content into Asset with a whole folder
	 * </p>
	 * 
	 * @param guid
	 * @param sourceFolderPath
	 * @throws ManagedImageException
	 */
	public void uploadAssetContentTotally(final String guid,
			final String sourceFolderPath) throws ManagedImageException {
		File folder = new File(sourceFolderPath);
		if (folder.exists()) {
			logger.info(className, "upload the asset folder as a whole -"
					+ sourceFolderPath);
			removeAllContents4Asset(guid);
			String[] strs = folder.list();
			for (int i = 0; i < strs.length; i++) {
				String candidatePath = new String(sourceFolderPath
						+ File.separatorChar + strs[i]);
				File candicate = new File(candidatePath);
				if (!candicate.isHidden()) {
					/*
					 * folder
					 */
					if (candicate.isDirectory()) {
						uploadFolder2AssetContent(guid, candidatePath);
					}
					/*
					 * file
					 */
					if (candicate.isFile()) {
						uploadFile2AssetContent(guid, candidatePath);
					}
				}
				candicate = null;
				candidatePath = null;
			}
		} else {
			throw new ManagedImageException(
					ManagedImageException.ASSET_LOCAL_FOLDER_NOT_EXIST);
		}
	}

	/**
	 * Example usage: java com.ibm.cloud.example.ram.RAMClient Guid
	 */
	public static void main(String[] args) {
		ManagedImageAsset client;
		/**
		 * add owner
		 */
		// try {
		// client = new ManagedRAMSession();
		// String guid = "DEAF1418-F923-FDEF-5C3C-B5E1DC702942";
		// // owner
		// UserInformation usr = new UserInformation();
		// usr.setEmail("qianfeng@cn.ibm.com");
		// usr.setImageURL("/theme/images/dummyImage.jpg");
		// usr.setName("Qian Feng");
		// usr.setUid("qianfeng@cn.ibm.com");
		//
		// client.addOwner(guid, usr);
		//
		// } catch (SCEClientException e) {
		// e.printStackTrace();
		// }
		/**
		 * get owner
		 */
		// try {
		// client = new ManagedRAMSession();
		// String guid = "DEAF1418-F923-FDEF-5C3C-B5E1DC702942";
		// String communityName = "Primary Enterprise Community 20000427";
		// System.out.println(client.getOwners(guid).length);
		//
		// } catch (SCEClientException e) {
		// e.printStackTrace();
		// }
		/**
		 * update contents
		 */
		// try {
		// client = new ManagedRAMSession();
		// String guid = "DEAF1418-F923-FDEF-5C3C-B5E1DC702942";
		// String sourceFilePath = "src/main/resources/sce_developers.json";
		// String targetFilePath = "sce_developers.json";
		// client.updateContent(guid, sourceFilePath, targetFilePath);
		// } catch (SCEClientException e) {
		// // TODO Auto-generated catch block
		// e.printStackTrace();
		// }
		/**
		 * update folder
		 */
		try {
			client = new ManagedImageAsset();
			String guid = "DEAF1418-F923-FDEF-5C3C-B5E1DC702942";
			String sourceFilePath = "src/main/resources/assets/bpm_85_windows_image";
			try {
				client.uploadAssetContentTotally(guid, sourceFilePath);
			} catch (ManagedImageException e) {
				e.printStackTrace();
			}
		} catch (SCEClientException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}

	}

}
