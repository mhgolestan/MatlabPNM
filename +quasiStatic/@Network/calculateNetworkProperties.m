%% Network Properties calculation
function calculateNetworkProperties(obj, inletPressure, outletPressure)
            obj.ThSD = zeros(obj.numberOfLinks,1);
            obj.PSD = zeros(obj.numberOfNodes,1);
            CoordinationNumber = zeros(obj.numberOfNodes,1);
            obj.numOfInletLinks = 0;
            obj.numOfOutletLinks = 0; 
            obj.averageCoordinationNumber = 0;
            obj.numOfIsolatedElements = 0;
            obj.numOfTriangularElements = 0;
            obj.numOfCircularElements = 0;
            obj.numOfSquareElements = 0;
            obj.numOfTriangularPores = 0;
            obj.numOfCircularPores = 0;
            obj.numOfSquarePores = 0;
            nodesVolume = 0;
            linksVolume = 0;

            for ii = 1:obj.numberOfNodes
                obj.Nodes{ii}.calculateElementsProperties
                nodesVolume = nodesVolume + (obj.Nodes{ii}.volume); 
                CoordinationNumber(ii,1) = obj.Nodes{ii}.connectionNumber; 
                obj.PSD(ii,1) = 2 * obj.Nodes{ii}.radius; 
                %Isolated element
                if obj.Nodes{ii}.connectionNumber == 0
                    obj.numOfIsolatedElements = obj.numOfIsolatedElements + 1;
                end
                if strcmp(obj.Nodes{ii}.geometry , 'Circle')== 1
                    obj.numOfCircularPores = obj.numOfCircularPores+1;
                    obj.numOfCircularElements = obj.numOfCircularElements+1;
                elseif strcmp(obj.Nodes{ii}.geometry , 'Triangle')== 1
                    obj.numOfTriangularPores = obj.numOfTriangularPores+1;
                else
                    obj.numOfSquarePores = obj.numOfSquarePores+1;
                end
            end 

            for ii = 1:obj.numberOfLinks                 
                obj.Links{ii}.calculateElementsProperties
                linksVolume = linksVolume + (obj.Links{ii}.volume);
                obj.ThSD (ii,1)= 2 * obj.Links{ii}.radius;
                if obj.Links{ii}.isInlet
                    obj.numOfInletLinks = obj.numOfInletLinks + 1;
                elseif obj.Links{ii}.isOutlet
                    obj.numOfOutletLinks = obj.numOfOutletLinks+1;                 
                end             
                if strcmp(obj.Links{ii}.geometry , 'Circle')== 1
                    obj.numOfCircularElements = obj.numOfCircularElements+1;
                elseif strcmp(obj.Links{ii}.geometry , 'Triangle')== 1
                    obj.numOfTriangularElements = obj.numOfTriangularElements+1;
                else
                    obj.numOfSquareElements = obj.numOfSquareElements+1;
                end
            end 

            obj.averageCoordinationNumber = sum(CoordinationNumber)/obj.numberOfNodes;
            obj.maxCoordinationNumber = max(CoordinationNumber); 
            obj.networkVolume = obj.xDimension * obj.yDimension * obj.zDimension;
            obj.poreVolume = linksVolume + nodesVolume;
            obj.Porosity = obj.poreVolume / (obj.xDimension * obj.yDimension * obj.zDimension);      
            calculateAbsolutePermeability(obj, inletPressure, outletPressure);
        end 