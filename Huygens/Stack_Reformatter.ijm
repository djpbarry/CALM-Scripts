// Dave Barry, Francis Crick Institute
// 2018.08.14
// david.barry@crick.ac.uk

// Generates "preview" images of stacks in a directory

macro "Stack Reformatter"{
	startTime = getTime();
	setBatchMode(true);
	input = getDirectory("Choose Input Directory");
	output = getDirectory("Choose Output Directory");
	list = getFileList(input);

	Dialog.create("Stack Reformatter");
	Dialog.addString("File extension:", ".tif");
	Dialog.show();
	extension = Dialog.getString();

	for(i = 0; i < list.length; i++){
		if(endsWith(toLowerCase(list[i]), toLowerCase(extension))){
			reformat(input, output, list[i], i);
			print(round((i+1) * 100.0 / list.length) + "% done");
		}
	}

	setBatchMode(false);
	close("*");
	duration = (getTime() - startTime) / 1000;
	hours = floor(duration / 3600);
	minutes = floor((duration - hours * 3600) / 60);
	seconds = floor(duration - hours * 3600 - minutes * 60);
	print("100% Done: " + hours + ":" + minutes + ":" + seconds);
	
	function reformat(input, output, filename, series) {
		fullInputFilename = input + filename;
		fullOutputFilename = output + filename + "_S" + series + ".ome.tif";
		print ("Reading " + fullInputFilename);
		open(fullInputFilename);
		//slices = nSlices / channels;
		//run("Stack to Hyperstack...", "order=xyzct channels=" + channels + " slices=" + slices + " frames=1 display=Composite");
		print ("Writing " + fullOutputFilename);
		run("Bio-Formats Exporter", "save=[" + fullOutputFilename + "] compression=Uncompressed");
	}
}