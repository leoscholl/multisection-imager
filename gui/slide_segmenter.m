function varargout = slide_segmenter(varargin)
% SLIDE_SEGMENTER MATLAB code for slide_segmenter.fig
%      SLIDE_SEGMENTER, by itself, creates a new SLIDE_SEGMENTER or raises the existing
%      singleton*.
%
%      H = SLIDE_SEGMENTER returns the handle to a new SLIDE_SEGMENTER or the handle to
%      the existing singleton*.
%
%      SLIDE_SEGMENTER('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SLIDE_SEGMENTER.M with the given input arguments.
%
%      SLIDE_SEGMENTER('Property','Value',...) creates a new SLIDE_SEGMENTER or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before slide_segmenter_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to slide_segmenter_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help slide_segmenter

% Last Modified by GUIDE v2.5 20-Jun-2018 14:15:21

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @slide_segmenter_OpeningFcn, ...
    'gui_OutputFcn',  @slide_segmenter_OutputFcn, ...
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


% --- Executes just before slide_segmenter is made visible.
function slide_segmenter_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to slide_segmenter (see VARARGIN)

% Filter the input image
handles.sigma = round(varargin{2});
handles.image = imgaussfilt(varargin{1}, handles.sigma);
handles.sections = {};
guidata(hObject, handles);

% Display initial image
addlistener(handles.Slider,'Value','PreSet',@(~,~)Slider_Moving(hObject));
for c = 1:size(handles.image, 3)
    handles.Channel.String{c} = sprintf('Channel %d', c);
end
Channel_Callback(handles.Channel, eventdata, handles);

% Update brush display
handles.Brush.Value = handles.sigma*10;
handles.Brush.Min = handles.sigma;
handles.Brush.Max = min(length(handles.image),handles.sigma*500);

% Set the gui name
if length(varargin) > 3
    set(hObject, 'Name', strcat('Slide Segmenter - ', varargin{4}));
else
    set(hObject, 'Name', 'Slide Segmenter');
end

% UIWAIT makes slide_segmenter wait for user response (see UIRESUME)
if varargin{3}
    uiwait(hObject);
end


% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure
if isequal(get(hObject, 'waitstatus'), 'waiting')
    uiresume(hObject)
else
    delete(hObject);
end

% --- Outputs from this function are returned to the command line.
function varargout = slide_segmenter_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Collect ROIs with corresponding convex hulls
stats = regionprops(handles.mask, 'BoundingBox', 'Centroid');
boundaries = bwboundaries(handles.mask, 'noholes');
sections = nan(length(handles.sections),1);
rois = nan(length(handles.sections), 4);
refs = nan(length(handles.sections),2);
for n = 1:length(handles.sections)
    sections(n) = str2double(handles.sections{n}.label.String);
    if isnan(sections(n))
        sections(n) = -n;
    end
    rois(n,:) = stats(n).BoundingBox;
    refs(n,:) = stats(n).Centroid;
end
varargout = {rois, sections, boundaries, refs};
delete(hObject);

function updateOverlay(handles)

% Display
handles.overlay.AlphaData = 0.2*handles.mask;
stats = regionprops(handles.mask, 'Centroid');

% Delete old sections
for i = 1:length(handles.sections)
    delete(handles.sections{i}.label);
end
handles.sections = cell(1,min(length(stats), 50));
for i = 1:length(handles.sections)
    handles.sections{i}.label = text(handles.Axes,stats(i).Centroid(1),...
        stats(i).Centroid(2),num2str(i), 'FontSize', 16, 'Color', [0.6,0,0.8]);
    handles.sections{i}.label.ButtonDownFcn = ...
        @(~,~)set(handles.sections{i}.label,'Editing', 'on');
end

guidata(handles.figure1, handles);

% --- Executes on Slider moving.
function Slider_Moving(figure)
handles = guidata(figure);
image = handles.image(:,:,handles.Channel.Value);
image = imbinarize(image, handles.Slider.Value);
image = bwareaopen(image, handles.sigma*10);
handles.mask = imfill(image, 'holes');
updateOverlay(handles);

% --- Executes during object creation, after setting all properties.
function Slider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

% --- Executes during object creation, after setting all properties.
function Brush_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Brush (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

% --- Executes on button press in Draw.
function Draw_Callback(hObject, eventdata, handles)
% hObject    handle to Draw (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if hObject.Value == 1
    handles.Erase.Value = 0;
    set(handles.figure1,'Pointer','hand');
    set(handles.figure1, 'WindowButtonDownFcn', ...
        @(src, evnt)mousePressed('draw'));
    set(handles.figure1,'WindowButtonMotionFcn',@(~,~)drawOnMask('hover-draw'));
else
    set(handles.figure1,'Pointer','arrow');
    set(handles.figure1, 'WindowButtonDownFcn', '');
    set(handles.figure1,'WindowButtonMotionFcn','');
end

% --- Executes on button press in Erase.
function Erase_Callback(hObject, eventdata, handles)
% hObject    handle to Erase (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if hObject.Value == 1
    handles.Draw.Value = 0;
    set(handles.figure1,'Pointer','hand');
    set(handles.figure1, 'WindowButtonDownFcn', ...
        @(src, evnt)mousePressed('erase'));
    set(handles.figure1,'WindowButtonMotionFcn',@(~,~)drawOnMask('hover-erase'));
else
    set(handles.figure1,'Pointer','arrow');
    set(handles.figure1, 'WindowButtonDownFcn', '');
    set(handles.figure1,'WindowButtonMotionFcn','');

end

% --- Executes on button press in CloseButton.
function CloseButton_Callback(hObject, eventdata, handles)
% hObject    handle to CloseButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
uiresume(handles.figure1);


function drawOnMask(type)
handles = guidata(gcbf);
pos = get(handles.Axes,'CurrentPoint');
r = handles.Brush.Value;

target = false(size(handles.mask));
[x,y] = meshgrid(1:size(handles.mask,2), 1:size(handles.mask,1));
target((x - pos(1,1)).^2 + (y - pos(1,2)).^2 < r^2) = true;

if strcmp(type,'draw')
    handles.mask(target)=1;
    handles.overlay.AlphaData = 0.2*handles.mask;
elseif strcmp(type,'erase')
    handles.mask(target)=0;
    handles.overlay.AlphaData = 0.2*handles.mask;
elseif strcmp(type, 'hover-draw')
    mask = handles.mask;
    target((x - pos(1,1)).^2 + (y - pos(1,2)).^2 < (r-1)^2) = false;
    mask(target) = 1;
    handles.overlay.AlphaData = 0.2*mask;
elseif strcmp(type, 'hover-erase')
    mask = handles.mask;
    target((x - pos(1,1)).^2 + (y - pos(1,2)).^2 < (r-1)^2) = false;
    mask(target) = 0;
    handles.overlay.AlphaData = 0.2*mask;
end
guidata(gcbf, handles);

function mousePressed(type)
handles = guidata(gcbf);
pos = round(get(handles.Axes,'CurrentPoint'));
pos = pos(1,2:-1:1);
if any(pos > size(handles.mask)) || any(pos < 0)
    % outside click
    return;
end
drawOnMask(type);
set(gcbf,'WindowButtonMotionFcn',@(~,~)drawOnMask(type));
set(gcbf,'WindowButtonUpFcn',@(~,~)mouseUnpressed(type));


function mouseUnpressed(type)

% Clean up the evidence ...
handles = guidata(gcbf);
set(handles.figure1,'WindowButtonUpFcn','');
set(handles.figure1,'WindowButtonMotionFcn',@(~,~)drawOnMask(['hover-',type]));
updateOverlay(handles);


% --- Executes on slider movement.
function Brush_Callback(hObject, eventdata, handles)
% hObject    handle to Brush (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider


% --- Executes on selection change in Channel.
function Channel_Callback(hObject, eventdata, handles)
% hObject    handle to Channel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns Channel contents as cell array
%        contents{get(hObject,'Value')} returns selected item from Channel
channel = hObject.Value;
image = handles.image(:,:,channel);
hold(handles.Axes, 'off');
imshow(image, [min(image(:)), max(image(:))], ...
    'Parent', handles.Axes);
hold(handles.Axes, 'on');
blue = repmat(reshape([0,.3,1],1,1,3),size(image,1),size(image,2),1);
handles.overlay = imshow(blue, 'Parent', handles.Axes);
guidata(handles.figure1, handles);

% Apply initial threshold
thr = double(multithresh(image))/double(intmax(class(image)));
handles.Slider.Min = double(min(image(:)))/double(intmax(class(image)));
handles.Slider.Max = thr*3;
handles.Slider.Value = thr;
Slider_Moving(handles.figure1);

% --- Executes during object creation, after setting all properties.
function Channel_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Channel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
