classdef Element < quasiStatic.Fluids
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        % properties set from the link and node input files
        index
        radius
        shapeFactor
        volume
        clayVolume
        isInlet
        isOutlet
        isInSubArea = 0;
        subareaID = -2;
        connectionNumber_subArea = 0;
        
        % Calculated properties
        
        geometry % geometrical shape of the element 
        halfAngle1
        halfAngle2
        halfAngle3
        halfAngle4
        area   
        crossSectionShape
        crossSectionShapePore
                
        conductanceSinglePhase=0 % Element conductance & area             
        wettingPhaseConductance
        nonWettingConductance  
        
        wettingPhaseCrossSectionArea 
        nonWettingCrossSectionArea  
        
        wettingPhaseSaturation
        nonWettingSaturation
        
        wettingPhasePressure
        nonWettingPressure      
        
        occupancy = 'A';  % Element filled by Water         
        wettingPhaseCornerExist = nan(1,4); % Water resides in the corner of element       
        nonWettingLayerExist = nan(1,4);        
        b = zeros(1,4); % Apex distance
        
        drainThresholdPressure_PistonLike % Capillary Threshold Pressure in Drainage
        
        recedingContactAngle = 0;        
        advancingContactAngle = 0; 
        
        hingeAngles 
        isInvaded = false; % check for invasion in Imbibition 
        control % control Saturation in Imbibition
        % Capillary Threshold Pressure in Imbibition
        imbPressureTrapped = nan;
        imbThresholdPressure_SnapOff = nan;
        imbThresholdPressure_PistonLike = nan;
        imbThresholdPressure_LayerCollapse = nan(1,4);
         
    end  
    
    methods
        %% General calculation
        calculateElementsProperties(obj)
        
        %% Drainage properties
        
        % Piston-Like threshold pressure
        calculateThresholdPressurePistonLike_drainage(obj) 
        
        % Conductance & cross-section area of each phase
        calculateConductance_Drainage(obj, Pc)
        
        %% Imbibition properties
        
        % Piston-Like threshold pressure
        calculateThresholdPressurePistonLike_Imbibition(obj, Pc_max_drainage)% Based on Patzek 2001 with NR_Khazali
        calculateThresholdPressurePistonLike_Imbibition_Patzek_2003(obj, Pc_max_drainage)% Based on Patzek 2003
        calculateThresholdPressurePistonLike_Imbibition_Raeini(obj, Pc_max_drainage)% Based on Raeini 2019 with NR
        
        % Snap-off threshold pressure
        calculateThresholdPressureSnapOff(obj,Pc_max_drainage)% Zolfaghari 
        calculateThresholdPressureSnapOff_Patzek(obj,Pc_max_drainage)% Patzek
        calculateThresholdPressureSnapOff_Valvatne(obj,Pc_max_drainage)% Valvatne 
        
        % LayerCollapse threshold pressure
        calculateThresholdPressureLayerCollapse(obj, Pc_max_drainage)% Zolfaghari
        calculateThresholdPressureLayerCollapse_Piri(obj, Pc_max_drainage)% Piri
        
        % nonWettingLayer existance check  threshold pressure  
        nonWettingLayerExistance(obj)
        
        % Conductance & cross-section area of each phase
        calculateConductance_Imbibition(obj, network, Pc)
        calculateConductance_Imbibition_Valvatne(obj, network, Pc)
        calculateConductance_Imbibition_Patzek_Piri(obj, network, Pc)
        calculateConductance_Imbibition_Zolfaghari(obj, network, Pc)
    end

end

