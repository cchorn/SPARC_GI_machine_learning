function [] = upsertResultObj(mdStruct, dataStruct)
    
    %   DESCRIPTION
    %   ===================================================================
    %   Inserts new or updates existing MDF result object
    %   See analyzeSignalFeatures.m for details on function inputs
    
    
    queryStruct = mdStruct;
    queryStruct.mdf_type = 'result';
    resultObj = mdf.load(queryStruct);
    
    if isempty(resultObj)
        fprintf('Creating new result object...\n')
        resultObj = mdfObj;
        resultObj.type = 'result';
        resultObj.md = mdStruct;
        if isnumeric(mdStruct.chanLabel)
            chanLabel = num2str(mdStruct.chanLabel);
        else
            chanLabel = mdStruct.chanLabel;
        end
        resultObj.setFiles(fullfile('<DATA_BASE>','results',sprintf('%s_Trial%02d_ch%s_%s',mdStruct.subject, mdStruct.trial, chanLabel,resultObj.uuid)));
        
%         mdf.addParentChildRelation(parentObj, resultObj, 'result');
%         resultObj.save;
%         parentObj.save;
        
    else
        fprintf('Updating existing result object...\n')
    end
    
    for iField = fieldnames(dataStruct)'
        resultObj.data.(iField{1}) = dataStruct.(iField{1});
    end
    resultObj.save;
    
end
