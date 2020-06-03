// Dave Barry, Francis Crick Institute
// 2018.08.14
// david.barry@crick.ac.uk

// Generates "preview" images of stacks in a directory

macro "Huygens Browser 2"{
	startTime = getTime();
	input = getDirectory("Choose Input Directory");
	list = getFileList(input);
	Array.sort(list);
	print(input);

	Dialog.create("Huygens Browser");
	Dialog.addNumber("Select starting index:", 1);
	Dialog.addNumber("Number of images to open:", 3);
	Dialog.addNumber("Display constrast saturation (0.0 - 1.0):", 0.35);
	Dialog.addString("File extension:", ".tif");
	Dialog.show();
	startIndex = Dialog.getNumber();
	nOpen = Dialog.getNumber();
	saturation = Dialog.getNumber();
	extension = Dialog.getString();

	nSeries = 0;
	nChannels = 0;

	series = newArray(list.length);
	channels = newArray(list.length);
	baseFileNames = newArray(list.length);
	Array.fill(series, -1);
	Array.fill(channels, -1);

	for(i = 0; i < list.length; i++){
		file = input + list[i];
		filename = list[i];
		if(endsWith(toLowerCase(list[i]), toLowerCase(extension))){
			s1 = indexOf(filename, "_S");
			s2 = lastIndexOf(filename, ".ome_");
			c1 = indexOf(filename, "_ch");
			c2 = lastIndexOf(filename, ".tif");
			s = parseInt(substring(filename, s1+2, s2));
			c = parseInt(substring(filename, c1+3, c2));
			if(!searchArray(series, s)){
				series[nSeries] = s;
				baseFileNames[nSeries] = filename;
				print("Series " + (nSeries + 1) + ": " + filename);
				nSeries++;
			}
			if(!searchArray(channels, c)){
				channels[nChannels] = c;
				nChannels++;
			}
		}
	}
	
	if(startIndex < 1) startIndex = 1;
	if((startIndex > nSeries)) startIndex = nSeries;
	
	IJ.log("Number of series: " + nSeries);
	IJ.log("Number of channels: " + nChannels);
	IJ.log("Beginning with the " + startIndex + "th image.");

	luts = getList("LUTs");
	displayModes = newArray("grayscale", "composite", "color");
	selectedLUTs = newArray(nChannels);
	
	Dialog.create("Specify Display Mode");
	Dialog.addChoice("Display mode", displayModes, displayModes[0]);
	for(c = 1; c <= nChannels; c++){
		Dialog.addChoice("Channel " + c, luts, luts[c - 1]);
	}
	Dialog.show();
	chosenDisplayMode = Dialog.getChoice();
	for(c = 1; c <= nChannels; c++){
		selectedLUTs[c-1] = Dialog.getChoice();
	}
	
	count = 0;
	for (s = startIndex - 1; s < nSeries; s++){
		makePreview(input, baseFileNames[s], series[s], channels, nChannels, selectedLUTs);
		count++;
		if(count >= nOpen){
			waitForUser("Huygens Browser", "Press OK to open next " + count + " image(s).");
			count = 0;
		}
	}
	print("Done");
	
	function makePreview(input, filename, series, channels, nChannels, luts) {
		fullFilename = input + filename;
		print("Opening series " + series);
		mergeOptions = "";
		for(c = 0; c < nChannels; c++){
			current = constructFileName(filename, channels[c], series);
			if(File.exists(input + current)){
				open(current);
				mergeOptions = mergeOptions + "c" + (c+1) + "=" + current + " ";
			}
		}

		run("Merge Channels...", mergeOptions + " create");
		Stack.setDisplayMode(chosenDisplayMode);
		newName = substring(filename, 0, indexOf(filename, ".")) + "_S" + series;
		rename(newName);
		getDimensions(w,h,dummy,s,f);
		Stack.setSlice(s / 2);
		for(c = 0; c < nChannels; c++){
			Stack.setChannel(c + 1);
			run(luts[c]);
			run("Enhance Contrast", "saturated=" + saturation);
		}
	}

	function searchArray(array, entry){
		L = lengthOf(array);
		for(i = 0; i < L; i++){
			if(array[i] == entry){
				return true;
			}
		}
		return false;
	}

	function constructFileName(baseFileName, channel, series){
		s1 = indexOf(filename, "_S");
		s2 = lastIndexOf(filename, ".ome_");
		c1 = indexOf(filename, "_ch");
		c2 = lastIndexOf(filename, ".tif");

		newFileName = substring(filename, 0, s1) + "_S" + series + substring(filename, s2, c1) + "_ch0" + channel + ".tif";
		
		print(newFileName);

		return newFileName;
	}
		
}