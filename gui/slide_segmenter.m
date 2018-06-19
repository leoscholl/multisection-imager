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

% Last Modified by GUIDE v2.5 18-Jun-2018 17:15:20

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

% Input image
handles.image = varargin{1};
handles.gaussImage = varargin{2};

% Apply initial threshold
thr = graythresh(handles.gaussImage)*0.95;
handles.Slider.Max = double(max(handles.gaussImage(:)))/double(intmax(class(handles.gaussImage)));
handles.Slider.Value = thr;
f = imbinarize(handles.gaussImage, thr);
handles.mask = imfill(f, 'holes');
addlistener(handles.Slider,'Value','PreSet',@(~,~)Slider_Moving(hObject));

% Display image and mask
imshow(handles.image, [min(handles.image(:)), max(handles.image(:))], ...
    'Parent', handles.Axes);
hold(handles.Axes, 'on');
green = cat(3, zeros(size(handles.gaussImage)), ...
    ones(size(handles.gaussImage)), zeros(size(handles.gaussImage)));
handles.overlay = imshow(green, 'Parent', handles.Axes);
handles.sections = {};
guidata(hObject, handles);
updateOverlay(handles);

% Update brush display
handles.Brush.Value = size(handles.image,2)/50;
Brush_Callback(handles.Brush, eventdata, handles);

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
handles.overlay.AlphaData = 0.5*handles.mask;
stats = regionprops(handles.mask, 'Centroid');

% Delete old sections
for i = 1:length(handles.sections)
    delete(handles.sections{i}.label);
end
handles.sections = cell(1,length(stats));
for i = 1:length(stats)
    handles.sections{i}.label = text(handles.Axes,stats(i).Centroid(1),...
        stats(i).Centroid(2),num2str(i), 'FontSize', 16);
    handles.sections{i}.label.ButtonDownFcn = ...
        @(~,~)set(handles.sections{i}.label,'Editing', 'on');
end

guidata(handles.figure1, handles);

% --- Executes on Slider moving.
function Slider_Moving(figure)
handles = guidata(figure);
thr = handles.Slider.Value;
f = imbinarize(handles.gaussImage, thr);
handles.mask = imfill(f, 'holes');
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
else
    set(handles.figure1, 'WindowButtonDownFcn', '');
    set(handles.figure1,'Pointer','arrow');
end

% --- Executes on button press in Erase.
function Erase_Callback(hObject, eventdata, handles)
% hObject    handle to Erase (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if hObject.Value == 1
    handles.Draw.Value = 0;
    set(handles.figure1,'Pointer','circle');
    set(handles.figure1, 'WindowButtonDownFcn', ...
        @(src, evnt)mousePressed('erase'));
else
    set(handles.figure1, 'WindowButtonDownFcn', '');
    set(handles.figure1,'Pointer','arrow');
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
elseif strcmp(type,'erase')
    handles.mask(target)=0;
end
handles.overlay.AlphaData = 0.5*handles.mask;
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
set(gcbf,'WindowButtonUpFcn',@(~,~)mouseUnpressed);


function mouseUnpressed

% Clean up the evidence ...
handles = guidata(gcbf);
set(handles.figure1,'WindowButtonUpFcn','');
set(handles.figure1,'WindowButtonMotionFcn','');
updateOverlay(handles);


% --- Executes on slider movement.
function Brush_Callback(hObject, eventdata, handles)
% hObject    handle to Brush (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
width = handles.BrushAxes.Position(3);
x = linspace(hObject.Min, hObject.Max, width);
handles.Axes.Units = 'pixel';
axesWidth = handles.Axes.Position(3);
handles.Axes.Units = 'normalized';
density = size(handles.image,2)/axesWidth;

r = handles.Brush.Value/density/1.5;
c = x(floor(end/2));
[X,Y] = meshgrid(x, x);
green = cat(3, zeros(size(X)), ...
    ones(size(X)), zeros(size(X)));
brush = false(size(X));
brush((X - c).^2 + (Y - c).^2 < r^2) = true;
image(handles.BrushAxes, x, x, green, 'AlphaData', brush);
axis(handles.BrushAxes, 'off');
