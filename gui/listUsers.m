function users = listUsers(file)

if ~exist('file', 'var')
    file = 'user-profiles.txt';
end

if ~exist(file, 'file')
    % file = uigetfile('*.mat', 'Open user profiles');
    error('No user profiles found, please create a user-profiles.txt file');
end
f = fopen(file, 'r');
C = textscan(f, '%s %s %s','delimiter', '\t');
fclose(f);

users = C{1}(2:end);
end