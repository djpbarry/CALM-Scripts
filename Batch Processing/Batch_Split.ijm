// Dave Barry, Francis Crick Institute
// 2018.01.17
// david.barry@crick.ac.uk

// Converts all files in a directory to TIFF - there will be one TIFF file per channel per input file.

macro "Batch Split"{
	
	directory = getDirectory("Choose input files");
	IJ.log("Input: " + directory);
	fileList = getFileList(directory);
	IJ.log(fileList.length + " files.");
	
	outputDirectory = getDirectory("Choose output directory");
	IJ.log("Output: " + outputDirectory);
	
	run("Bio-Formats Macro Extensions");
	setBatchMode(true);
	
	for (i=0; i<fileList.length; i++) {
		file = directory + fileList[i];
		Ext.isThisType(file, thisType);
		if(thisType=="true"){
			IJ.log("\nFile " + file + " is a recognised format - processing.");
			Ext.setId(file);
			Ext.getSizeC(sizeC);
			Ext.getSeriesCount(sCount);
			Ext.getDimensionOrder(dimOrder);
			IJ.log("Number of series: " + sCount);
			IJ.log("Number of channels: " + sizeC);
	
			for(s=1;s<=sCount;s++){
				run("Bio-Formats Importer", "open=[" + file + "] color_mode=Default rois_import=[ROI manager] view=Hyperstack stack_order=" + dimOrder + " use_virtual_stack series_" + s);
				if(sizeC > 1){
					run("Split Channels");
				}
				subDirs = newArray(sizeC);
				for(c=0;c<sizeC;c++){
					subDirs[c] = outputDirectory + "C_" + (c + 1);
					if(!File.exists(subDirs[c])){
						File.makeDirectory(subDirs[c]);
					}
				}
				titles = getList("image.titles");
				for(j=0; j<titles.length; j++){
					selectWindow(titles[j]);
					index = lastIndexOf(titles[j], ".");
					titles[j] = substring(titles[j], 0, index);
					filename = subDirs[j] + File.separator + titles[j] + "_S" + s + "_C" + (j+1) + ".ome.tiff";
					//filename = outputDirectory + titles[j] + "_S" + s + ".ome.tiff";
					//filename = replace(filename, " ", "-");
					IJ.log("Saving " + filename);
					run("Bio-Formats Exporter", "save=[" + filename + "] use compression=Uncompressed");
					close();
				}
			}
			Ext.close();
		} else {
			IJ.log("\nFile " + file + " is not a recognised format - skipping.");
		}
	}
	
	IJ.log("\nFinished");
	showStatus("Finished.");
	setBatchMode(false);
	
	function saveFile(outFile) {
	   run("Bio-Formats Exporter", "save=[" + outFile + "] compression=Uncompressed");
	}
}