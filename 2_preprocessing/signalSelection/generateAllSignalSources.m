function [] = generateAllSignalSources(subject, bipolarPairs)
    
    %   DESCRIPTION
    %   =====================================================================
    %   Generates and saves signal source objects for each animal 
    %
    %   Author: Ameya C. Nanivadekar
    %   email: acnani@gmail.com
    
    allTrials = mdf.load('subject',subject,'mdf_type','trial');
    for iTrial = 1:length(allTrials)
        tmpObj = allTrials(iTrial);
        createBipolarEGGobj(tmpObj,bipolarPairs)
        createPaddleAvgEGGobj(tmpObj)
        createBipolarPaddleAvgEGGobj(tmpObj)
        createCommonAvgRefobj(tmpObj)
    end

    disp(['Finished ', subject])
    datetime
end
