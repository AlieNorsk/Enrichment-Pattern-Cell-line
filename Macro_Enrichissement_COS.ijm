run("Close All");
roiManager("reset");


//Demander dans quel fichier sont les images 
Dir=getDirectory("Choose a Directory");
fileList=getFileList(Dir);

channel=GUI();
ListfilePattern=CreateListPattern(channel[0],channel[2]);
ListfileTIRF=CreateListTIRF(channel[1],channel[2]);
DrawCellBorder();
setBatchMode(true);
ROIPattern();
Background();
Measure(); 
setBatchMode("exit and display");


//-------------------------------------------------------------------
// Création de deux liste  différentes une pour les fichiers TIRF et une pour les fichier correspondant au pattern 
function CreateListPattern(ChannelPattern,nbcond) { 
	ListfilePattern=newArray(fileList.length/nbcond);
	compt=0;
	for (i = 0; i < fileList.length; i++) {
		if (endsWith(fileList[i], ChannelPattern+".TIF")==true)
		{ListfilePattern[compt]=fileList[i];
		compt=compt+1;}}
		return ListfilePattern;}

function CreateListTIRF(ChannelTIRF,nbcond) { 
	ListfileTIRF=newArray(fileList.length/nbcond);
	compt=0;
	for (i = 0; i < fileList.length; i++) {
		if (endsWith(fileList[i], ChannelTIRF+".TIF")==true)
		{ListfileTIRF[compt]=fileList[i];
		compt=compt+1;}}
		return ListfileTIRF;}
		

//--------------------------------------------------------------
//Traçage des bordures de la cellule sur l'ensemble des  fichiers TIRF 
// Etape en premiére pour éviter l'intervention de l'utilisateur plus tard 

function DrawCellBorder() { 
for (i = 0; i < ListfileTIRF.length; i++) {
	open(Dir+ListfileTIRF[i]);
	orig=ListfileTIRF[i];
	setTool("polygon");
	waitForUser("Draw border of your cell and click sur OK");
	roiManager("add");
	roiManager("select", i);
	selectWindow(orig);
	roiManager("rename", File.nameWithoutExtension+"_ROI");
	run("Close All");
	}
	roiManager("save", Dir+"Cellcontour.zip");
	roiManager("reset");
	}

//-------------------------------------------------------------------
// function ecrite pour extraire les ROI correspondant à INPattern et OUTPattern dans la ROI de la  cellule d'interet + mesure du niveau de Cy5 

function ROIPattern() { 
	for (i = 0; i < ListfilePattern.length ; i++) {
		orig=ListfilePattern[i];
		open(Dir+orig);
		origname=File.nameWithoutExtension;
		selectWindow(orig);
		
		//Threshold de l'image pattern
		run("Duplicate...", "title=MaskPattern");
		setOption("BlackBackground", true);
		setAutoThreshold("Default dark");
		
		//transformer en masque 
		run("Convert to Mask");
		run("Fill Holes");
		setAutoThreshold("Default dark");
		
		//ouvrir la ROI de la cellule 
		roiManager("open", Dir+"Cellcontour.zip");
		roiManager("deselect");
		roiManager("select", i);


		//extraire les ROI du pattern dans la zone de cellule 
		roiManager("reset");
		run("Analyze Particles...", "size=50-Infinity clear add");
		roiManager("save", Dir+ origname +"_PatternIN.zip");
		roiManager("reset");
		
		//creer le pattern inverse
		run("Select None");
		run("Duplicate...", "title=MaskPatternInvert");
		run("Invert");
		setAutoThreshold("Default dark");
		
		//faire le decoupage ROI sur le pattern Invert
		//selectWindow("MaskPatternInvert");
		roiManager("open", Dir+"Cellcontour.zip");
		roiManager("deselect");
		roiManager("select", i);
		roiManager("reset");
		run("Analyze Particles...", "size=50-Infinity clear add");
		
		//enregistrer le masque Invert Pattern
		roiManager("save", Dir+origname+"_PatternOUT.zip");
		saveAs("Tiff", Dir+origname+"_maskInvert");
		
		//enregistrer le masque Pattern
		selectWindow("MaskPattern");
		saveAs("Tiff", Dir+origname+"_mask");
		
		//remettre tout a zero
		roiManager("reset");
		run("Close All");
		}}


