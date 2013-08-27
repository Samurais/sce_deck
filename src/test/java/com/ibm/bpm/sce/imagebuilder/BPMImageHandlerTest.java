package com.ibm.bpm.sce.imagebuilder;

import java.io.FileNotFoundException;
import java.io.IOException;

import com.ibm.sce.deck.exceptions.ManagedImageException;
import com.ibm.sce.deck.exceptions.SCEClientException;
import com.ibm.sce.deck.resources.ManagedImage;

import junit.framework.TestCase;

public class BPMImageHandlerTest extends TestCase {

	public void testProcessImage() {

		ManagedImage img;
		try {
			img = new ManagedImage(20108298);
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
