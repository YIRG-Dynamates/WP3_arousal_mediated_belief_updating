function filename = GiveCopyNumber(filename)
%Check if file exists. If so, give it a copy number (similar to Windows)

if (exist(filename, 'file') == 2)
    
    [full_path,name,ext] = fileparts(filename);
    
    copy_nr = 1;
    while 1
        if copy_nr < 10
            copy_nr_str = ['00' num2str(copy_nr)];
        elseif copy_nr < 100
            copy_nr_str = ['0' num2str(copy_nr)];
        else
            copy_nr_str = num2str(copy_nr);
        end
        filename = fullfile(full_path,[name ' (' copy_nr_str ')' ext]);
        
        if ~(exist(filename, 'file') == 2)
            break;
        else
            copy_nr = copy_nr+1;
        end
    end
    
end %[EoF]
