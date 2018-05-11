function users = listUsers()
    f = fopen('user-profiles.txt', 'r');
    C = textscan(f, '%s %s %s','delimiter', '\t');
    fclose(f);

    users = C{1}(2:end);
end