//-------------------------------------------------------------------
//MESURE D'UNE VALEUR BACKGROUND

function Background() { 
for (i = 0; i < ListfileTIRF.length; i++) {
	open(Dir+ListfileTIRF[i]);
	orig=ListfileTIRF[i];
	origname=File.nameWithoutExtension;
	setAutoThreshold("MinError");
	run("Convert to Mask");
	run("Dilate");
	run("Erode");
	run("Erode");
	run("Erode");
	setAutoThreshold("Default dark");
	run("Create Selection");
	roiManager("add");
	roiManager("save", Dir+origname+"_Background.zip");
	roiManager("reset");
	run("Close All");
	}}
		

//-------------------------------------------------------------------
function Measure() { 

for (i = 0; i < ListfileTIRF.length; i++) {
	open(Dir+ListfilePattern[i]);
	origP=ListfilePattern[i];
	orignameP=File.nameWithoutExtension;
	

	//Measure PatternFluo 
	roiManager("open", Dir+orignameP+"_PatternIN.zip");
	run("Set Measurements...", "mean redirect=None decimal=3");
	roiManager("multi-measure measure_all one append");
	roiManager("reset");

	//Measure Pattern bakground 
	selectWindow(origP);
	run("Select None");
	roiManager("open", Dir+orignameP+"_PatternOUT.zip");
	run("Set Measurements...", "mean redirect=None decimal=3");
	roiManager("multi-measure measure_all one append");
	run("Close All");
	roiManager("reset");
	
	
	open(Dir+ListfileTIRF[i]);
	orig=ListfileTIRF[i];
	origname=File.nameWithoutExtension;

	
	//Mesure FluoresnceCell Global 
	roiManager("open", Dir+"Cellcontour.zip");
	roiManager("deselect");
	roiManager("select", i);
	roiManager("multi-measure measure_all one append");
	run("Select None");
	roiManager("reset");

	//Mesure Background 
	roiManager("open", Dir+origname+"_Background.zip");
	roiManager("multi-measure measure_all one append");
	run("Select None");
	roiManager("reset");
	
	// Mesure Enrichissement OUT 
	roiManager("open", Dir+orignameP+"_PatternOUT.zip");
	roiManager("multi-measure measure_all one append");
	run("Select None");
	roiManager("reset");

	// Mesure Enrichissement IN 
	roiManager("open", Dir+orignameP+"_PatternIN.zip");
	roiManager("multi-measure measure_all one append");

	//Enregistrer les measure
	selectWindow("Results");
	saveAs("Results",  Dir + origname + "_Pattern_All_Back_OUT_IN.csv");
	run("Close");
	roiManager("reset");
	run("Close All");
	}}

 

//------------------------------------------------------
// Demande à l'utilisateur qu'elle channel il utilise et également le nbr de channel acquérit (même ceux non utilisé pour l'analyse) 
function GUI() { 

choicesPattern=newArray("Cy5 epi", "GFP");
choices=newArray("TIRF-488","TIRF-561","NONE");

Dialog.create("Choose your acquisition channels /n for enrichment measures");
Dialog.addChoice("Channel use for pattern acquisition ?", choicesPattern);
Dialog.addChoice("Channel use for for TIRF acquisition ?", choices);
Dialog.addNumber("Nbr de channel (Acquisitions)", 4);
Dialog.show();

channelPattern=Dialog.getChoice();
channelTIRF=Dialog.getChoice();
nbcond=Dialog.getNumber();

return newArray(channelPattern,channelTIRF,nbcond);
}

