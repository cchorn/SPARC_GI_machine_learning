function [snipObj] = createSnippetObj(metadataStruct, wf, snipIdx)
    
    %   DESCRIPTION
    %   ===================================================================
    %   Save snippet of waveform to MDF object 
    %
    %   INPUTS
    %   ===================================================================
    %   metadataStruct  :  (struct) mdf query struct
    %   wf              :  (1xn) waveform snippet
    %   snipIdx         :  (int) index of signal window
    %
    %   Author: Ameya C. Nanivadekar
    %   email: acnani@gmail.com

    snipObj = mdfObj;
    snipObj.type = 'snip';
    snipObj.md = metadataStruct;
    
    if isnumeric(metadataStruct.chanLabel)
        chanLabel = num2str(metadataStruct.chanLabel);
    else
        chanLabel = metadataStruct.chanLabel;
    end
    snipObj.setFiles(fullfile('<DATA_BASE>','snip',sprintf('%s_Trial%02d_CH%s_snip%d',metadataStruct.subject,metadataStruct.trialnum, chanLabel, snipIdx)));
    
    snipObj.data.wf = wf;
    snipObj.save;
end