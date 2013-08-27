package com.ibm.bpm.sce.test;

import com.ibm.sce.deck.tools.LogHelper;

/**
 * Get BPM profile tuning parameters
 * 
 * @author hqghuang@cn.ibm.com
 */
public class BPMProfileTuning {

	/**
	 * <p>
	 * Title: getTunningParams
	 * </p>
	 * <p>
	 * Description: get BPM profile tuning parameters
	 * </p>
	 * 
	 * @param part_type
	 *        e.g. dmgr, nodeagent, managed.procctr.adv
	 * @return
	 */
	public String getTunningParams(String part_type) {
		// Reset all parameters
		String HEAP_MIN = "Default"; // jvm min heap size (-Xms) in MB
		String HEAP_MAX = "Default"; // jvm max heap size (-Xmx) in MB
		String HEAP_NUR_MIN = "Default"; // min jvm nursery size (-Xmns) in MB
		String HEAP_NUR_MAX = "Default"; // min jvm nursery size (-Xmnx) in MB
		String DEF_POOL_MIN = "Default"; // Default Thread Pool min size
		String DEF_POOL_MAX = "Default"; // Default Thread Pool max size
		String DS_CON_POOL = "Default"; // DataSource Connection pool size (non
										// ME Data sources, about 7 of them)
		String AC_MAX_CONCURRENCY = "Default"; // SCA_WLE_nodeName_server1_AS >
												// Custom properties >
												// maxConcurrency
		String AC_MAX_BATCH_SIZE = "Default"; // SCA_WLE_nodeName_server1_AS >
												// Custom properties >
												// maxBatchSize

		/*
		 * WLE Tuning parameters, such as bpd-queue-capacity and
		 * max-thread-pool-size can be find in <profile>/config/cells/<cell
		 * name>nodes/<nodename>/servers/server1/process-center/config/system/
		 * 80EventManager.xml
		 */
		String BPD_CAPACITY = "Default"; // bpd-queue-capacity value in
											// 80EventManager.xml
		String THREAD_POOL_SIZE = "Default"; // max-thread-pool-size value in
												// 80EventManager.xml
		String APPLY_WLE_SETTING_TO_CLUSTER = "Default"; // do not modify
															// cluster's
															// 80EventManager.xml
															// by default

		// PC specific settings:
		String TW_CLIENT_CF_MAX = "Default"; // max connection of topic
												// connection factory
												// jms/TWClientConnectionFactory
		String CACHE_MESS_CF_MAX = "Default"; // max connection of topic
												// connection factory
												// tw.jms.cacheMessageConnectionFactory
		String CORBA_FRAG_SIZE = "Default"; // com.ibm.CORBA.FragmentSize
											// property of ORB Service

		// Heap Base
		String HEAP_BASE = "Default"; // for jvm option -Xgc:preferredHeapBase
										// for example 0x100000000
		String SEND_EXTERNAL_EMAIL = "Default"; // send external email
		String serverCfgType = getServerConfig();
		LogHelper.printInfo("serverCfgType: " + serverCfgType);
		if (part_type.equals("dmgr")) {
			HEAP_MIN = "256";
			HEAP_MAX = "1024";
		} else if (part_type.equals("nodeagent")) {
			HEAP_MIN = "128";
			HEAP_MAX = "768";
		} else if (serverCfgType.equals(Constants.BRONZE)) {
			HEAP_MIN = "768";
			HEAP_MAX = "2048";
		} else if (serverCfgType.equals(Constants.SILVER)) {
			HEAP_MIN = "2048";
			HEAP_MAX = "3072";
			HEAP_NUR_MIN = "256";
			HEAP_NUR_MAX = "768";

			if (part_type.equals("managed.procctr.adv")) {
				DS_CON_POOL = "100";
				TW_CLIENT_CF_MAX = "60";
				CACHE_MESS_CF_MAX = "60";
			} else {
				DS_CON_POOL = "150";
				BPD_CAPACITY = "40";
				THREAD_POOL_SIZE = "70";
				APPLY_WLE_SETTING_TO_CLUSTER = "true";
			}
			SEND_EXTERNAL_EMAIL = "false";
		} else if (serverCfgType.equals(Constants.GOLD)) {
			HEAP_MIN = "3072";
			HEAP_MAX = "4096";
			HEAP_NUR_MIN = "256";
			HEAP_NUR_MAX = "768";
			DEF_POOL_MIN = "20";
			DEF_POOL_MAX = "40";
			if (part_type.equals("managed.procctr.adv")) {
				DS_CON_POOL = "100";
				TW_CLIENT_CF_MAX = "60";
				CACHE_MESS_CF_MAX = "60";
			} else {
				DS_CON_POOL = "200";
				AC_MAX_CONCURRENCY = "20";
				AC_MAX_BATCH_SIZE = "8";
				BPD_CAPACITY = "80";
				THREAD_POOL_SIZE = "110";
				APPLY_WLE_SETTING_TO_CLUSTER = "true";
			}
			SEND_EXTERNAL_EMAIL = "false";
			HEAP_BASE = "0x100000000";
		} else if (serverCfgType.equals(Constants.PLATINUM)) {
			HEAP_MIN = "3072";
			HEAP_MAX = "4096";
			HEAP_NUR_MIN = "256";
			HEAP_NUR_MAX = "768";
			DEF_POOL_MIN = "20";
			DEF_POOL_MAX = "40";
			if (part_type.equals("managed.procctr.adv")) {
				DS_CON_POOL = "100";
				TW_CLIENT_CF_MAX = "60";
				CACHE_MESS_CF_MAX = "60";
			} else {
				DS_CON_POOL = "200";
				AC_MAX_CONCURRENCY = "20";
				AC_MAX_BATCH_SIZE = "8";
				BPD_CAPACITY = "80";
				THREAD_POOL_SIZE = "110";
				APPLY_WLE_SETTING_TO_CLUSTER = "true";
			}
			SEND_EXTERNAL_EMAIL = "false";
			HEAP_BASE = "0x100000000";
		}

		String tunning_params = HEAP_MIN + " " + HEAP_MAX + " " + HEAP_NUR_MIN
				+ " " + HEAP_NUR_MAX + " " + DEF_POOL_MIN + " " + DEF_POOL_MAX
				+ " " + DS_CON_POOL + " " + AC_MAX_CONCURRENCY + " "
				+ AC_MAX_BATCH_SIZE + " " + BPD_CAPACITY + " "
				+ THREAD_POOL_SIZE + " " + APPLY_WLE_SETTING_TO_CLUSTER + " "
				+ TW_CLIENT_CF_MAX + " " + CACHE_MESS_CF_MAX + " "
				+ CORBA_FRAG_SIZE + " " + HEAP_BASE + " " + SEND_EXTERNAL_EMAIL
				+ " " + part_type;
		return tunning_params;
	}

	private String getServerConfig() {
		int cpu_num = Runtime.getRuntime().availableProcessors();
		LogHelper.printInfo("cpu_num: " + cpu_num);
		switch (cpu_num) {
		case 2:
			return Constants.BRONZE;
		case 4:
			return Constants.SILVER;
		case 8:
			return Constants.GOLD;
		case 16:
			return Constants.PLATINUM;
		default:
			return null;
		}
	}

}
