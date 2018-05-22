function varargout = multisection_imager(varargin)
% MULTISECTION_IMAGER MATLAB code for multisection_imager.fig
%      MULTISECTION_IMAGER, by itself, creates a new MULTISECTION_IMAGER or raises the existing
%      singleton*.
%
%      H = MULTISECTION_IMAGER returns the handle to a new MULTISECTION_IMAGER or the handle to
%      the existing singleton*.
%
%      MULTISECTION_IMAGER('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MULTISECTION_IMAGER.M with the given input arguments.
%
%      MULTISECTION_IMAGER('Property','Value',...) creates a new MULTISECTION_IMAGER or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before multisection_imager_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to multisection_imager_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help multisection_imager

% Last Modified by GUIDE v2.5 22-May-2018 12:51:18

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @multisection_imager_OpeningFcn, ...
                   'gui_OutputFcn',  @multisection_imager_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before multisection_imager is made visible.
function multisection_imager_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to multisection_imager (see VARARGIN)

% Choose default command line output for multisection_imager
handles.output = hObject;
if length(varargin) == 1
    handles.mm = varargin{1};
elseif evalin( 'base', 'exist(''mm'',''var'') == 1' )
    handles.mm = evalin('base','mm');
else
    handles.mm = mmInit;
end
handles.uiPrefsList = {'DataDir', ...
    'Channels', 'Exposures', 'Grid', 'AutoConvert', ...
    'SaveASC', 'CountCells'};
% Update handles structure
guidata(hObject, handles);

% Set users menu
users = listUsers();
handles.User.String = users;

% Load preferences
loadPrefs(handles);

% UIWAIT makes multisection_imager wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = multisection_imager_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure
savePrefs(handles);
delete(hObject);

% --- Executes on button press in PreFocus.
function PreFocus_Callback(hObject, eventdata, handles)
% hObject    handle to PreFocus (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if ~isfield(handles, 'mm')
    fprintf(2, 'No MicroManager environment open. Please Start MicroManager.\n');
    return;
end
mm = handles.mm;
if checkPositionList(mm) == 0
    handles.PositionListError.Visible = 'on';
    return;
else
    handles.PositionListError.Visible = 'off';
end
if isempty(handles.Grid.String)
    gridSize = [];
else
    gridSize = str2double(strsplit(handles.Grid.String,{' ',','},...
        'CollapseDelimiters',true));
end
preFocus(mm, gridSize);

% --- Executes on button press in Start.
function Start_Callback(hObject, eventdata, handles)
% hObject    handle to Start (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if ~isfield(handles, 'mm')
    fprintf(2, 'No MicroManager environment open. Please Start MicroManager.\n');
    return;
end
mm = handles.mm;
if checkPositionList(mm) == 0
    handles.PositionListError.Visible = 'on';
    return;
else
    handles.PositionListError.Visible = 'off';
end

title = 'Starting acquisition';
body = 'You will be notified when it is finished';
color = '#439FE0';
users = strtrim(strsplit(handles.User.String{handles.User.Value},...
    {' ',','}, 'CollapseDelimiters',true));
notifyUsers(users, title, body, color);

% Acquisition
dir = handles.DataDir.String;
subject = handles.Subject.String;
slide = handles.Slide.String;
if isempty(dir) || isempty(subject) || isempty(slide)
    handles.FileError.Visible = 'on';
    return;
else
    handles.Error.Visible = 'off';
end
filepath = fullfile(dir, subject, slide);
channels = strtrim(strsplit(handles.Channels.String,{' ',','},...
    'CollapseDelimiters',true));
exposures = str2double(strsplit(handles.Exposures.String,{' ',','},...
    'CollapseDelimiters',true));
fprintf('Acquiring...\n');
setStatus(handles, 'Acquiring...');
result = acquireMultiple(mm, filepath, channels, exposures);
if isempty(result.error)
    title = 'Multisection acquisition complete!';
    body = sprintf('Finished in %d hours, %d minutes, and %d seconds', ...
        floor(result.elapsed/60/60), floor(result.elapsed/60), ...
        round(mod(result.elapsed, 60)));
    color = 'good';
else
    title = 'Multisection acquisition failed...';
    body = getReport(e,'basic','hyperlinks','off');
    color = 'danger';
end
notifyUsers(users, title, body, color);
% Post-processing
doConvert = handles.AutoConvert.Value;
doAsc = handles.SaveASC.Value;
doCellCount = handles.CountCells.Value;
pairs = handles.Pairs.Data;
if doConvert
    fprintf('Exporting...\n');
    setStatus(handles, 'Exporting...');
    postProcess(result.store, dir, subject, [], doAsc, doCellCount, pairs);
    fprintf('Done exporting.\n');
end
setStatus(handles, '');

% --- Executes on button press in Convert.
function Convert_Callback(hObject, eventdata, handles)
% hObject    handle to Convert (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if ~isfield(handles, 'mm')
    fprintf(2, 'No MicroManager environment open. Please Start MicroManager.\n');
    return;
end
dir = handles.DataDir.String;
subject = handles.Subject.String;
if isempty(dir) || isempty(subject)
    handles.FileError.Visible = 'on';
    return;
else
    handles.Error.Visible = 'off';
end
doAsc = handles.SaveASC.Value;
doCellCount = handles.CountCells.Value;
pairs = handles.Pairs.Data;
mm = handles.mm;
windows = mm.displays().getAllImageWindows().toArray();
for w = 1:length(windows)
    name = windows(w).getName();
    if strcmp(name, 'Snap/Live View')
        continue;
    end
    store = windows(w).getDatastore();
    fprintf('Converting %s...\n', name);
    setStatus(handles, 'Exporting...');
    postProcess(store, dir, subject, [], doAsc, doCellCount, pairs);
    fprintf('Done converting %s.\n', name);
end
setStatus(handles, '');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Preference saving and other helper fns   %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- Sets the title with a status indication
function setStatus(handles, text)
if isempty(text)
    set(handles.figure1, 'Name', 'Multisection Imager');
else
    set(handles.figure1, 'Name', ['Multisection Imager - ', text]);
end
drawnow;

% --- Executes on selection change in User.
function User_Callback(hObject, eventdata, handles)
% hObject    handle to User (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns User contents as cell array
%        contents{get(hObject,'Value')} returns selected item from User
loadPrefs(handles, handles.User.String{handles.User.Value});

% --- Loads preferences.
function loadPrefs(handles, user)
uiPrefsList = handles.uiPrefsList;
prfgroup = 'multisection_imager';
if ~exist('user', 'var') || isempty(user)
    if ispref(prfgroup, 'User')
        user = getpref(prfgroup, 'User');
    end
end
userValue = find(ismember(handles.User.String, user));
if ~isempty(user) && ~isempty(userValue)
    handles.User.Value = userValue;
    prfgroup = strcat('multisection_imager_', user);
end
for i = 1:length(uiPrefsList)
    prfname = uiPrefsList{i};
    if ispref(prfgroup,prfname) %pref exists
        if isfield(handles, prfname) %ui widget exists
            myhandle = handles.(prfname);
            prf = getpref(prfgroup,prfname);
            uiType = get(myhandle,'Style');
            switch uiType
                case 'edit'
                    if ischar(prf)
                        set(myhandle, 'String', prf);
                    else
                        set(myhandle, 'String', num2str(prf));
                    end
                case 'checkbox'
                    if islogical(prf) || isnumeric(prf)
                        set(myhandle, 'Value', prf);
                    end
                case 'popupmenu'
                    str = get(myhandle,'String');
                    if isnumeric(prf) && prf <= length(str)
                        set(myhandle, 'Value', prf);
                    end
                case 'listbox'
                    if iscellstr(prf) || ischar(prf)
                        set(myhandle, 'String', prf);
                    end
            end
        end
    end
end
drawnow

% --- Stores preferences.
function savePrefs(handles)
uiPrefsList = handles.uiPrefsList;
user = handles.User.String{handles.User.Value};
setpref('multisection_imager', 'User', user);
if isempty(user)
    prfgroup = 'multisection_imager';
else
    prfgroup = strcat('multisection_imager_', user);
end
for i = 1:length(uiPrefsList)
    prfname = uiPrefsList{i};
    myhandle = handles.(prfname);
    uiType = get(myhandle,'Style');
    switch uiType
        case 'edit'
            prf = get(myhandle, 'String');
            setpref(prfgroup, prfname, prf);
        case 'checkbox'
            prf = get(myhandle, 'Value');
            if ~islogical(prf); prf=logical(prf);end
            setpref(prfgroup, prfname, prf);
        case 'popupmenu'
            prf = get(myhandle, 'Value');
            setpref(prfgroup, prfname, prf);
        case 'listbox'
            prf = get(myhandle, 'String');
            setpref(prfgroup, prfname, prf);
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CreateFcns - below functions are useless %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- Executes during object creation, after setting all properties.
function Channels_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Channels (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function User_CreateFcn(hObject, eventdata, handles)
% hObject    handle to User (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function Exposures_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Exposures (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function Subject_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Subject (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function Slide_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Slide (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function Sections_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Sections (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



% --- Executes during object creation, after setting all properties.
function DataDir_CreateFcn(hObject, eventdata, handles)
% hObject    handle to DataDir (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function Grid_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Grid (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

