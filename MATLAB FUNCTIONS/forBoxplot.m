
function forBox = forBoxplot(delta_amps_all, included_sounds)

% inputs only per column, not for all sujects at once
% make two vectors for the deltas and SACs

deltas = [];
SACs = [];

for trial = 1:200;
    if ~isempty(delta_amps_all{trial, 1});

        logical = included_sounds{trial, 1}.incl_sounds 

        deltas = vertcat(deltas, delta_amps_all{trial, 1}(logical));
        SACs = vertcat(SACs, included_sounds{trial, 1}.SAC_level(logical)');
    end 
end

forBox(:,1) = deltas
forBox(:,2) = SACs

forBox(forBox(:,2) > 5, :) = []

end %eof