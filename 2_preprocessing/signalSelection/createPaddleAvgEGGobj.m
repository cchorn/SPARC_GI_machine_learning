function [] = createPaddleAvgEGGobj(trialObj)
    
    %   DESCRIPTION
    %   ===================================================================
    %   Generates bipolar pair objects for all possible EGG bipolar pairs 
    %
    %   INPUTS
    %   ===================================================================
    %   trialObj    :   MDF object for trial to be processed
    %
    %   Author: Ameya C. Nanivadekar
    %   email: acnani@gmail.com
    
    summaryObj = mdf.load('subject',trialObj.subject,'mdf_type','summary');
    eggChan = summaryObj.EGG.label;
    paddleNum = summaryObj.EGG.paddleNum;
    uniquePaddles = unique(paddleNum);
    numPaddles = length(uniquePaddles);
    
    paddleObj_template = mdfObj;
    paddleObj_template.type = 'paddleAvgEGG';
    paddleObj_template.md.subject = trialObj.subject;
    paddleObj_template.md.trial = trialObj.trial;
    paddleObj_template.md.EGGchans = [];
    paddleObj_template.md.chanLabel = [];
    paddleObj_template.md.paddleNum = [];
    paddleObj_template.md.fs = 2e3;

    paddleLabels = cell(1,numPaddles);
    for iPaddle = 1:numPaddles
        chanLabel = sprintf('paddle%02d',uniquePaddles(iPaddle));
        paddleChans = eggChan(paddleNum == uniquePaddles(iPaddle));
        
        if ismember(trialObj.trialType, {'rec', 'emetine','euthasol', 'rec_postop','rec_awake', 'feeding', 'post_feeding', 'pre_feeding', 'emetine_awake', 'feeding_stim','water_awake'})
            for iSeg = 1:trialObj.getLen('segments')
                segObj = trialObj.segments(iSeg);
                existingObj = mdf.load('subject',segObj.subject,'trial',segObj.trial,'mdf_type','paddleAvgEGG','chanLabel',chanLabel,'segment',segObj.segment);
                if isempty(existingObj)
                    fprintf('Processing segment %d, paddle %s\n', iSeg, chanLabel)
                    
                    EGGchans = mdf.load('subject',segObj.subject,'trial',segObj.trial,'mdf_type','egg','EGGlabel',paddleChans,'segment',segObj.segment);
                    
                    paddleObj = paddleObj_template.clone;
                    paddleObj.setFiles(fullfile('<DATA_BASE>',segObj.subject,'paddleAvgEGG',sprintf('Trial%02d_seg%02d_%s',segObj.trial, segObj.segment, chanLabel)));
                    paddleObj.md.segment = segObj.segment;
                    paddleObj.md.EGGchans = paddleChans;
                    paddleObj.md.chanLabel = chanLabel;
                    paddleObj.md.paddleNum = uniquePaddles(iPaddle);
                    
                    dataCellVec = [EGGchans(:).data.wf];
                    if ~isrow(dataCellVec)
                        dataCellVec = dataCellVec';
                    end
                    paddleObj.data.wf = mean(cell2mat(dataCellVec),2);
                    paddleObj.data.time = EGGchans(1).data.time;
                    paddleObj.save;
                    
                    mdf.addParentChildRelation(segObj, paddleObj, 'paddleAvgEGG');
                    segObj.save;
                    paddleObj.save;
                    
                else 
                    disp([chanLabel, ' already exists. Overwriting wf'])
                    EGGchans = mdf.load('subject',segObj.subject,'trial',segObj.trial,'mdf_type','egg','EGGlabel',paddleChans,'segment',segObj.segment);
                    dataCellVec = EGGchans(:).data.wf;
                    if ~isrow(dataCellVec)
                        dataCellVec = dataCellVec';
                    end
                    existingObj.data.wf = mean(cell2mat(dataCellVec),2);
                    existingObj.data.time = EGGchans(1).data.time;
                    existingObj.save;
                end
            end
            
        else
            if ismember(trialObj.trialType, {'stim', 'pauli_stim','stim_postop', 'stim_awake', 'balloon', 'palpate'})
                existingObj = mdf.load('subject',trialObj.subject,'trial',trialObj.trial,'mdf_type','paddleAvgEGG','chanLabel',chanLabel);
                if isempty(existingObj)
                    fprintf('Processing trial %d, paddle %s\n', trialObj.trial, chanLabel)
                    
                    EGGchans = mdf.load('subject',trialObj.subject,'trial',trialObj.trial,'mdf_type','egg','EGGlabel',paddleChans);
                    
                    paddleObj = paddleObj_template.clone;
                    paddleObj.setFiles(fullfile('<DATA_BASE>',trialObj.subject,'paddleAvgEGG',sprintf('Trial%02d_%s',trialObj.trial, chanLabel))); 
                    paddleObj.md.EGGchans = paddleChans;
                    paddleObj.md.chanLabel = chanLabel;
                    paddleObj.md.paddleNum = uniquePaddles(iPaddle);
                    
                    dataCellVec = [EGGchans(:).data.wf];
                    if ~isrow(dataCellVec)
                        dataCellVec = dataCellVec';
                    end
                    paddleObj.data.wf = mean(cell2mat(dataCellVec),2);
                    paddleObj.data.time = EGGchans(1).data.time;
                    paddleObj.save;
                    
                    mdf.addParentChildRelation(trialObj, paddleObj, 'paddleAvgEGG');
                    trialObj.save;
                    paddleObj.save;
            
                else
                    disp([chanLabel, ' already exists. Overwriting wf'])
                    EGGchans = mdf.load('subject',trialObj.subject,'trial',trialObj.trial,'mdf_type','egg','EGGlabel',paddleChans);
                    dataCellVec = [EGGchans(:).data.wf];
                    if ~isrow(dataCellVec)
                        dataCellVec = dataCellVec';
                    end
                    existingObj.data.wf = mean(cell2mat(dataCellVec),2);
                    existingObj.data.time = EGGchans(1).data.time;
                    existingObj.save;
                end
            else
                error('invalid trial type')
            end
        end
        paddleLabels{iPaddle} = chanLabel;
    end
    summaryObj.md.paddleLabels = paddleLabels;
    summaryObj.save;
    disp('Finished processing paddle averages')
end
