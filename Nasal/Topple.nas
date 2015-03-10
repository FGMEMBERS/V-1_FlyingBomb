#code implementing check of distance for all MP aircraft
#when some stays close enough for specified ammount of time, the V-1 topples over

var models_node = props.globals.getNode("/ai/models");

var degToRad = 3.141592654/180;

#trigger topple
var topple = func(callsign, latDiff, lonDiff, heading) {
	
	#send MP chat message about who toppled me!
	setprop("/sim/multiplay/chat", "Toppled by " ~ callsign ~ "!");
	print("Toppled by " ~ callsign ~ "!");
	
	setprop("/autopilot/locks/heading", ""); #disable roll control
	setprop("/autopilot/locks/altitude", ""); #disable altitude control
	
	#check which direction to roll
	if( (lonDiff*math.cos(degToRad*heading) - latDiff*math.sin(degToRad*heading)) > 0 ) {
		setprop("/controls/flight/aileron", -0.12); 
		print("Toppling left!");
	}
	else {
		setprop("/controls/flight/aileron", 0.12); 
		print("Toppling right!");
	}
	
}


#variable holding how many seconds of proximity are needed to topple
var toppleSecs = 8;
var sideLimit = 5; #m
var rearLimit = -120; #m - high rear limit to prevent latency issues; can be changed for scenario purposes
var fwdLimit = 5; #m
var altLimit = 10; #ft
var R = 6378137; #Earth radius in m
#vector holding how long sequence of checks each MP aircraft was close
var inRange = [];
var toppled = 0;

#check whether to increment inRange[] proximity counter
var inToppleRange = func(altDiff, lonDiff, latDiff, heading, mpIndex) {
	var headingRad = degToRad * heading;
	#altitude check
	if( abs(altDiff) > altLimit ) return 0;
	#side check
	sideDiff = abs(lonDiff*math.cos(headingRad) - latDiff*math.sin(headingRad));
	if( sideDiff > sideLimit ) return 0;
	var fwdDiff = lonDiff*math.sin(headingRad) + latDiff*math.cos(headingRad); #positive: in front of me, negative: behind me
	#fwd check
	if( fwdDiff > fwdLimit ) return 0;
	#rear check
	if( fwdDiff < rearLimit ) return 0;
	#omit video recoreder, UFO, ... add at will
	var aircraft = getprop("/ai/models/multiplayer["~ mpIndex ~"]/model-short");
	if( aircraft == "mibs" or aircraft == "ufo" ) return 0;
	
	print(getprop("/ai/models/multiplayer["~ mpIndex ~"]/callsign") ~ " attempting topple! sideDiff:" ~ sideDiff ~ " fwdDiff:" ~ fwdDiff);
	return 1;
}

#cyclic topple checking
var toppleCheck = func {
	if(getprop("/velocities/groundspeed-kt") > 50 and getprop("/ai/models/num-players") > 0) {
		#count MP aircraft
		var nMP = -1;
		foreach (var mp; models_node.getChildren("multiplayer")) {
			var ind = mp.getIndex();
			if(nMP < ind)
				nMP = ind;
		}
		
		nMP += 1;
		setsize(inRange, nMP);
		
		forindex(var i; inRange) {
			if(inRange[i] == nil) {
				#print("nil found for new multiplayer[" ~ i ~ "], fixing");
				inRange[i] = 0;
			}
		}

		#iterate over all MP aircraft in range
		foreach (var mp; models_node.getChildren("multiplayer")) {
			var ind = mp.getIndex();
			var alt = mp.getValue("position/altitude-ft");
			var lon = mp.getValue("position/longitude-deg");
			var lat = mp.getValue("position/latitude-deg");
			
			#print(mp.getIndex() ~ " - " ~ mp.getValue("callsign"));
			#print(alt ~ ", " ~ lon ~ ", " ~ lat);
			
			d_alt = alt - getprop("/position/altitude-ft"); 
			d_lon = lon - getprop("/position/longitude-deg");
			d_lat = lat - getprop("/position/latitude-deg");
			
			#distance check in meters
			dm_lon = R*d_lon/(360.0*math.cos(lat*degToRad));
			dm_lat = R*d_lat/360.0;
			if( inToppleRange(d_alt, dm_lon, dm_lat, getprop("/orientation/heading-deg"), ind) ) {
				inRange[ind] += 1;
				if(inRange[ind] == 1)
					setprop("/sim/multiplay/chat", getprop("/ai/models/multiplayer["~ ind ~"]/callsign") ~ " attempting topple!");
			}
			else {
				if(inRange[ind] > 0) {
					print("Topple attempt by " ~ getprop("/ai/models/multiplayer["~ ind ~"]/callsign") ~ " failed...");
					setprop("/sim/multiplay/chat", "Topple attempt by " ~ getprop("/ai/models/multiplayer["~ ind ~"]/callsign") ~ " failed...");
				}
					
				inRange[ind] = 0;
				
			}
		}
			
		#time check
		forindex(var i; inRange) {
			if(inRange[i] > toppleSecs) {
				d_lon = getprop("/ai/models/multiplayer[" ~ i ~ "]/position/longitude-deg") - getprop("/position/longitude-deg");
				d_lat = getprop("/ai/models/multiplayer[" ~ i ~ "]/position/latitude-deg") - getprop("/position/latitude-deg");
				dm_lon = R*d_lon/(360.0*math.cos(getprop("/position/latitude-deg")*degToRad));
				dm_lat = R*d_lat/360.0;
				topple(getprop("/ai/models/multiplayer[" ~ i ~ "]/callsign"), dm_lat, dm_lon, getprop("/orientation/heading-deg"));
			toppled = 1;
			}
				
		}
	}
	
	if(toppled == 0)
		settimer(toppleCheck, 1);
}

settimer(toppleCheck, 5); #start checking

