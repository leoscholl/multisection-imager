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

% Last Modified by GUIDE v2.5 10-May-2018 13:45:43

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
end
% Update handles structure
guidata(hObject, handles);

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
delete(hObject);

% --- Executes on button press in StartMM.
function StartMM_Callback(hObject, eventdata, handles)
% hObject    handle to StartMM (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
mm = mmInit;
assignin('base', 'mm', mm);
pause(0.1); % allow interrupt callback
handles.mm = mm;
guidata(handles.figure1, handles)

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
gridSize = str2double(strsplit(handles.Grid.String,{' ',','},...
    'CollapseDelimiters',true));
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
users = strtrim(strsplit(handles.User.String,{' ',','},...
    'CollapseDelimiters',true));
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
    fprintf('Converting...\n');
    postProcess(result.store, dir, subject, [], doAsc, doCellCount, pairs);
    fprintf('Done converting.\n');
end

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
    store = windows(w).getDatastore();
    fprintf('Converting %s...\n', name);
    postProcess(store, dir, subject, [], doAsc, doCellCount, pairs);
    fprintf('Done converting %s.\n', name);
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
