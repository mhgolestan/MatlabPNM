% Define the test case
classdef test_SinglePhaseFlow < matlab.unittest.TestCase  
    
    properties
        mynetwork
    end
    
    methods (TestMethodSetup)
        function createmynetwork(testCase)
            
            import quasiStatic.*
            % Crearing an object of the mynetwork
            mynetworkFileName = 'simple_9_homogen_highAR';  
            testCase.mynetwork = Network(mynetworkFileName);
            testCase.mynetwork.name = mynetworkFileName;
        end
    end
    
    methods (Test)        
        
        function testSinglePhaseFlow(testCase)
            % Test single-phase flow simulation
            testCase.mynetwork.calculateSinglePhasePressureDistribution = true;
            testCase.mynetwork.inletPressure_Pa = 1;
            testCase.mynetwork.outletPressure_Pa = 0; 
            testCase.mynetwork.visualization = true;
            testCase.mynetwork.IO.output_networkStochasticAndPlotInfo_singlePhaseFlow(testCase.mynetwork); 
            
            % Verify that pressure distribution is calculated
            testCase.verifyTrue(testCase.mynetwork.calculateSinglePhasePressureDistribution);
            % Verify that inlet and outlet pressures are set correctly
            testCase.verifyEqual(testCase.mynetwork.inletPressure_Pa, 1);
            testCase.verifyEqual(testCase.mynetwork.outletPressure_Pa, 0);  
            testCase.verifyTrue(testCase.mynetwork.visualization);   
            % Verify that absolute permeability and porosity are calculated correctly
            testCase.verifyLessThan(abs(testCase.mynetwork.absolutePermeability_mD - (2.647659e+04)), 1e-2); 
            testCase.verifyLessThan(abs(testCase.mynetwork.porosity - 5.688606e-01), 1e-2); 
        end
         
    end
end 
  
 



