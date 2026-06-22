function dynamates_repository_path = LoadDynamates(dynamates_repository_folder_name)
%Load the dynamates file structure if not yet done
%The Dynamates repository folder is returned

if nargin < 1
    dynamates_repository_folder_name = 'wp1_spatial_predictions';
end

%Check if Dynamates paths structure has already been loaded
if ismember('dynamates_paths', who('global'))
    global dynamates_paths
    dynamates_repository_path = dynamates_paths.repository;
    return
end

%Check if Dynamates repository exists as part of the current directory
current_folder = cd;
first_char_idx = strfind(current_folder,dynamates_repository_folder_name);
if ~isempty(first_char_idx)
    last_char_idx = first_char_idx(1)+length(dynamates_repository_folder_name)-1;
    dynamates_repository_path = current_folder(1:last_char_idx);
    
else
    %Let the user find the Dynamates repository manually
    dynamates_repository_path = uigetdir('', ['Select the Dynamates startup folder ("' dynamates_repository_folder_name '")']);
    if dynamates_repository_path == 0
        error('The dynamates repository path is required in order to run this program'); %Cancel was pressed in the GUI
    else
        [~,selected_folder_name] = fileparts(dynamates_repository_path);
        if ~strcmp(selected_folder_name,dynamates_repository_folder_name)
            error(['The user selected an invalid dynamates repository path: Selected folder was not: "' dynamates_repository_folder_name '"']);
        end
    end
end

%Run the Dynamates startup script
cd(dynamates_repository_path);
dynamates_startup;
cd(current_folder);

end %[EoF]
