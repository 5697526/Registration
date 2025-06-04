function files = getAllFiles(dirName)
  % Get list of all files and folders in the given directory
  files = dir(dirName);
  % Remove the '.' and '..' directories
  files = files(~strcmp({files.name}, '.') & ~strcmp({files.name}, '..'));
  % Initialize an empty cell array to store the names of all the files
  file_names = {};
  % Loop through the files and folders
  for i = 1:length(files)
    file = files(i);
    % If the file is a directory, recursively call the function to get its files
    if file.isdir
      sub_files = getAllFiles(fullfile(dirName, file.name));
      % Add the subdirectory files to the file list
      file_names = [file_names; sub_files];
    % If the file is not a directory, add it to the file list
    else
      file_names = [file_names; fullfile(dirName, file.name)];
    end
  end
  % Return the file names
  files = file_names;
end