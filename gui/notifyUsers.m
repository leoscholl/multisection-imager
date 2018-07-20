function notifyUsers(users, title, body, color)
    
    if ischar(users)
        users = {users};
    end

    % Read preference file
    f = fopen('user-profiles.txt', 'r');
    C = textscan(f, '%s %s %s','delimiter', '\t');
    fclose(f);
    
    email = C{2}{1};
    password = C{3}{1};

    % Send message to each user
    for u = 1:length(users)
        row = find(ismember(C{1}, users{u}));
        method = C{2}{row};
        link = C{3}{row};
        error = [];
        
        switch method
            case 'slack'
                
                data = [];
                data.attachments(2).fallback = title;
                data.attachments(2).pretext = title;
                if exist('color', 'var')
                    data.attachments(2).color = color;
                end
                data.attachments(2).text = body;
                data.attachments(1).fallback = title;
                options = weboptions('MediaType', 'application/json', 'RequestMethod', 'POST');
                
                try
                    response = webwrite(link,data,options);
                catch e
                    error = e;
                end

            case 'email'
                props = java.lang.System.getProperties;
                props.setProperty('mail.smtp.auth','true');
                props.setProperty('mail.smtp.socketFactory.class', 'javax.net.ssl.SSLSocketFactory');
                props.setProperty('mail.smtp.socketFactory.port','465');

                setpref('Internet','E_mail',email);
                setpref('Internet','SMTP_Server','imap.gmail.com');
                setpref('Internet','SMTP_Username',email);
                setpref('Internet','SMTP_Password',password);
                
                try
                    sendmail(link, title, body);
                catch e
                    error = e;
                end
        end
        
        if ~isempty(error)
            warning('Couldn''t notify user %s.', C{1}{row});
            warning(getReport(error));
        end
    end
end