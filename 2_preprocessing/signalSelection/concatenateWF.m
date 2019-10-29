function concatWF = concatenateWF(wfObjArray)
    
    %   DESCRIPTION
    %   ===================================================================
    %   Concatenates the waveforms for an array of MDF objects containing a
    %   signal waveform. Particularly useful for segmented trials
    %
    %   INPUTS
    %   ===================================================================
    %   wfObjArray   :  (1xn) array of MDF objects containing a wf field
    % 
    %   NOTE
    %   ===================================================================
    %   The cell2mat and (:) indexing may have to be tweaked based on the 
    %   MATLAB version in use.
    %
    %   Author: Ameya C. Nanivadekar
    %   email: acnani@gmail.com
    
    if isempty(wfObjArray)
        concatWF = 0;
    elseif numel(wfObjArray) == 1
        concatWF = wfObjArray.wf;
    else
        [~,wfMask] = sort(cell2mat(wfObjArray(:).segment));            
        concatWF = cell2mat(wfObjArray(wfMask).wf);                 % all signal wfs will be a column vector
    end
    concatWF(concatWF > 10^8 | concatWF < -10^8) = 0;
end