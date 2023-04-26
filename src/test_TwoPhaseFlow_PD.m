% Define the test case
classdef test_TwoPhaseFlow_PD < matlab.unittest.TestCase  
    
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
            
            % Test single-phase flow simulation
            testCase.mynetwork.calculateSinglePhasePressureDistribution = true;
            testCase.mynetwork.inletPressure_Pa = 1;
            testCase.mynetwork.outletPressure_Pa = 0; 
            testCase.mynetwork.visualization = true;
            testCase.mynetwork.IO.output_networkStochasticAndPlotInfo_singlePhaseFlow(testCase.mynetwork); 
        end
    end
    
    methods (Test)        
        
        function testDrainageData(testCase)  
            
            % Test two-phase flow simulation
            % Run the primary drainage simulation and get the drainage data  
            
            testCase.mynetwork.max_Pc_Pa = 10000;
            testCase.mynetwork.min_Pc_Pa = -10000;
            testCase.mynetwork.deltaS_input = 0.1;
            testCase.mynetwork.NoOfPc_interval = 10;
            testCase.mynetwork.randSeed = 0;
            
            testCase.mynetwork.calculateRelativePermeability = true; 
            % typeOfPoreBodyFillingAlgorithm = {Blunt1, Blunt2, Oren1, Oren2, Patzek, Valvatne (uses absolute permeability)}
            testCase.mynetwork.typeOfPoreBodyFillingAlgorithm = 'Valvatne'; 
            testCase.mynetwork.flowVisualization = true;
            
            testCase.mynetwork.recedingContactAngle = 0;
            testCase.mynetwork.advancingContactAngle = 0;
            
            testCase.mynetwork.primaryDrainage_20191207(); 
            
            drainageData = testCase.mynetwork.DrainageData;

            % Read the expected table from an Excel file
            expectedTable = readtable('Drainage.xlsx', 'Sheet', 'Sheet1');            

            % Check the size of the drainage data table
            [numRows, numCols] = size(drainageData);
            testCase.verifyEqual(numRows, size(expectedTable, 1));
            testCase.verifyEqual(numCols, size(expectedTable, 2));

            % Check the values in the drainage data table
            for row = 1:numRows
                for col = 1:numCols
                    expectedValue = expectedTable(row, col).Variables;
                    actualValue = drainageData(row, col);  
                    testCase.verifyLessThan((abs(actualValue - expectedValue)), 1e-2);
                end
            end
        end
    end
end 
  
 



