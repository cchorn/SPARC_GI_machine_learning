function [] = createBipolarPaddleAvgEGGobj(trialObj)
    
    %   DESCRIPTION
    %   ===================================================================
    %   Generates bipolar pair objects for all possible EGG bipolar pairs 
    %
    %   INPUTS
    %   ===================================================================
    %   trialObj    :   MDF object for trial to be processed
    %   paddlepairs :   nx2 array where columns are EGG paddles
    %                   to difference
    %   NOTE
    %   ===================================================================
    %   Paddle average objects should have been created prior to running
    %   this function
    %
    %   Author: Ameya C. Nanivadekar
    %   email: acnani@gmail.com
    
    summaryObj = mdf.load('subject',trialObj.subject,'mdf_type','summary');
    paddleNum = summaryObj.EGG.paddleNum;
    uniquePaddles = unique(paddleNum);
    paddlePairs   = nchoosek(uniquePaddles, 2);
    numCombos = size(paddlePairs,1);
    
    bipolarObj_template = mdfObj;
    bipolarObj_template.type = 'bipolarPaddleAvgEGG';
    bipolarObj_template.md.subject = trialObj.subject;
    bipolarObj_template.md.trial = trialObj.trial;
    bipolarObj_template.md.paddle1 = [];
    bipolarObj_template.md.paddle2 = [];
    bipolarObj_template.md.chanLabel = [];
    bipolarObj_template.md.fs = 2e3;
    
    paddlePairLabels = cell(1,numCombos);        
    for iCombo = 1:numCombos
        chanLabel = sprintf('paddle%02d-%02d',paddlePairs(iCombo,1),paddlePairs(iCombo,2));
        
        if ismember(trialObj.trialType, {'rec', 'emetine','euthasol', 'rec_postop','rec_awake', 'feeding', 'post_feeding', 'pre_feeding', 'emetine_awake', 'feeding_stim','water_awake'})
            for iSeg = 1:trialObj.getLen('segments')
                segObj = trialObj.segments(iSeg);
                existingObj = mdf.load('subject',segObj.subject,'trial',segObj.trial,'mdf_type','bipolarPaddleAvgEGG','chanLabel',chanLabel,'segment',segObj.segment);
                if isempty(existingObj)
                    paddleObj = mdf.load('subject',segObj.subject,'trial',segObj.trial,'mdf_type','paddleAvgEGG','paddleNum',paddlePairs(iCombo,:),'segment',segObj.segment);
                    if length(paddleObj) ~= 2
                        error('missing paddle objects')
                    end
                    
                    fprintf('Processing segment %d, bipolar pair %s\n', iSeg, chanLabel)
                    paddle1 = mdf.load('subject',segObj.subject,'trial',segObj.trial,'mdf_type','paddleAvgEGG','paddleNum',paddlePairs(iCombo,1),'segment',segObj.segment);
                    paddle2 = mdf.load('subject',segObj.subject,'trial',segObj.trial,'mdf_type','paddleAvgEGG','paddleNum',paddlePairs(iCombo,2),'segment',segObj.segment);
                    
                    bipolarObj = bipolarObj_template.clone;
                    bipolarObj.setFiles(fullfile('<DATA_BASE>',segObj.subject,'bipolarPaddleAvgEGG',sprintf('Trial%02d_seg%02d_ch%s',segObj.trial, segObj.segment, chanLabel)));
                    bipolarObj.md.paddle1 = paddlePairs(iCombo,1);
                    bipolarObj.md.paddle2 = paddlePairs(iCombo,2);
                    bipolarObj.md.chanLabel = chanLabel;
                    bipolarObj.md.segment = segObj.segment;

                    bipolarObj.data.wf = paddle1.data.wf-paddle2.data.wf;
                    bipolarObj.data.time = paddle1.data.time;
                    bipolarObj.save;

                    mdf.addParentChildRelation(paddle1, bipolarObj,'bipolarPaddleAvgEGG');
                    mdf.addParentChildRelation(paddle2, bipolarObj,'bipolarPaddleAvgEGG');
                    mdf.addParentChildRelation(segObj, bipolarObj, 'bipolarPaddleAvgEGG');

                    segObj.save;
                    paddle1.save;
                    paddle2.save;
                    bipolarObj.save;
                else
                    fprintf('%s already created. Overwriting wf\n',chanLabel)
                    paddle1 = mdf.load('subject',segObj.subject,'trial',segObj.trial,'mdf_type','paddleAvgEGG','paddleNum',paddlePairs(iCombo,1),'segment',segObj.segment);
                    paddle2 = mdf.load('subject',segObj.subject,'trial',segObj.trial,'mdf_type','paddleAvgEGG','paddleNum',paddlePairs(iCombo,2),'segment',segObj.segment);
                    existingObj.data.wf = paddle1.data.wf-paddle2.data.wf;
                    existingObj.data.time = paddle1.data.time;
                    existingObj.save;
                end
            end
        else
            if ismember(trialObj.trialType, {'stim', 'pauli_stim','stim_postop', 'stim_awake', 'balloon', 'palpate'})
                existingObj = mdf.load('subject',trialObj.subject,'trial',trialObj.trial,'mdf_type','bipolarPaddleAvgEGG','chanLabel',chanLabel);
                if isempty(existingObj)
                    paddleObj = mdf.load('subject',trialObj.subject,'trial',trialObj.trial,'mdf_type','paddleAvgEGG','paddleNum',paddlePairs(iCombo,:));
                    if length(paddleObj) ~= 2
                        error('missing paddle objects')
                    end
                    
                    fprintf('Processing trial %d,bipolar pair %s\n', trialObj.trial, chanLabel)
                    
                    paddle1 = mdf.load('subject',trialObj.subject,'trial',trialObj.trial,'mdf_type','paddleAvgEGG','paddleNum',paddlePairs(iCombo,1));
                    paddle2 = mdf.load('subject',trialObj.subject,'trial',trialObj.trial,'mdf_type','paddleAvgEGG','paddleNum',paddlePairs(iCombo,2));
                    
                    bipolarObj = bipolarObj_template.clone;
                    bipolarObj.setFiles(fullfile('<DATA_BASE>',trialObj.subject,'bipolarPaddleAvgEGG',sprintf('Trial%02d_ch%s',trialObj.trial, chanLabel)));
                    bipolarObj.md.paddle1 = paddlePairs(iCombo,1);
                    bipolarObj.md.paddle2 = paddlePairs(iCombo,2);
                    bipolarObj.md.chanLabel = chanLabel;

                    bipolarObj.data.wf = paddle1.data.wf-paddle2.data.wf;
                    bipolarObj.data.time = paddle1.data.time;
                    bipolarObj.save;

                    mdf.addParentChildRelation(paddle1, bipolarObj,'bipolarPaddleAvgEGG');
                    mdf.addParentChildRelation(paddle2, bipolarObj,'bipolarPaddleAvgEGG');
                    mdf.addParentChildRelation(trialObj, bipolarObj, 'bipolarPaddleAvgEGG');

                    trialObj.save;
                    paddle1.save;
                    paddle2.save;
                    bipolarObj.save;
                    
                else
                    fprintf('%s already created. Overwriting wf\n',chanLabel)
                    paddle1 = mdf.load('subject',trialObj.subject,'trial',trialObj.trial,'mdf_type','paddleAvgEGG','paddleNum',paddlePairs(iCombo,1));
                    paddle2 = mdf.load('subject',trialObj.subject,'trial',trialObj.trial,'mdf_type','paddleAvgEGG','paddleNum',paddlePairs(iCombo,2));
                    existingObj.data.wf = paddle1.data.wf-paddle2.data.wf;
                    existingObj.data.time = paddle1.data.time;
                    existingObj.save;
                end
            else
                error('invalid trial type')
            end
        end
        paddlePairLabels{iCombo} = chanLabel;
    end
    summaryObj.md.paddlePairLabels = paddlePairLabels;
    summaryObj.save;
    disp('Finished processing paddle pairs')
end
