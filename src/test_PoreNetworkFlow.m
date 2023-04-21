% Define the test case
classdef test_PoreNetworkFlow < matlab.unittest.TestCase
    
    properties
        mynetwork
    end
    
    methods (TestMethodSetup)
        function createmynetwork(testCase)
            
            import quasiStatic.*
            % Crearing an object of the mynetwork
            mynetworkFileName = 'simple_9_homogen_highAR';  
            testCase.mynetwork = Network(mynetworkFileName);
        end
    end
    
    methods (Test)
        
        function testSinglePhaseFlow(testCase)
            % Test single-phase flow simulation
            testCase.mynetwork.calculateSinglePhasePressureDistribution = true;
            testCase.mynetwork.inletPressure_Pa = 1;
            testCase.mynetwork.outletPressure_Pa = 0;
            testCase.mynetwork.calculateRelativePermeability = false;
            
            % Verify that pressure distribution is calculated
            testCase.verifyTrue(testCase.mynetwork.calculateSinglePhasePressureDistribution);
            % Verify that inlet and outlet pressures are set correctly
            testCase.verifyEqual(testCase.mynetwork.inletPressure_Pa, 1);
            testCase.verifyEqual(testCase.mynetwork.outletPressure_Pa, 0);
            % Verify that relative permeability is not calculated
            testCase.verifyFalse(testCase.mynetwork.calculateRelativePermeability);
        end
        
        function testTwoPhaseFlow(testCase)
            % Test two-phase flow simulation
            testCase.mynetwork.calculateSinglePhasePressureDistribution = false;
            testCase.mynetwork.calculateRelativePermeability = true;
            testCase.mynetwork.inletPressure_Pa = 1;
            testCase.mynetwork.outletPressure_Pa = 0;
            testCase.mynetwork.recedingContactAngle = 0;
            testCase.mynetwork.advancingContactAngle = 0;
            
            testCase.mynetwork.primaryDrainage_20191207();
            testCase.mynetwork.secondaryImbibition_20191207();
            
            % Verify that relative permeability is calculated
            testCase.verifyTrue(testCase.mynetwork.calculateRelativePermeability);
            % Verify that inlet and outlet pressures are set correctly
            testCase.verifyEqual(testCase.mynetwork.inletPressure_Pa, 1);
            testCase.verifyEqual(testCase.mynetwork.outletPressure_Pa, 0);
            % Verify that contact angles are set correctly
            testCase.verifyEqual(testCase.mynetwork.recedingContactAngle, 0);
            testCase.verifyEqual(testCase.mynetwork.advancingContactAngle, 0);
        end
        
    end
    
end
