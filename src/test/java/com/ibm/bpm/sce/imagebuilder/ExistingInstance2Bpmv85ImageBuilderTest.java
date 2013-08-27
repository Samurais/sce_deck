package com.ibm.bpm.sce.imagebuilder;

import com.ibm.bpm.sce.imagebuilder.ExistingInstance2Bpmv85ImageBuilder;
import com.ibm.sce.deck.exceptions.ManagedInstanceException;
import junit.framework.TestCase;

public class ExistingInstance2Bpmv85ImageBuilderTest extends TestCase {

	public void testExistingInst2ImageBuilder() {
		// define instance name and bpm installer repo
		String swRepoHost = "170.225.163.85";
		String xInstanceId = "456367";
		String xInstUser = "idcuser";
		String xInstPassword = "pwd4Cloud";
		try {
			ExistingInstance2Bpmv85ImageBuilder xImageBuilder = new ExistingInstance2Bpmv85ImageBuilder(
					xInstanceId, swRepoHost, xInstUser, xInstPassword);
			xImageBuilder.build();

		} catch (ManagedInstanceException e) {
			e.printStackTrace();
		}

	}

}
