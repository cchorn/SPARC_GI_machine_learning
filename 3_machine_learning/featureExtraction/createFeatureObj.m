function [featObj] = createFeatureObj(metadataStruct, snipIdx)
    
    %   DESCRIPTION
    %   ===================================================================
    %   Saves windowed feature to MDF object 
    %
    %   INPUTS
    %   ===================================================================
    %   metadataStruct  :  (struct) mdf query struct
    %   snipIdx         :  (int) index of signal window
    
    featObj = mdfObj;
    featObj.type = 'feature';
    featObj.md = metadataStruct;
    
    if isnumeric(metadataStruct.chanLabel)
        chanLabel = num2str(metadataStruct.chanLabel);
    else
        chanLabel = metadataStruct.chanLabel;
    end
    featObj.setFiles(fullfile('<DATA_BASE>','feature',sprintf('%s_Trial%02d_CH%s_snip%d_feat%d',metadataStruct.subject, metadataStruct.trialnum, chanLabel, snipIdx, metadataStruct.feature)));
    
    featObj.save;
end