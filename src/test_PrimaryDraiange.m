% Define the test case
classdef test_PrimaryDraiange < matlab.unittest.TestCase  
    
    properties
        mynetwork
    end
    
    methods (Test)
        function testDrainageData(testCase)
            
            import quasiStatic.*
            % Run the primary drainage simulation and get the drainage data
            mynetworkFileName = 'simple_9_homogen_highAR';  
            testCase.mynetwork = Network(mynetworkFileName);
                                   
        
            % Test single-phase flow simulation
            testCase.mynetwork.calculateSinglePhasePressureDistribution = true;
            testCase.mynetwork.inletPressure_Pa = 1;
            testCase.mynetwork.outletPressure_Pa = 0;
            testCase.mynetwork.calculateRelativePermeability = false;
                    
            
            % Test two-phase flow simulation
            testCase.mynetwork.calculateSinglePhasePressureDistribution = false;
            testCase.mynetwork.calculateRelativePermeability = true;
            testCase.mynetwork.inletPressure_Pa = 1;
            testCase.mynetwork.outletPressure_Pa = 0;
            testCase.mynetwork.recedingContactAngle = 0;
            testCase.mynetwork.advancingContactAngle = 0;
            testCase.mynetwork.primaryDrainage_20191207(); 
            
            drainageData = testCase.mynetwork.DrainageData;

            % Read the expected table from an Excel file
            expectedTable = readtable('Drainage.xlsx', 'Sheet', 'Sheet1');

            % Load the expected table from a .mat file
%             expectedTable = load('DrainageData.mat', 'network.DrainageData');
%             expectedTable = network.DrainageData; 
            

            % Check the size of the drainage data table
            [numRows, numCols] = size(drainageData);
            testCase.verifyEqual(numRows, size(expectedTable, 1));
            testCase.verifyEqual(numCols, size(expectedTable, 2));

            % Check the values in the drainage data table
            for row = 1:numRows
                for col = 1:numCols
                    expectedValue = expectedTable(row, col);
                    actualValue = drainageData(row, col);
                    testCase.verifyEqual(actualValue, expectedValue);
                end
            end
        end
    end
end 
  
 



