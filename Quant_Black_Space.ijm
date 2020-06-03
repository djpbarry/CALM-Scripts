// Dave Barry, Francis Crick Institute
// 2018.01.08
// david.barry@crick.ac.uk

// Calculates the proportion of black space in all images in a directory.

macro "Quant Black Space"{
	directory = getArgument();
	if(!File.exists(directory)){
		directory = getDirectory("Choose input files");
	}
	IJ.log("Input: " + directory);
	fileList = getFileList(directory);
	IJ.log(fileList.length + " files.");
	
	run("Bio-Formats Macro Extensions");
	setBatchMode(true);
	for (i=0; i<fileList.length; i++) {
		file = directory + File.separator + fileList[i];
		IJ.log("\nProcessing " + file);
		Ext.setId(file);
		Ext.getSizeC(sizeC);
		Ext.getSeriesCount(sCount);
		IJ.log("Number of series: " + sCount);
		IJ.log("Number of channels: " + sizeC);

		for(s=1;s<=sCount;s++){
			run("Bio-Formats Importer", "open=[" + file + "] color_mode=Default rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT use_virtual_stack series_" + s);			
			if(sizeC > 1){
				run("Split Channels");
			}
			imageSize = getWidth() * getHeight();
			minZero = imageSize;
			titles = getList("image.titles");
			for(j=0; j<titles.length; j++){
				selectWindow(titles[j]);
				getHistogram(values, counts, 256);
				if(counts[0] < minZero){
					minZero = counts[0];
				}
				close();
			}
			setResult("Image Name", nResults(), fileList[i]);
			setResult("Series", nResults() - 1, s);
			setResult("% Black", nResults() - 1, minZero / imageSize);
		}
		Ext.close();
	}
	
	IJ.log("\nFinished");
	showStatus("Finished.");
	setBatchMode(false);
}