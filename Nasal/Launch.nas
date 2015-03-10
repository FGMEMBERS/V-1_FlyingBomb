var launch = func {
    if ( getprop("/gear/gear[0]/wow") or 
         getprop("/gear/gear[1]/wow") or
         getprop("/gear/gear[2]/wow") ){
    screen.log.write("Launching!");
    
    #this is on purpose! prevents the V-1 from pitching up crazily
    setprop("/controls/gear/brake-parking", 1); 
    
    setprop("/controls/flight/elevator", -1);
    setprop("/controls/engines/thruster[0]/throttle", 1);
    settimer ( func { 
        setprop("/controls/flight/elevator", 0); 
        setprop("/controls/gear/gear-down", 0);
        setprop("/controls/engines/thruster[0]/throttle", 0); 
        setprop("/controls/gear/brake-parking", 0);
        }, 3.5);
    }
    else
        screen.log.write("Can't launch: Not on ground!");
}
    

