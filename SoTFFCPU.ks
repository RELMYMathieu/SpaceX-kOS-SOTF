// STARSHIP SoTF FLIGHT CONTROL SCRIPT
clearscreen.
print "-- Starship SoTF Flight Software v1.0 --".
print "Initializing flight systems...".

// Core systems
set shipCore to ship:partstagged("ShipCore")[0].
set shipNose to ship:partstagged("ShipNose")[0].

// Engine setup
set engine1 to ship:partstagged("E1")[0].
set engine2 to ship:partstagged("E2")[0].
set engine3 to ship:partstagged("E3")[0].
set engines to list(engine1, engine2, engine3).

// Flap setup
set aftFlaps to ship:partstagged("AftFlap").
set fwdFlaps to ship:partstagged("FwdFlap").

// Control locks
lock throttle to 0.
lock steering to "kill".

// Import all utility functions
function setFlaps {
    parameter angleFwd.
    parameter angleAft.
    parameter deploy.
    parameter authority.
    
    for flap in fwdFlaps {
        flap:getmodule("ModuleSEPControlSurface"):SetField("Deploy", deploy).
        flap:getmodule("ModuleSEPControlSurface"):SetField("Deploy Angle", angleFwd).
        flap:getmodule("ModuleSEPControlSurface"):SetField("Authority Limiter", authority).
    }
    
    for flap in aftFlaps {
        flap:getmodule("ModuleSEPControlSurface"):SetField("Deploy", deploy).
        flap:getmodule("ModuleSEPControlSurface"):SetField("Deploy Angle", angleAft).
        flap:getmodule("ModuleSEPControlSurface"):SetField("Authority Limiter", authority).
    }
}

function setEngineGimbal {
    parameter engineNum.
    parameter actuateOut.
    
    local engine to choose engine1 if engineNum = 1
                    else choose engine2 if engineNum = 2
                    else engine3.
    
    local currentState to engine:getmodule("ModuleSEPRaptor"):GetField("Actuate Out").
    
    if currentState <> actuateOut {
        engine:getmodule("ModuleSEPRaptor"):DoAction("toggle actuate out", true).
    }
}

function controlEngine {
    parameter engineNum.
    parameter activate.
    
    local engine to choose engine1 if engineNum = 1
                    else choose engine2 if engineNum = 2
                    else engine3.
                    
    if activate {
        engine:activate().
    } else {
        engine:shutdown().
    }
}

wait until false. // TEMPORARY

// TODO: Implement flight control logic