function triggersInfo = GetAllTriggers(data)

%The binary stuff was to send triggers to the skin conductance recorder in Birmingham   
%Leave here - possibly useful in the future

if ~isempty(data)

    BinaryPowers    = [0 1 2 3 4 5 7];  %Note 6 is missing
    BinaryColumnNrs = [4 3 6 5 8 7 9];  %Binary channels order is mixed up in recorded data

    %Find all trigger row nrs
    triggersInfo = find(sum(data(:,BinaryColumnNrs),2)>0);
    if ~isempty(triggersInfo)
        nTriggerRows = length(triggersInfo);
        triggersInfo = [zeros(nTriggerRows,1) triggersInfo];
        for i=1:nTriggerRows
            binaryCodeTemp = data(triggersInfo(i,2),BinaryColumnNrs);
            for j=1:numel(BinaryPowers)
                triggersInfo(i,1) = triggersInfo(i,1) + sign(binaryCodeTemp(j))*2^BinaryPowers(j); 
            end
        end

        %Delete connecting triggers with the same value
        nTriggerRows = size(triggersInfo,1);
        for i=nTriggerRows:-1:1
            if i~=1
                if (triggersInfo(i,1) == triggersInfo(i-1,1)) && (triggersInfo(i,2) == (triggersInfo(i-1,2)+1))
                    triggersInfo(i,:) = [];
                end
            end
        end
    else
        triggersInfo = zeros(0,2);
    end

%If input is empty - then return a triggerInfo cell array with all necessary info ('value','code','description')    
else
    
    %Create all possible trigger values
    AllPossibleTriggerValues = nan(127,1);
    AllPossibleTriggerCodes = nan(127,7);
    counter=0;
    for i0=0:1
        for i1=0:1
            for i2=0:1
                for i3=0:1
                    for i4=0:1
                        for i5=0:1
                            for i7=0:1
                                counter=counter+1;
                                AllPossibleTriggerValues(counter,1) = i0*2^0 + i1*2^1 + i2*2^2 + i3*2^3 + i4*2^4 + i5*2^5 + i7*2^7;
                                AllPossibleTriggerCodes(counter,:) = [i0 i1 i2 i3 i4 i5 i7];
                            end
                        end
                    end
                end
            end
        end
    end
    
    %Sort the possibilities in ascending order
    [AllPossibleTriggerValues,Idx2sort] = sort(AllPossibleTriggerValues(:,1));
    AllPossibleTriggerCodes = AllPossibleTriggerCodes(Idx2sort,:);

    %Delete trigger '0'
    AllPossibleTriggerValues(1,:) = [];
    AllPossibleTriggerCodes(1,:) = [];
    
    %Create cell array to save
    nPotentialTriggers = length(AllPossibleTriggerValues);
    triggersInfo = cell(nPotentialTriggers,3);
    for i=1:nPotentialTriggers
        triggersInfo{i,1} = AllPossibleTriggerValues(i,:);
        triggersInfo{i,2} = AllPossibleTriggerCodes(i,:);
    end
    
    %Hard code some meaningful trigger values
    triggersInfo{(AllPossibleTriggerValues == 191),3} = 'Start of Block';
    triggersInfo{(AllPossibleTriggerValues == 190),3} = 'End of Block';
    
    triggersInfo{(AllPossibleTriggerValues == 189),3} = '5sec Fix Start';
    triggersInfo{(AllPossibleTriggerValues == 188),3} = '5sec Fix End';
    
    triggersInfo{(AllPossibleTriggerValues == 187),3} = 'AV stimulus';
    triggersInfo{(AllPossibleTriggerValues == 186),3} = 'A stimulus';
    
    triggersInfo{(AllPossibleTriggerValues == 185),3} = 'Response Prompt';
    triggersInfo{(AllPossibleTriggerValues == 184),3} = 'Response Given';
    
    triggersInfo{(AllPossibleTriggerValues == 183),3} = 'Feedback Positive';
    triggersInfo{(AllPossibleTriggerValues == 182),3} = 'Feedback Negative';
    
end

end %[EOF]
