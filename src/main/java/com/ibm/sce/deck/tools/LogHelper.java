package com.ibm.sce.deck.tools;

import java.io.File;
import java.io.IOException;
import java.util.logging.ConsoleHandler;
import java.util.logging.FileHandler;
import java.util.logging.Formatter;
import java.util.logging.Level;
import java.util.logging.LogRecord;
import java.util.logging.Logger;

import com.ibm.bpm.sce.test.Constants;
import com.ibm.bpm.sce.test.TestResult;

/**
 * Simple Logger for bpm test
 * 
 * @author hqghuang@cn.ibm.com
 */
public class LogHelper {

	private static Logger LOGGER = Logger.getLogger("com.ibm.sce.deck.tools");
	private static LogHelper logHelper = null;

	public static LogHelper getInstance() {
		if (logHelper == null) {
			logHelper = new LogHelper();
		}
		return logHelper;
	}

	private LogHelper() {
		initialize();
	}

	/**
	 * <p>
	 * Title: initialize
	 * </p>
	 * <p>
	 * Description: initialize log
	 * </p>
	 * 
	 */
	private void initialize() {
		String path = "";
		String jarDir = FileUtil.getDirFromClassLoader();
		if (jarDir == null) {
			path = System.getProperty("user.dir");
		} else {
			path = jarDir.substring(0, jarDir.lastIndexOf(File.separator));
		}
		File file = new File(path, "logs");
		if (!file.exists()){
			file.mkdir();
		}
		File logFile = new File(file, Constants.LOG_NAME);
		if (!logFile.exists()) {
			try {
				logFile.createNewFile();
			} catch (IOException e) {
				e.printStackTrace();
			}
		}
		ConsoleHandler consoleHandler = new ConsoleHandler();
		consoleHandler.setLevel(Level.INFO);
		consoleHandler.setFormatter(new MyFormatter());
		FileHandler fileHandler = null;
		try {
			fileHandler = new FileHandler(logFile.getAbsolutePath(), true);
		} catch (IOException e) {
			e.printStackTrace();
		}
		fileHandler.setLevel(Level.INFO);
		fileHandler.setFormatter(new MyFormatter());

		LOGGER.addHandler(consoleHandler);
		LOGGER.addHandler(fileHandler);
	}

	private class MyFormatter extends Formatter {
		@Override
		public String format(LogRecord record) {
			return record.getLevel() + ": " + record.getMessage() + "\n";
		}
	}

	public void log(String msg) {
		LOGGER.info(msg);
	}

	public void log(String msg, TestResult tr, TestResult.Status status) {
		if (status.equals(TestResult.Status.SUCCESS)) {
			LOGGER.info(Constants.SUCCESS + msg);
			tr.addSuccessCase(Constants.SUCCESS + msg);
		} else if (status.equals(TestResult.Status.FAILED)) {
			LOGGER.info(Constants.FAILED + msg);
			tr.addFailedCase(Constants.FAILED + msg);
		} else if (status.equals(TestResult.Status.WARNING)) {
			LOGGER.info(Constants.WARNING + msg);
			tr.addWarningCase(Constants.WARNING + msg);
		}
	}

	public void log(Level level, String msg) {
		LOGGER.log(level, msg);
	}

	public static void printInfo(Object message) {
		System.out.println(message);
	}
}
