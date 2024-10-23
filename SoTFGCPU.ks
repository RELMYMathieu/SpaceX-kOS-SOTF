// STARSHIP SoTF CONTROL SCRIPT
clearscreen.
print "-- Starship SoTF Ground Software v1.0 --".
print "Initializing ship systems...".

// PART INITIALIZATION
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

// Static fire mode
set testSequence to false. // TODO : Use this variable to decide whether or not to proceed with testing engines/flaps/rcs.
set sfMode to false. // True will trigger SF sequence after safety checks, else skip past SF logic.
set flightMode to true. // Flight mode triggers if true. Else, continue execution.

// SYSTEM VERIFICATION
local function verifyParts {
    local allPartsFound to true.
    
    if shipCore = 0 {
        print "ERROR: Ship core not found!".
        set allPartsFound to false.
    }
    if shipNose = 0 {
        print "ERROR: Nose cone not found!".
        set allPartsFound to false.
    }
    
    // Verify engines
    for engine in engines {
        if engine = 0 {
            print "ERROR: Missing engine!".
            set allPartsFound to false.
        }
    }
    
    // Verify flaps
    if aftFlaps:length < 2 {
        print "ERROR: Expected 2 aft flaps, found " + aftFlaps:length.
        set allPartsFound to false.
    }
    if fwdFlaps:length < 2 {
        print "ERROR: Expected 2 forward flaps, found " + fwdFlaps:length.
        set allPartsFound to false.
    }
    
    return allPartsFound.
}

local function setFlaps {
    parameter angleFwd.     // Forward flap angle (0-90°)
    parameter angleAft.     // Aft flap angle (0-90°)
    parameter deploy.       // Boolean for deployment
    parameter authority.    // Authority limiter (0-40°)
    
    // Set forward flaps
    for flap in fwdFlaps {
        flap:getmodule("ModuleSEPControlSurface"):SetField("Deploy", deploy).
        flap:getmodule("ModuleSEPControlSurface"):SetField("Deploy Angle", angleFwd).
        flap:getmodule("ModuleSEPControlSurface"):SetField("Authority Limiter", authority).
    }
    
    // Set aft flaps
    for flap in aftFlaps {
        flap:getmodule("ModuleSEPControlSurface"):SetField("Deploy", deploy).
        flap:getmodule("ModuleSEPControlSurface"):SetField("Deploy Angle", angleAft).
        flap:getmodule("ModuleSEPControlSurface"):SetField("Authority Limiter", authority).
    }
}

// ENGINE CONTROL
local function setEngineGimbal {
    parameter engineNum.    // 1, 2, or 3
    parameter actuateOut.   // true = gimbal locked (actuated out), false = gimbal active (actuated in)
    
    local engine to choose engine1 if engineNum = 1
                    else choose engine2 if engineNum = 2
                    else engine3.
    
    // Get current state from the public Actuate Out field
    local currentState to engine:getmodule("ModuleSEPRaptor"):GetField("Actuate Out").
    
    // Only toggle if current state doesn't match desired state
    if currentState <> actuateOut {
        engine:getmodule("ModuleSEPRaptor"):DoAction("toggle actuate out", true).
    }
}

local function controlEngine {
    parameter engineNum.    // 1, 2, or 3
    parameter activate.     // true to activate, false to shutdown
    
    local engine to choose engine1 if engineNum = 1
                    else choose engine2 if engineNum = 2
                    else engine3.
                    
    if activate {
        engine:activate().
    } else {
        engine:shutdown().
    }
}

local function staticFireSequence {
    clearscreen.
    
    local messages to list().  // Store persistent messages (for logging purposes)
    
    from {local t is -40.} until t > 5 step {set t to t + 1.} do {
        clearscreen.
        print "Static Fire Sequence".
        print "-----------------".
        print "T" + (choose "+" if t >= 0 else "") + t + "s".
        
        // Print all stored messages
        for msg in messages {
            print msg.
        }
        
        if t = -2 {
            messages:add("All engines ignition - 50% throttle").
            controlEngine(1, true).
            controlEngine(2, true).
            controlEngine(3, true).
            lock throttle to 0.5.
        } else if t = 0 {
            messages:add("Engine 1 shutdown and locked").
            messages:add("Throttle to 70%").
            controlEngine(1, false).
            setEngineGimbal(1, true).
            lock throttle to 0.7.
        } else if t = 2 {
            messages:add("Engine 2 shutdown and locked").
            messages:add("Throttle to 100%").
            controlEngine(2, false).
            setEngineGimbal(2, true).
            lock throttle to 1.0.
        } else if t = 5 {
            messages:add("Engine 3 shutdown and locked").
            messages:add("Sequence complete").
            controlEngine(3, false).
            setEngineGimbal(3, true).
            lock throttle to 0.
        }
        
        wait 1.
    }
}

// Test sequence
if verifyParts() {
    // TODO : Add RCS checkouts for both nose & body +modify rcs power (25, 50, 100...)
    // TODO : Add venting checkouts (vent out some prop & then figure out refuel with the launchpad)
    print "All parts verified. Testing flaps...".
    setFlaps(0, 0, true, 40).
    wait 3.
    setFlaps(90, 0, true, 40).
    wait 3.
    setFlaps(0, 0, true, 40).
    wait 3.
    setFlaps(0, 90, true, 40).
    wait 3.
    setFlaps(40, 40, false, 40).
    print "Test complete.".

    wait 5.

    print "Testing engines...".
    wait 2.
    print "Testing Engine 1...".
    setEngineGimbal(1, true).
    wait 2.
    setEngineGimbal(1, false).
    
    wait 2.
    
    print "Testing Engine 2...".
    setEngineGimbal(2, true).
    wait 2.
    setEngineGimbal(2, false).
    
    wait 2.
    
    print "Testing Engine 3...".
    setEngineGimbal(3, true).
    wait 2.
    setEngineGimbal(3, false).
    
    print "Engine test sequence complete.".
    wait 2.


    // Check for conflicting modes
    if sfMode and flightMode {
        print "ERROR: Both Static Fire Mode and Flight Mode are active!".
        print "Please disable one mode and restart the script to proceed.".
        wait until false.  // Stop further execution
    }
    else if sfMode {
        print "Initializing static fire sequence in 5 seconds...".
        wait 5.
        staticFireSequence().
    } else if flightMode {
        print "Initializing flight mode in 5 seconds...".
        wait 5.
        runPath("SoTFFCPU.ks").
    }
    
} else {
    print "System verification failed. Please check part tags.".
}

wait until false. // TEMPORARY
print "Execution finished with no errors.".

// TODO : Create functions for engines & flaps health checkouts.
// TODO URGENT : Print error & finish execution if both sf & flight mode are true.
// TODO non-priority : Create functions for engines & flaps health checkouts.
