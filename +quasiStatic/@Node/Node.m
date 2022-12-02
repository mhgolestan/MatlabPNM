classdef Node < quasiStatic.Element
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        x_coordinate
        y_coordinate
        z_coordinate
        connectionNumber
        connectedNodes
        connectedLinks  
        imbThresholdPressure_PoreBodyFilling = nan;  
        newID
    end
    
    methods
        function obj = Node(index,...
                            x_coordinate,...
                            y_coordinate,...
                            z_coordinate,...
                            connectionNumber,...
                            connectionData,...
                            volume,...
                            radius,...
                            shapeFactor,...
                            clayVolume)
            %UNTITLED Construct an instance of this class
            %   Detailed explanation goes here
            obj.index = index;
            obj.x_coordinate = x_coordinate;
            obj.y_coordinate = y_coordinate;
            obj.z_coordinate = z_coordinate;
            obj.connectionNumber = connectionNumber;  
            obj.connectedNodes = connectionData(1:connectionNumber);
            if connectionData(connectionNumber + 1) == 1
                obj.isInlet = true;
            else
                obj.isInlet = false;
            end
            if connectionData(connectionNumber + 2) == 1
                obj.isOutlet = true;
            else
                obj.isOutlet = false;
            end
            obj.connectedLinks = connectionData(connectionNumber + 3: end);
            obj.volume = volume;
            obj.radius = radius;
            obj.shapeFactor = shapeFactor;
            obj.clayVolume = clayVolume;   
        end    
        %% PoreBodyFilling 
        calculateThresholdPressurePoreBodyFilling (obj,network)% Blunt2
        calculateThresholdPressurePoreBodyFilling_Blunt1 (obj,network) % Blunt1
        calculateThresholdPressurePoreBodyFilling_Oren1 (obj,network)% Oren1
        calculateThresholdPressurePoreBodyFilling_Oren2 (obj,network)% Oren2
        calculateThresholdPressurePoreBodyFilling_Piri (obj,network)% Piri
        calculateThresholdPressurePoreBodyFilling_Patzek (obj,network)% Patzek
        calculateThresholdPressurePoreBodyFilling_Valvatne (obj,network)% Valvatne
    end
    
end

