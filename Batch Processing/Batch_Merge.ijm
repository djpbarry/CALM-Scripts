// Dave Barry, Francis Crick Institute
// 2017.11.23
// david.barry@crick.ac.uk

// Merges TIFF files representing individual channels into a single compositite TIFF.
// Input files should be presented in a single directory,  with one subdirectory for
// each channel to be merged.

macro "Batch Merge" {

	directory = getDirectory("Choose location of input directories");
	IJ.log("Input: " + directory);
	dirList = getFileList(directory);
	IJ.log(dirList.length + " directories.");
	
	outputDirectory = getDirectory("Choose output directory");
	IJ.log("Output: " + outputDirectory);
	IJ.log("");
	
	run("Bio-Formats Macro Extensions");
	setBatchMode(true);
	
	c1fileList = getFileList(directory + dirList[0]);
	
	for (i=0; i<c1fileList.length; i++) {
		titles = newArray(dirList.length);
		for(c=0; c<dirList.length; c++){
			fileList = getFileList(directory + dirList[c]);
			file = directory + dirList[c] + fileList[i];
			Ext.setId(file);
			Ext.openImagePlus(file);
			IJ.log("Processing " + file);
			index = lastIndexOf(file, ".");
			titles[c] = substring(file, 0, index);
			rename(titles[c]);
		}
		IJ.log("");
		params = "";
		for(c=0;c<titles.length;c++){
			params = params + "c"+(c+1)+"=["+titles[c]+"] ";
		}
		run("Merge Channels...", params + "create");
		mergeTitles = getList("image.titles");
		selectWindow(mergeTitles[0]);
		filename = outputDirectory + File.getName(titles[0]) + "_Merge.tiff";
		IJ.log("Saving " + filename + "\n");
		IJ.log("");
		saveAs("TIFF", filename);
		close();
	}
	IJ.log("Finished");
	showStatus("Finished.");
	setBatchMode(false);
	
	function saveFile(outFile) {
	   run("Bio-Formats Exporter", "save=[" + outFile + "] compression=Uncompressed");
	}
}