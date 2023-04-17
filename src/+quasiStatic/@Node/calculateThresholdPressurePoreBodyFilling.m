function calculateThresholdPressurePoreBodyFilling(element,network)
switch (network.typeOfPoreBodyFillingAlgorithm)
    case 'Blunt2'    
        calculateThresholdPressurePoreBodyFilling_Blunt2 (element,network)% Blunt2
    case 'Blunt1'
        calculateThresholdPressurePoreBodyFilling_Blunt1 (element,network) % Blunt1
    case 'Oren1'
        calculateThresholdPressurePoreBodyFilling_Oren1 (element,network)% Oren1
    case 'Oren2'
        calculateThresholdPressurePoreBodyFilling_Oren2 (element,network)% Oren2
    case 'Piri'
        calculateThresholdPressurePoreBodyFilling_Piri (element,network)% Piri
    case 'Patzek'
        calculateThresholdPressurePoreBodyFilling_Patzek (element,network)% Patzek  
    case 'Valvatne'
        calculateThresholdPressurePoreBodyFilling_Valvatne (element,network)% Valvatne  
    otherwise 
        warning ('typeOfPoreBodyFillingAlgorithm does not match with the defined algorithms, therefore Valvatne is used as a default algorithm'); 
        calculateThresholdPressurePoreBodyFilling_Valvatne(element,network) % Valvatne 
end
    

end