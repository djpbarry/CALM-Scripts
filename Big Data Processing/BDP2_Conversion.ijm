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
	Dialog.addMessage("Select Output Formats:");
	Dialog.addCheckboxGroup(1, 3, newArray("BigDataViewer", "OME-TIFF"), newArray(false, false));
	Dialog.addChoice("Generate Projections", newArray("sum", "max"), "max");
	Dialog.show();
	
	input = Dialog.getString();
	output = Dialog.getString();
	bdv = Dialog.getCheckbox();
	tiff = Dialog.getCheckbox();
	proj = Dialog.getChoice();
	
	nCPUs = parseInt(call("ij.util.ThreadUtil.getNbCpus"));
	regex = ".*/[sS]tack_0_(?<C1>[cC]hannel_.*)/(?<C2>Cam_.*)_(?<T>\\d+)(|.lux).h5";
	stack = "_stack_0_";

	channelsubset = newArray(0);
	
	channelsubset = listFiles(input, channelsubset);
	
	channels = "";
	
	for (i = 0; i < channelsubset.length; i++) {
		channels = channels + channelsubset[i] + ",";
	}
	
	run("BDP2 Open Position And Channel Subset...", "viewingmodality=[Do not show] directory=[" + input + "] enablearbitraryplaneslicing=false regexp=[.*/[sS]tack_0_(?<C1>[cC]hannel_.*)/(?<C2>Cam_.*)_(?<T>\\d+)(|.lux).h5] channelsubset=[" + channels + "] ");
	
	nT = getNumberofTimepoints() - 1;
	
	run("BDP2 Save As...", "inputimage=[raw] directory=[" + output + "] numiothreads=1 numprocessingthreads=" + nCPUs + " filetype=[TIFFVolumes] saveprojections=true projectionmode=[" + proj + "] savevolumes=false channelnames=[Channel index (C00, C01, ...)] tiffcompression=[LZW] tstart=0 tend=" + nT + " ");
	
	if(bdv){
		run("BDP2 Save As...", "inputimage=[raw] directory=[" + output + "] numiothreads=1 numprocessingthreads=" + nCPUs + " filetype=[BigDataViewerXMLHDF5] saveprojections=false projectionmode=[" + proj + "] savevolumes=true channelnames=[Channel index (C00, C01, ...)] tiffcompression=[None] tstart=0 tend=" + nT + " ");
	}
	if(tiff){
		run("BDP2 Save As...", "inputimage=[raw] directory=[" + output + "] numiothreads=1 numprocessingthreads=" + nCPUs + " filetype=[TIFFVolumes] saveprojections=false projectionmode=[" + proj + "] savevolumes=true channelnames=[Channel index (C00, C01, ...)] tiffcompression=[LZW] tstart=0 tend=" + nT + " ");
	}
	
}


function listFiles(dir, result) {
     list = getFileList(dir);
     for (i=0; i<list.length; i++) {
     	fullPath = dir + File.separator() + list[i];
        if (File.isDirectory(fullPath)){
           result = listFiles(fullPath, result);
        } else if (matches(fullPath, regex)){
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
