srand(); #set seed for random generator

#automated engine cutoff on dive
var dive_cutoff = func {
    if ( (getprop("/autopilot/settings/target-altitude-ft") <= 0) and 
         (getprop("/autopilot/locks/altitude") == "altitude-hold") ){
    screen.log.write("Final dive!");
    setprop("/controls/engines/engine/throttle", 0);
    }
}
setlistener("/autopilot/locks/altitude", dive_cutoff);
setlistener("/autopilot/settings/target-altitude-ft", dive_cutoff);


#flame Rembrandt light brightness alternation
var flamePath = "sim/model/V-1/";
props.globals.initNode(flamePath ~ "flameBright", 0.0, "DOUBLE");
var flameSeq = [0,0,0,0];
var curSeq = 0;
var flameBright = func {
	flameSeq[curSeq] = 0.5 + rand()*0.5;
	
	setprop(flamePath ~ "flameBright", 
		(flameSeq[0]+flameSeq[1]+flameSeq[2]+flameSeq[3]) / 4);
	
	if( curSeq < 3)
		curSeq += 1;
	else
		curSeq = 0;
		
	settimer(flameBright, 0.02);
}

settimer(flameBright, 0.02);







