
function reg_results = reg_pP(surp_mat, delta_mat, incl_mat)

% initialize
subjects_all = width(surp_mat)
trials_all = height(surp_mat)
reg_results = []

%loop
%subject = 1
for subject = 1:subjects_all

    surpr_i = [];
    delta_i = [];
    for trial = 1:trials_all
    
        incl_sound = incl_mat{trial, subject}.incl_sounds  ;
        surpr_i = [surpr_i, surp_mat{trial, subject}(incl_sound)  ];
        delta_i = [delta_i, delta_mat{trial, subject}(incl_sound)' ];

    end
    
    surpr_i = zscore(surpr_i);
    delta_i = zscore(delta_i);
    
    SURP = [ones(length(surpr_i),1) surpr_i'];
    
    [b,bint,r,rint,stats] =  regress(delta_i',SURP) ;
    
    
    reg_results{subject,1} = b(1);
    reg_results{subject,2} = b(2);
    reg_results{subject,3} = bint;
    %reg_results{subject,4} = r;
    reg_results{subject,4} = stats;

end
end %eof