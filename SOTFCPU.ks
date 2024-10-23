// STARSHIP SOTF CONTROL SCRIPT
clearscreen.
print "-- Starship SOTF Software v1.0 --".
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
set sfMode to true. // True will trigger SF sequence after safety checks, else skip past SF logic.

// SYSTEM VERIFICATION
function verifyParts {
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

function setFlaps {
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
function setEngineGimbal {
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

function controlEngine {
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

function staticFireSequence {
    print "Initializing static fire sequence in 5 seconds...".
    wait 5.
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
    print "All parts verified. Testing flaps...".
    setFlaps(0, 0, true, 40).
    wait 3.
    setFlaps(30, 0, true, 40).
    wait 5.
    setFlaps(0, 30, true, 40).
    wait 5.
    setFlaps(40, 40, false, 40).
    print "Test complete.".

    wait 3.

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

    if sfMode {
        staticFireSequence().
    }

} else {
    print "System verification failed. Please check part tags.".
}

print "Execution finished with no errors.".

// Execute from boot file?
// Maybe have an init script?

// TODO : Flight program.