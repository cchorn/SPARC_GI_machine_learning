function [] = createCommonAvgRefobj(trialObj)
    
    %   DESCRIPTION
    %   ===================================================================
    %   Generates bipolar pair objects for all possible EGG bipolar pairs 
    %
    %   INPUTS
    %   ===================================================================
    %   trialObj    :   MDF object for trial to be processed
    
    if ismember(trialObj.trialType, {'rec', 'emetine','euthasol', 'rec_postop','rec_awake', 'feeding', 'post_feeding', 'pre_feeding', 'emetine_awake', 'feeding_stim','water_awake'})
        for iSeg = 1:trialObj.getLen('segments')
            fprintf('Processing CAR for segment %d\n', iSeg)
            
            segObj = trialObj.segments(iSeg);
            CARobj = mdfObj;
            CARobj.type = 'CAR';
            CARobj.uuid = mdf.UUID;
            CARobj.setFiles(fullfile('<DATA_BASE>',trialObj.subject,'CAR_EGG',sprintf('Trial%02d_seg%02d_CAR',trialObj.trial, segObj.segment)));
            CARobj.md.subject = trialObj.subject;
            CARobj.md.trial = trialObj.trial;
            CARobj.md.segment = segObj.segment;
            CARobj.md.fs = 2e3;
            
            allWf = [segObj.EGG_2k.wf];            
            CARobj.data.wf = mean(cell2mat(allWf),2);
            CARobj.data.time = segObj.EGG_2k(1).time;
            CARobj.save;
            
            mdf.addParentChildRelation(segObj, CARobj, 'commonAvgEGG');
            segObj.save;
            CARobj.save;
        end

    else
        if ismember(trialObj.trialType, {'stim', 'pauli_stim','stim_postop', 'stim_awake', 'balloon', 'palpate'})
            fprintf('Processing CAR for trial %d\n', trialObj.trial)
            CARobj = mdfObj;
            CARobj.type = 'CAR';
            CARobj.uuid = mdf.UUID;
            CARobj.setFiles(fullfile('<DATA_BASE>',trialObj.subject,'CAR_EGG',sprintf('Trial%02d_CAR',trialObj.trial)));
            CARobj.md.subject = trialObj.subject;
            CARobj.md.trial = trialObj.trial;
            CARobj.md.fs = 2e3;
            
            allWf = [trialObj.EGG_2k.wf];         
            CARobj.data.wf = mean(cell2mat(allWf),2);
            CARobj.data.time = trialObj.EGG_2k(1).time;
            CARobj.save;
            
            mdf.addParentChildRelation(trialObj, CARobj, 'commonAvgEGG');
            trialObj.save;
            CARobj.save;
        else
            error('invalid trial object')
        end
    end
    
    disp('Finished processing CARs')
end
