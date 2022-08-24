/*
 * Simple script to convert Luxendo outputs into more friendly formats for visualisation and exploration 
 * 
 * Dave Barry 26.04.2022
 * david.barry@crick.ac.uk
 * 
 * 
*/

var title = "Luxendo File Converter";

macro "Luxendo File Converter"{
	print("\\Clear");

	Dialog.create(title);
	Dialog.addDirectory("Input", getDirectory("cwd"));
	Dialog.addDirectory("Output", getDirectory("cwd"));
	Dialog.addMessage("");
	Dialog.addCheckbox("Generate Converted Files?", false);
	Dialog.addToSameRow();
	Dialog.addChoice("Select File Type:", newArray("BigDataViewer", "OME-TIFF"), "OME-TIFF");
	Dialog.addMessage("");
	Dialog.addCheckbox("Generate Projections?", false);
	Dialog.addToSameRow();
	Dialog.addChoice("Select Projection Type:", newArray("sum", "max"), "max");
	Dialog.addMessage("");
	Dialog.addCheckbox("Generate Downsampled Volumes?", false);
	Dialog.addToSameRow();
	Dialog.addNumber("Downsample factor in X and Y:", 1);
	Dialog.addToSameRow();
	Dialog.addNumber("Downsample factor in Z:", 1);
	Dialog.show();
	
	input = Dialog.getString();
	output = Dialog.getString();
	convert = Dialog.getCheckbox();
	fileType = Dialog.getChoice();
	proj = Dialog.getCheckbox();
	projType = Dialog.getChoice();
	down = Dialog.getCheckbox();
	downXY = Dialog.getNumber();
	downZ = Dialog.getNumber();
	
	nCPUs = parseInt(call("ij.util.ThreadUtil.getNbCpus"));
	///regex = ".*/[sS]tack_0_(?<C1>[cC]hannel_.*)/(?<C2>Cam_.*)_(?<T>\\d+)(|.lux).h5";
	regex = "(?<C2>Cam_.*)_(?<T>\\d+)(|.lux).h5";
	stack = "_stack_0_";

	channelsubset = newArray(0);
	
	channelsubset = listFiles(input, channelsubset);
	
	channels = "";
	
	for (i = 0; i < channelsubset.length; i++) {
		channels = channels + channelsubset[i] + ",";
	}
	
	run("BDP2 Open Position And Channel Subset...", "viewingmodality=[Do not show] directory=[" + input + "] enablearbitraryplaneslicing=false regexp=[.*/[sS]tack_0_(?<C1>[cC]hannel_.*)/(?<C2>Cam_.*)_(?<T>\\d+)(|.lux).h5] channelsubset=[" + channels + "] ");
		
	nT = getNumberofTimepoints() - 1;
	
	nC = getNumberofChannels() - 1;
	
	if(proj){
		run("BDP2 Save As...", "inputimage=[raw] directory=[" + output + "] numiothreads=1 numprocessingthreads=" + nCPUs + " filetype=[TIFFVolumes] saveprojections=true projectionmode=[" + projType + "] savevolumes=false channelnames=[Channel index (C00, C01, ...)] tiffcompression=[LZW] tstart=0 tend=" + nT + " ");
	}
	if(convert && matches(fileType, "BigDataViewer")){
		run("BDP2 Save As...", "inputimage=[raw] directory=[" + output + "] numiothreads=1 numprocessingthreads=" + nCPUs + " filetype=[BigDataViewerXMLHDF5] saveprojections=false projectionmode=[" + projType + "] savevolumes=true channelnames=[Channel index (C00, C01, ...)] tiffcompression=[None] tstart=0 tend=" + nT + " ");
	}
	if(convert && matches(fileType, "OME-TIFF")){
		run("BDP2 Save As...", "inputimage=[raw] directory=[" + output + "] numiothreads=1 numprocessingthreads=" + nCPUs + " filetype=[TIFFVolumes] saveprojections=false projectionmode=[" + projType + "] savevolumes=true channelnames=[Channel index (C00, C01, ...)] tiffcompression=[LZW] tstart=0 tend=" + nT + " ");
	}
	if(down){
		run("BDP2 Bin...", "inputimage=[raw] outputimagename=[raw-bin-" + downXY + "-" + downZ + "] viewingmodality=[Do not show] binwidthxpixels=" + downXY + " binwidthypixels=" + downXY + " binwidthzpixels=" + downZ + " ");
		run("BDP2 Save As...", "inputimage=[raw-bin-" + downXY + "-" + downZ + "] directory=[" + output + "] numiothreads=1 numprocessingthreads=" + nCPUs + " filetype=[TIFFVolumes] saveprojections=false projectionmode=[" + projType + "] savevolumes=true channelnames=[Channel index (C00, C01, ...)] tiffcompression=[LZW] tstart=0 tend=" + nT + " ");
	}
}


function listFiles(dir, result) {
     list = getFileList(dir);
     for (i=0; i<list.length; i++) {
     	fullPath = dir + File.separator() + list[i];
        if (File.isDirectory(fullPath)){
           result = listFiles(fullPath, result);
        } else if (matches(list[i], regex)){
			result = Array.concat(result, substring(File.getName(File.getParent(fullPath)), lengthOf(stack) - 1) + "_"
			+ substring(list[i], 0, lastIndexOf(list[i], "_")));
        }
     }
     return result;
  }
  
function getNumberofTimepoints(){
	logWindow = split(getInfo("log"), "\n");

	for (i = 0; i < logWindow.length; i++) {
		line = split(logWindow[i], ":");
		if(startsWith(line[0], "nT") > 0){
			return parseInt(line[1]);
		}
	}
	return -1;
}

function getNumberofChannels(){
	logWindow = split(getInfo("log"), "\n");

	for (i = 0; i < logWindow.length; i++) {
		line = split(logWindow[i], ":");
		if(startsWith(line[0], "nC") > 0){
			return parseInt(line[1]);
		}
	}
	return -1;
}