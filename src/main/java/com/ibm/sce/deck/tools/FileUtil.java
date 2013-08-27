package com.ibm.sce.deck.tools;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;
import java.net.URL;
import java.util.ArrayList;
import java.util.List;
import java.util.zip.ZipEntry;
import java.util.zip.ZipOutputStream;

import com.ibm.bpm.sce.test.Constants;

/**
 * 
 * @author hqghuang@cn.ibm.com
 */
public class FileUtil {

	public static String getJarDir() {
		String path = getDirFromClassLoader();
		if (path == null) {
			path = System.getProperty("user.dir");
		}
		return path;
	}

	/**
	 * <p>
	 * Title: getDirFromClassLoader
	 * </p>
	 * <p>
	 * Description: getDirFromClassLoader
	 * </p>
	 * 
	 * @return
	 */
	public static String getDirFromClassLoader() {
		try {
			String path = FileUtil.class.getName().replace(".", "/");
			path = "/" + path + ".class";
			URL url = FileUtil.class.getResource(path);
			String jarUrl = url.getPath();
			if (jarUrl.startsWith("file:")) {
				if (jarUrl.length() > 5) {
					jarUrl = jarUrl.substring(5);
				}
				jarUrl = jarUrl.split("!")[0];

			} else {
				jarUrl = FileUtil.class.getResource("/").toString()
						.substring(5);
			}
			File file = new File(jarUrl);
			return file.getParent();

		} catch (Exception e) {
		}
		return null;
	}

	/**
	 * <p>
	 * Title: find
	 * </p>
	 * <p>
	 * Description: find string
	 * </p>
	 * 
	 * @param dir
	 * @param suffix
	 * @return
	 */
	public static List<String> find(String dir, String suffix) {
		List<String> list = new ArrayList<String>();
		try {
			File file = new File(dir);
			if (file.exists() && file.isDirectory()) {
				find(file, suffix, list);
			} else {
				throw new IllegalArgumentException(
						"param \"dir\" must be an existing directory .dir = "
								+ dir);
			}
		} catch (Exception e) {
			e.printStackTrace();
		}
		return list;
	}

	/**
	 * <p>
	 * Title: find
	 * </p>
	 * <p>
	 * Description: find string
	 * </p>
	 * 
	 * @param dirFile
	 * @param suffix
	 * @param list
	 */
	private static void find(File dirFile, String suffix, List<String> list) {
		if (dirFile.exists() && dirFile.isDirectory()) {
			File[] subFiles = dirFile.listFiles();
			for (File subFile : subFiles) {
				if (subFile.isDirectory()) {
					find(subFile, suffix, list);
				} else {
					String path = subFile.getAbsolutePath();
					if (path.endsWith(suffix)) {
						list.add(path);
					}
				}
			}
		} else {
			throw new IllegalArgumentException(
					"param \"dir\" must be an existing directory .dir = "
							+ dirFile.getAbsolutePath());
		}
	}

	/**
	 * <p>
	 * Title: createZip
	 * </p>
	 * <p>
	 * Description: create Zip file
	 * </p>
	 * 
	 * @param sourcePath
	 * @param zipPath
	 */
	public static void createZip(String sourcePath, String zipPath) {
		FileOutputStream fos = null;
		ZipOutputStream zos = null;
		try {
			fos = new FileOutputStream(zipPath);
			zos = new ZipOutputStream(fos);
			writeZip(new File(sourcePath), "", zos);
		} catch (FileNotFoundException e) {
			e.printStackTrace();
		} finally {
			try {
				if (zos != null) {
					zos.close();
				}
			} catch (IOException e) {
				e.printStackTrace();
			}

		}
	}

	/**
	 * <p>
	 * Title: writeZip
	 * </p>
	 * <p>
	 * Description: write Zip file
	 * </p>
	 * 
	 * @param file
	 * @param parentPath
	 * @param zos
	 */
	private static void writeZip(File file, String parentPath,
			ZipOutputStream zos) {
		if (file.exists()) {
			if (file.isDirectory()) {
				parentPath += file.getName() + File.separator;
				File[] files = file.listFiles();
				for (File f : files) {
					writeZip(f, parentPath, zos);
				}
			} else {
				FileInputStream fis = null;
				try {
					if (file.getName().endsWith("zip")) {
						return;
					}
					fis = new FileInputStream(file);
					ZipEntry ze = new ZipEntry(parentPath + file.getName());
					zos.putNextEntry(ze);
					byte[] content = new byte[1024];
					int len;
					while ((len = fis.read(content)) != -1) {
						zos.write(content, 0, len);
						zos.flush();
					}

				} catch (Exception e) {
					e.printStackTrace();
				} finally {
					try {
						if (fis != null) {
							fis.close();
						}
					} catch (IOException e) {
						e.printStackTrace();
					}
				}
			}
		}
	}

	/**
	 * <p>
	 * Title: writeFile
	 * </p>
	 * <p>
	 * Description: write file
	 * </p>
	 * 
	 * @param file
	 * @param content
	 */
	public static void writeFile(File file, String content) {
		try {
			BufferedWriter output = new BufferedWriter(new FileWriter(file, true));
			if (!content.endsWith("\n")){
				content += "\n";
			}
			output.write(content);
			output.close();
		} catch (Exception e) {
			e.printStackTrace();
		}
	}

	/**
	 * <p>
	 * Title: generateReport
	 * </p>
	 * <p>
	 * Description: generate report
	 * </p>
	 * 
	 * @param result
	 */
	public static void generateReport(String result) {
		File file = null;
		String path = "";
		String jarDir = getDirFromClassLoader();
		if (jarDir == null) {
			path = System.getProperty("user.dir");
		} else {
			path = jarDir.substring(0, jarDir.lastIndexOf(File.separator));
		}
		file = new File(path, Constants.RESULT_LOG);
		if (!file.exists()) {
			try {
				file.createNewFile();
			} catch (IOException e) {
				e.printStackTrace();
			}
		}
		writeFile(file, result);
	}

	/**
	 * <p>
	 * Title: printResult
	 * </p>
	 * <p>
	 * Description: print result
	 * </p>
	 * 
	 * @return
	 */
	public static String printResult() {
		File file = null;
		String path = "";
		String jarDir = getDirFromClassLoader();
		if (jarDir == null) {
			path = System.getProperty("user.dir");
		} else {
			path = jarDir.substring(0, jarDir.lastIndexOf(File.separator));
		}
		file = new File(path, Constants.RESULT_LOG);

		try {
			String line = "";
			StringBuffer sb = new StringBuffer();
			BufferedReader input = new BufferedReader(new FileReader(file));
			while ((line = input.readLine()) != null) {
				sb.append(line + "\n");
			}
			input.close();
			return sb.toString();
		} catch (Exception e) {
			e.printStackTrace();
		}
		return "";
	}

	/**
	 * <p>
	 * Title: readFile
	 * </p>
	 * <p>
	 * Description: readFile
	 * </p>
	 * 
	 * @param file
	 * @return
	 */
	public static String readFile(File file) {
		try {
			String line = "";
			StringBuffer sb = new StringBuffer();
			BufferedReader input = new BufferedReader(new FileReader(file));
			while ((line = input.readLine()) != null) {
				if (!line.endsWith("\n")){
					line += "\n";
				} 
				sb.append(line);
			}
			input.close();
			return sb.toString();
		} catch (Exception e) {
			e.printStackTrace();
		}
		return "";
	}

}
