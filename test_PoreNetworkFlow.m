classdef test_PoreNetworkFlow < matlab.unittest.TestCase
    
    properties
        network
    end
    
    methods (TestMethodSetup)
        function createNetwork(testCase)
            % Crearing an object of the network
            networkFileName = 'simple_9_homogen_highAR';  
            testCase.network = Network(networkFileName);
        end
    end
    
    methods (Test)
        
        function testSinglePhaseFlow(testCase)
            % Test single-phase flow simulation
            testCase.network.calculateSinglePhasePressureDistribution = true;
            testCase.network.inletPressure_Pa = 1;
            testCase.network.outletPressure_Pa = 0;
            testCase.network.calculateRelativePermeability = false;
            
            % Verify that pressure distribution is calculated
            testCase.verifyTrue(testCase.network.calculateSinglePhasePressureDistribution);
            % Verify that inlet and outlet pressures are set correctly
            testCase.verifyEqual(testCase.network.inletPressure_Pa, 1);
            testCase.verifyEqual(testCase.network.outletPressure_Pa, 0);
            % Verify that relative permeability is not calculated
            testCase.verifyFalse(testCase.network.calculateRelativePermeability);
        end
        
        function testTwoPhaseFlow(testCase)
            % Test two-phase flow simulation
            testCase.network.calculateSinglePhasePressureDistribution = false;
            testCase.network.calculateRelativePermeability = true;
            testCase.network.inletPressure_Pa = 1;
            testCase.network.outletPressure_Pa = 0;
            testCase.network.recedingContactAngle = 0;
            testCase.network.advancingContactAngle = 0;
            
            testCase.network.primaryDrainage_20191207();
            testCase.network.secondaryImbibition_20191207();
            
            % Verify that relative permeability is calculated
            testCase.verifyTrue(testCase.network.calculateRelativePermeability);
            % Verify that inlet and outlet pressures are set correctly
            testCase.verifyEqual(testCase.network.inletPressure_Pa, 1);
            testCase.verifyEqual(testCase.network.outletPressure_Pa, 0);
            % Verify that contact angles are set correctly
            testCase.verifyEqual(testCase.network.recedingContactAngle, 0);
            testCase.verifyEqual(testCase.network.advancingContactAngle, 0);
        end
        
    end
    
end
