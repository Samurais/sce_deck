package com.ibm.sce.deck.tools;

import java.io.*;
import java.util.zip.*;

public class ZipHandler {
	private ZipInputStream zipIn;
	private ZipOutputStream zipOut;
	private ZipEntry zipEntry;
	private static int bufSize;
	private byte[] buf;
	private int readedBytes;

	public ZipHandler() {
		this(512);
	}

	public ZipHandler(int bufSize) {
		this.bufSize = bufSize;
		this.buf = new byte[this.bufSize];
	}

	public String doZip(String zipDirectory) {
		File file;
		File zipDir;

		zipDir = new File(zipDirectory);
		String zipFileName = zipDir.getName() + ".zip";

		try {
			this.zipOut = new ZipOutputStream(new BufferedOutputStream(
					new FileOutputStream(zipFileName)));
			handleDir(zipDir, this.zipOut);
			this.zipOut.close();
		} catch (IOException ioe) {
			ioe.printStackTrace();
		}
		return zipFileName;
	}

	private void handleDir(File dir, ZipOutputStream zipOut) throws IOException {
		FileInputStream fileIn;
		File[] files;

		files = dir.listFiles();

		if (files.length == 0) {
			this.zipOut.putNextEntry(new ZipEntry(dir.toString() + "/"));
			this.zipOut.closeEntry();
		} else {
			for (File fileName : files) {
				if (fileName.isDirectory()) {
					handleDir(fileName, this.zipOut);
				} else {
					fileIn = new FileInputStream(fileName);
					this.zipOut.putNextEntry(new ZipEntry(fileName.toString()));

					while ((this.readedBytes = fileIn.read(this.buf)) > 0) {
						this.zipOut.write(this.buf, 0, this.readedBytes);
					}

					this.zipOut.closeEntry();
				}
			}
		}
	}

	public void unZip(String unZipfileName) {
		FileOutputStream fileOut;
		File file;

		try {
			this.zipIn = new ZipInputStream(new BufferedInputStream(
					new FileInputStream(unZipfileName)));

			while ((this.zipEntry = this.zipIn.getNextEntry()) != null) {
				file = new File(this.zipEntry.getName());

				if (this.zipEntry.isDirectory()) {
					file.mkdirs();
				} else {
					File parent = file.getParentFile();
					if (!parent.exists()) {
						parent.mkdirs();
					}

					fileOut = new FileOutputStream(file);
					while ((this.readedBytes = this.zipIn.read(this.buf)) > 0) {
						fileOut.write(this.buf, 0, this.readedBytes);
					}
					fileOut.close();
				}
				this.zipIn.closeEntry();
			}
		} catch (IOException ioe) {
			ioe.printStackTrace();
		}
	}

	public void setBufSize(int bufSize) {
		this.bufSize = bufSize;
	}

	// public static void main(String[] args) throws Exception {
	// String name = "bpm_windows_image";
	// ZipHandler zip = new ZipHandler();
	//
	// zip.doZip(name);
	// // zip.unZip(name);
	// }
}
