// Dave Barry, Francis Crick Institute
// 2018.01.17
// david.barry@crick.ac.uk

// Finds local intensity maxima in all slices in a stack.

macro "Stack Max Finder"{
	N = nSlices();
	title = getTitle();
	Dialog.create("Stack Max Finder");
	Dialog.addNumber("Specify Noise Tolerance:", 1000);
	Dialog.show();
	tol = Dialog.getNumber();
	for (i=1; i<=N; i++) {
		selectWindow(title);
		setSlice(i);
		label = getInfo("slice.label");
		run("Find Maxima...", "noise="+tol+" output=[Single Points]");
		rename(label + " - Maxima");
	}
}