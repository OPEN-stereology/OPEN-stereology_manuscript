% OPEN-Stereology Core Function – Reviewer Copy
%
% Copyright (c) 2021-2025, OPEN-Stereology
% Licensed under the PolyForm Noncommercial License 1.0.0
% https://polyformproject.org/licenses/noncommercial/1.0.0
%
% Developed by the OPEN-Stereology project team at UC San Diego (UCSD).
% For more information, see: https://github.com/OPEN-Stereology
%
% NO WARRANTY: This code is provided "as is" without warranty of any kind,
% express or implied. The authors and affiliated institutions disclaim all
% liability for any use, misuse, or interpretation of the software.
%
% DO NOT POST OR CIRCULATE WITHOUT PERMISSION.
%
% SYSTEM CONFIGURATION NOTICE:
%
% This version of OPEN-Stereology software includes system-specific
% parameters and hardware control commands that reflect the configuration
% used in the accompanying manuscript.
%
% These parameters include (but are not limited to):
%   - Camera type and resolution
%   - Stage driver command formats and motor interface
%   - Objective magnification calibration values
%   - Image acquisition timing and file naming conventions
%   - Directory paths for the data is being stored
%
% These settings are not guaranteed to be compatible with other systems.
% Users intending to adapt this software for their own stereology setup
% must review and modify all system-dependent variables, driver commands,
% and calibration constants accordingly. Proper adaptation will require
% access to and careful review of the manuscript associated with this
% software.

function varargout = open_stereo(varargin)
% open_stereo MATLAB code for open_stereo.fig
%      open_stereo, by itself, creates a new open_stereo or raises the existing
%      singleton*.
%
%      H = open_stereo returns the handle to a new open_stereo or the handle to
%      the existing singleton*.
%
%      open_stereo('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in open_stereo.M with the given input arguments.
%
%      open_stereo('Property','Value',...) creates a new open_stereo or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before open_stereo_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to open_stereo_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Only prompt for token on initial launch — not on callbacks
isInitialCall = isempty(varargin) || ...
    (numel(varargin) >= 1 && ischar(varargin{1}) && ~ismember(varargin{1}, {'CALLBACK','Property'}));

persistent accessGranted  % Remember token so it doesn't ask again
if isempty(accessGranted) && isInitialCall
    expected = [85 67 83 68 50 48 50 53 33];
    input = inputdlg('Enter reviewer token:');
    if isempty(input) || ~isequal(double(input{1}), expected)
        errordlg('Need Reviewer Token', 'Unauthorized');
        varargout = {};
        return;
    else
        accessGranted = true;
    end
end

%accessGranted = false;

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @open_stereo_OpeningFcn, ...
    'gui_OutputFcn',  @open_stereo_OutputFcn, ...
    'gui_LayoutFcn',  [], ...
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


% --- Executes just before open_stereo is made visible.
function open_stereo_OpeningFcn(hObject, eventdata, handles, varargin)
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to open_stereo (see VARARGIN)

handles.output = hObject;

handles.myData.mrArray(1).http   = 'http://localhost:8081/'; % Toupcam
handles.myData.CANON_CAMERA      = 0;
handles.myData.mrArray(1).mouse  = 'Mouse_0';
handles.myData.mrArray(1).region = 'Region_0';
handles.myData.mrArray(1).section = 'Section_0';
handles.myData.mrArray(1).roi_type = '1';
handles.myData.mrArray(1).index  = 1;
handles.myData.mrArray(1).FS     = 0;
handles.myData.pointList         = [];
handles.myData.roi_type(1).rc    = [1 1 10 10];

axes(handles.axes1);
guidata(hObject, handles);

file_name = [handles.myData.mrArray(1).mouse '_' handles.myData.mrArray(1).region '.mat'];
handles.myData.mrArray(1).file_name = file_name;
handles.myData.mrArray(2:end) = [];

set(handles.myData.Name_Obj, 'string', file_name);

handles.myData.C = YawCameraController;

if handles.myData.CANON_CAMERA
    handles.myData.C.Cmd('All_Minimize');
end

[img, handles] = capture_img(handles);

h = imshow(img); axis equal; shg;
hh = title(['STATIC CAM VIEW -- DIMS = [ ' num2str(size(img)) ']' 10 ...
    '      Image = ' handles.myData.img_list(end).file]);
set(hh, 'Interpreter', 'none');
set(0, 'defaulttextinterpreter', 'none');

% Load Calibration L
file_path = 'Calib_L.mat';
file_info = dir(file_path);
if ~isempty(file_info)
    last_modification_date = file_info.datenum;
    fprintf('Last modification date of %s: %s\n', file_path, datestr(last_modification_date));
else
    error('File not found: %s\n', file_path);
end
load(file_path);
handles.myData.Calib = Calib_L;
disp('Loaded Calibration L from file');

% Load Calibration 
load Calib_K_tmp.mat;  % LAST ONE
handles.myData.Calib_K = Calib_K;
handles.myData.pointList(1).K         = Calib_K(3).K;
handles.myData.pointList(1).Objective = '10x';
handles.myData.Calib_K10              = Calib_K(3).K;

% Load the latest Calib_K (2023 temporary measure)
load Calib_K_tmp.mat
for i = 1:length(Calib_K)
    handles.myData.Calib_K(i).K = Calib_K(i).K;
end
handles.myData.Calib_K10 = Calib_K(3).K;

SendCommand(0, 'UPR,Z,100')
SendCommand(0, 'RES,Z,0.1')

msg    = SendCommand(0, 'PZ');
z_steps = str2num(msg);

msg1    = SendCommand(0, 'RES,Z');
u_per_s = sscanf(msg1, '%f/r')';

z_micron = z_steps * u_per_s;
handles.myData.z_u_per_s = u_per_s;

guidata(hObject, handles);


% --- Outputs from this function are returned to the command line.
function varargout = open_stereo_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

varargout{1} = handles.output;


% --- Executes on button press in pushbutton6.
function pushbutton6_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

file_name = [handles.myData.mrArray(1).mouse '_' handles.myData.mrArray(1).region '.mat'];

if length(handles.myData.mrArray) > 1
    dans = questdlg(['Save Current File: ' file_name], ...
        'SAVE MENU', 'YES', 'NO', 'NO');
    if strcmp(dans, 'YES')
        saveState(hObject, handles);
    end
end

handles.myData.open = 1;
close('open_stereo');
run('open_stereo');


% --- Executes on button press in pushbutton8.
function pushbutton8_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton8 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

try
    if isfield(handles.myData, 'img_list')
        img = imread(handles.myData.img_list(end).file);
    else
        [img, handles] = capture_img(hObject, handles);
    end
catch
    keyboard
end

big_img = handles.myData.img_list(end).file;
img = imread(big_img);

h = imshow(img); axis equal; shg;

ROI_number = str2double(get(handles.myData.mrArray(1).index_obj, 'String'));
ROI_num    = ROI_number;

handles.myData.mrArray(ROI_num).big_img  = big_img;
handles.myData.mrArray(ROI_num).mouse    = get(handles.myData.mrArray(1).mouse_obj,   'String');
handles.myData.mrArray(ROI_num).region   = get(handles.myData.mrArray(1).region_obj,  'String');
handles.myData.mrArray(ROI_num).section  = get(handles.myData.mrArray(1).section_obj, 'String');
handles.myData.mrArray(ROI_num).roi_type = get(handles.myData.mrArray(1).roitype_obj, 'String');

if iscell(handles.myData.mrArray(ROI_num).roi_type)
    handles.myData.mrArray(ROI_num).roi_type = handles.myData.mrArray(ROI_num).roi_type{1};
end

handles.myData.mrArray(1).index = ROI_number;

point1 = get(gcf, 'CurrentPoint');
h = imrect(gca, [point1 handles.myData.roi_type(str2num(handles.myData.mrArray(ROI_number).roi_type)).rc]);
rct = wait(h);

handles.myData.mrArray(ROI_number).roi_img = imcrop(img, rct);
delete(h);

rct = [rct(1:2) handles.myData.roi_type(str2num(handles.myData.mrArray(ROI_number).roi_type)).rc];
handles.myData.mrArray(ROI_number).roi_rct = rct;

guidata(hObject, handles);
rectangle('Position', rct);
drawnow;

rec_obj = handles.myData.mrArray(1).record_obj;
rec_txt = [['Mouse Rec. Length  :  ' num2str(length(handles.myData.mrArray))] char(10) ...
    ['====================='] char(10) ...
    ['Last Rec Update  :  ' num2str(ROI_number)] char(10) ...
    ['Mouse  :  ' char(handles.myData.mrArray(ROI_number).mouse)] char(10) ...
    ['Region  :  ' char(handles.myData.mrArray(ROI_number).region)] char(10) ...
    ['Section  :  ' char(handles.myData.mrArray(ROI_number).section)] char(10) ...
    ['ROI Type  :  ' char(handles.myData.mrArray(ROI_number).roi_type)] char(10) ...
    ['====================='] char(10) ...
    ['Number of ROI s  :  ' num2str(length(handles.myData.roi_type)-1)]];
set(rec_obj, 'String', rec_txt);

ROI_num = 1 + length(handles.myData.mrArray);
handles.myData.mrArray(ROI_num) = handles.myData.mrArray(ROI_number);
set(handles.myData.mrArray(1).index_obj, 'String', num2str(ROI_num));

hObject9 = handles.myData.mrArray(1).index_obj;
ROI_num  = str2double(get(hObject9, 'String'));

if (length(handles.myData.mrArray) < ROI_num) || isempty(handles.myData.mrArray(ROI_num).mouse)
    handles.myData.mrArray(ROI_num).mouse = get(handles.myData.mrArray(1).mouse_obj, 'String');
end
if isempty(handles.myData.mrArray(ROI_num).region)
    handles.myData.mrArray(ROI_num).region = get(handles.myData.mrArray(1).region_obj, 'String');
end
if isempty(handles.myData.mrArray(ROI_num).section)
    handles.myData.mrArray(ROI_num).section = get(handles.myData.mrArray(1).section_obj, 'String');
end
if isempty(handles.myData.mrArray(ROI_num).roi_type)
    handles.myData.mrArray(ROI_num).roi_type = get(handles.myData.mrArray(1).roitype_obj, 'String');
end

guidata(hObject, handles);


function edit1_Callback(hObject, eventdata, handles)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

ROI_number = str2double(get(handles.myData.mrArray(1).index_obj, 'String'));
handles.myData.mrArray(1).index = ROI_number;
handles.myData.mrArray(ROI_number).mouse = get(hObject, 'String');

file_name = [handles.myData.mrArray(ROI_number).mouse '_' handles.myData.mrArray(ROI_number).region '.mat'];
handles.myData.mrArray(1).file_name = file_name;
set(handles.myData.Name_Obj, 'string', handles.myData.mrArray(1).file_name);

guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function edit1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

handles.myData.mrArray(1).mouse_obj = hObject;
guidata(hObject, handles);
if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end


function edit5_Callback(hObject, eventdata, handles)
% hObject    handle to edit5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

ROI_number = str2double(get(handles.myData.mrArray(1).index_obj, 'String'));
handles.myData.mrArray(1).index = ROI_number;
handles.myData.mrArray(ROI_number).region = get(hObject, 'String');

file_name = [handles.myData.mrArray(ROI_number).mouse '_' handles.myData.mrArray(ROI_number).region '.mat'];
handles.myData.mrArray(1).file_name = file_name;
set(handles.myData.Name_Obj, 'string', handles.myData.mrArray(1).file_name);
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function edit5_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

handles.myData.mrArray(1).region_obj = hObject;
guidata(hObject, handles);
if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end


function edit6_Callback(hObject, eventdata, handles)
% hObject    handle to edit6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes during object creation, after setting all properties.
function edit6_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

handles.myData.mrArray(1).section_obj = hObject;
guidata(hObject, handles);
if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end


function edit7_Callback(hObject, eventdata, handles)
% hObject    handle to edit7 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

roi_type = get(hObject, 'String');
handles.myData.mrArray(1).roi_type = roi_type;
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function edit7_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit7 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

handles.myData.mrArray(1).roitype_obj = hObject;
guidata(hObject, handles);
if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end


% --- Executes on button press in pushbutton9.
function pushbutton9_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton9 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

hold on;
h  = imrect();
rc = wait(h);
hold on;
hh = rectangle('Position', rc, 'EdgeColor', 'g');
delete(h);

h2 = text(rc(1), rc(2) - abs(diff(ylim))/40, num2str(length(handles.myData.roi_type)), 'Color', 'g');
handles.myData.roi_type(end).rc = [rc(3) rc(4)];

% Save it
handles.myData.roi_type(end+1).rc    = [0 0];
handles.myData.roi_list{end+1}       = num2str(length(handles.myData.roi_list));
set(handles.myData.roi_list_obj, 'string', handles.myData.roi_list);
guidata(hObject, handles);


% --- Executes on selection change in listbox2.
function listbox2_Callback(hObject, eventdata, handles)
% hObject    handle to listbox2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

v_list   = get(hObject, 'String');
roi_type = v_list{get(hObject, 'Value')};

set(handles.myData.mrArray(1).roitype_obj, 'string', roi_type);
handles.myData.mrArray(1).roi_type = roi_type;

ROI_number = str2double(get(handles.myData.mrArray(1).index_obj, 'String'));

rct = [mean(xlim) mean(ylim) handles.myData.roi_type(str2num(roi_type)).rc];
title(['Click to accept and select ROI type : ' roi_type])
h = imrect(gca, rct); shg;
pause(0.5)
delete(h);
title(['Live View'])
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function listbox2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to listbox2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

handles.myData.roi_list     = {''};
handles.myData.roi_list_obj = hObject;
set(hObject, 'string', handles.myData.roi_list);
if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end
guidata(hObject, handles);


% --- Executes on button press in pushbutton10.
function pushbutton10_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton10 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

saveState(hObject, handles);
guidata(hObject, handles);


% --- Executes on button press in pushbutton11.
function pushbutton11_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton11 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles    = loadState(hObject, handles);
ROI_number = length(handles.myData.mrArray);

rec_txt = [['Mouse Rec. Length  :  ' num2str(length(handles.myData.mrArray))] char(10) ...
    ['====================='] char(10) ...
    ['Last Rec Update  :  ' num2str(ROI_number)] char(10) ...
    ['Mouse  :  ' char(handles.myData.mrArray(ROI_number).mouse)] char(10) ...
    ['Region  :  ' char(handles.myData.mrArray(ROI_number).region)] char(10) ...
    ['Section  :  ' char(handles.myData.mrArray(ROI_number).section)] char(10) ...
    ['ROI Type  :  ' char(handles.myData.mrArray(ROI_number).roi_type)] char(10) ...
    ['Point List : ' char(num2str(length(handles.myData.pointList)))] char(10) ...
    ['====================='] char(10) ...
    ['Number of ROI s  :  ' num2str(length(handles.myData.roi_type)-1)]];

rec_obj = handles.myData.mrArray(1).record_obj;
set(rec_obj, 'String', rec_txt);
set(handles.myData.roi_list_obj, 'string', handles.myData.roi_list);

guidata(hObject, handles);


function edit9_Callback(hObject, eventdata, handles)
% hObject    handle to edit9 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.myData.mrArray(1).index_obj = hObject;
ROI_num = str2double(get(hObject, 'String'));

if (length(handles.myData.mrArray) < ROI_num) || isempty(handles.myData.mrArray(ROI_num).mouse)
    handles.myData.mrArray(ROI_num).mouse = get(handles.myData.mrArray(1).mouse_obj, 'String');
end
if isempty(handles.myData.mrArray(ROI_num).region)
    handles.myData.mrArray(ROI_num).region = get(handles.myData.mrArray(1).region_obj, 'String');
end
if isempty(handles.myData.mrArray(ROI_num).section)
    handles.myData.mrArray(ROI_num).section = get(handles.myData.mrArray(1).section_obj, 'String');
end
if isempty(handles.myData.mrArray(ROI_num).roi_type)
    handles.myData.mrArray(ROI_num).roi_type = get(handles.myData.mrArray(1).roitype_obj, 'String');
end

guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function edit9_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit9 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

handles.myData.mrArray(1).index_obj = hObject;
if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function text13_CreateFcn(hObject, eventdata, handles)
% hObject    handle to text13 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

handles.myData.mrArray(1).record_obj = hObject;
guidata(hObject, handles);


% --- Executes on button press in pushbutton12.
function pushbutton12_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton12 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.myData.roi_type(end+1).rc = [0 0];
handles.myData.roi_list{end+1}    = num2str(length(handles.myData.roi_list));
set(handles.myData.roi_list_obj, 'string', handles.myData.roi_list);
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function pushbutton12_CreateFcn(hObject, eventdata, handles)
% hObject    handle to pushbutton12 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes during object creation, after setting all properties.
function pushbutton9_CreateFcn(hObject, eventdata, handles)
% hObject    handle to pushbutton9 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes during object creation, after setting all properties.
function pushbutton11_CreateFcn(hObject, eventdata, handles)
% hObject    handle to pushbutton11 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes during object creation, after setting all properties.
function axes1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to axes1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
% Hint: place code in OpeningFcn to populate axes1


function handles = loadState(hObject, handles)
[file, path] = uigetfile('*.mat');
load(fullfile(path, file));

for i = 1:length(mrArray)
    try
        handles.myData.mrArray(i).mouse    = mrArray(i).mouse;    set(handles.myData.mrArray(1).mouse_obj,   'String', mrArray(i).mouse);
        handles.myData.mrArray(i).region   = mrArray(i).region;   set(handles.myData.mrArray(1).region_obj,  'String', mrArray(i).region);
        handles.myData.mrArray(i).section  = mrArray(i).section;  set(handles.myData.mrArray(1).section_obj, 'String', mrArray(i).section);
        handles.myData.mrArray(i).roi_type = mrArray(i).roi_type; set(handles.myData.mrArray(1).roitype_obj, 'String', mrArray(i).roi_type);
        handles.myData.mrArray(i).index    = mrArray(i).index;    set(handles.myData.mrArray(1).index_obj,   'String', mrArray(i).index);
        handles.myData.mrArray(i).roi_img  = mrArray(i).roi_img;
        handles.myData.mrArray(i).roi_rct  = mrArray(i).roi_rct;
        handles.myData.mrArray(i).big_img  = mrArray(i).big_img;
    end
end

handles.myData.mrArray(1).file_name = mrArray(1).file_name;
set(handles.myData.Name_Obj, 'String', mrArray(1).file_name);

for i = 1:length(roi_type)
    try
        handles.myData.roi_type(i).rc = roi_type(i).rc;
    end
end

handles.myData.roi_list  = roi_list;
handles.myData.img_list  = img_list;
handles.myData.pointList = pointList;


function saveState(hObject, handles)
mrArray(1).file_name = handles.myData.mrArray(1).file_name;

for i = 1:length(handles.myData.mrArray)
    try
        mrArray(i).mouse     = handles.myData.mrArray(i).mouse;
        mrArray(i).region    = handles.myData.mrArray(i).region;
        mrArray(i).section   = handles.myData.mrArray(i).section;
        mrArray(i).roi_type  = handles.myData.mrArray(i).roi_type;
        mrArray(i).index     = handles.myData.mrArray(i).index;
        mrArray(i).roi_img   = handles.myData.mrArray(i).roi_img;
        mrArray(i).roi_rct   = handles.myData.mrArray(i).roi_rct;
        mrArray(1).file_name = handles.myData.mrArray(1).file_name;
        mrArray(i).big_img   = handles.myData.mrArray(i).big_img;
    end
end

for i = 1:length(handles.myData.roi_type)
    try
        roi_type(i).rc = handles.myData.roi_type(i).rc;
    end
end

img_list  = handles.myData.img_list;
roi_list  = handles.myData.roi_list;
pointList = handles.myData.pointList;

eval([' save ' handles.myData.mrArray(1).file_name '  mrArray roi_type roi_list img_list pointList']);
disp([' saving ' handles.myData.mrArray(1).file_name '  mrArray roi_type roi_list img_list pointList']);


% --- Executes on button press in pushbutton13.
function pushbutton13_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton13 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

ROI_number = str2num(get(handles.myData.roi_num_obj, 'String'));

if (ROI_number > 0) && (ROI_number <= length(handles.myData.mrArray))
    roi_type = handles.myData.mrArray(ROI_number).roi_type;
    rct      = handles.myData.mrArray(ROI_number).roi_rct;

    big_img = handles.myData.mrArray(ROI_number).big_img;
    if isempty(big_img)
        keyboard
        big_img = handles.myData.img_list(end).file;
    end

    img = imread(big_img);

    mm = size(handles.myData.mrArray(ROI_number).roi_img);
    m  = mm(1);
    n  = mm(2);

    img(:,:,2) = img(:,:,2);
    img(:,:,1) = img(:,:,2);
    img(:,:,3) = img(:,:,2);
    img(round(rct(2)+(1:m)), round(rct(1)+(1:n)), 1) = handles.myData.mrArray(ROI_number).roi_img(:,:,1);
    img(round(rct(2)+(1:m)), round(rct(1)+(1:n)), 2) = handles.myData.mrArray(ROI_number).roi_img(:,:,2);
    img(round(rct(2)+(1:m)), round(rct(1)+(1:n)), 3) = handles.myData.mrArray(ROI_number).roi_img(:,:,3);

    hold off;
    h = imshow(img); axis equal; shg;
    hold on

    rectangle('Position', rct, 'EdgeColor', 'b');
    text(rct(1)+rct(3)/2, rct(2)+rct(4)/2, num2str(ROI_number), 'Color', 'b');
    axis equal
end

hh = title([big_img 10 '****  RIGHT CLICK TO CONTINUE ****']);
set(hh, 'Interpreter', 'none');

kk = waitforbuttonpress();

img = imread(handles.myData.img_list(end).file);
hh  = title(['Current Frame : ' big_img]);
h   = imshow(img); axis equal; shg;
guidata(hObject, handles);

rec_obj = handles.myData.mrArray(1).record_obj;
rec_txt = [['Mouse Rec. Length  :  ' num2str(length(handles.myData.mrArray))] char(10) ...
    ['====================='] char(10) ...
    ['Last Rec Update  :  ' num2str(ROI_number)] char(10) ...
    ['Mouse  :  ' char(handles.myData.mrArray(ROI_number).mouse)] char(10) ...
    ['Region  :  ' char(handles.myData.mrArray(ROI_number).region)] char(10) ...
    ['Section  :  ' char(handles.myData.mrArray(ROI_number).section)] char(10) ...
    ['ROI Type  :  ' char(handles.myData.mrArray(ROI_number).roi_type)] char(10) ...
    ['====================='] char(10) ...
    ['Number of ROI s  :  ' num2str(length(handles.myData.roi_type)-1)]];
set(rec_obj, 'String', rec_txt);


function edit10_Callback(hObject, eventdata, handles)
% hObject    handle to edit10 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes during object creation, after setting all properties.
function edit10_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit10 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

handles.myData.roi_num_obj = hObject;
if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end
guidata(hObject, handles);


% --- Executes on button press in pushbutton14.
function pushbutton14_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton14 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

while 1
    img = handles.myData.C.LiveView;
    imshow(img); axis equal;
    shg;
end


function [img, file] = grabImage(hObject, handles)
handles.myData.C.Capture;
file = handles.myData.C.lastfile;
img  = imread([handles.myData.mrArray(1).http file]);


% --- Executes on button press in pushbutton15.
function pushbutton15_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton15 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

[img, handles] = capture_img(handles);
guidata(hObject, handles);


function [img, handles] = capture_img(handles)
hold off;

file = 'out.jpg';

try
    img = imread([handles.myData.mrArray(1).http file]);
catch
    img = imread([handles.myData.mrArray(1).http file]);
end

img_dir = get(handles.myData.Name_Obj, 'String');
[filepath, fname, ext] = fileparts(img_dir);
img_dir = fname;
mkdir(['C:\' img_dir]);

if ~isfield(handles.myData, 'img_list')
    handles.myData.img_list = [];
end

handles.myData.img_list(end+1).file = ['c:/' img_dir '/' num2str(length(handles.myData.img_list)+1) '.jpg'];

k = 1;
while exist(handles.myData.img_list(end).file)
    bas = ['c:/' img_dir '/' num2str(length(handles.myData.img_list)+1) '.jpg'];
    handles.myData.img_list(end).file = [bas(1:(end-4)) '_' num2str(k) '.jpg'];
    k = k + 1;
end

imwrite(img, handles.myData.img_list(end).file);
imshow(img); axis equal; shg;
hh = title(['CAPTURED IMAGE # ' num2str(length(handles.myData.img_list)) ' --  DIMS = [ ' num2str(size(img)) ' ]' 10 handles.myData.img_list(end).file]);
set(hh, 'Interpreter', 'none');


% --- Executes on button press in radiobutton1.
function radiobutton1_Callback(hObject, eventdata, handles)
% hObject    handle to radiobutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

frame = 1;
hold off;
img = imread([handles.myData.mrArray(1).http 'out.jpg']);
imshow(img); axis equal; shg;

while get(handles.myData.Stream_Obj, 'Value') == 1
    img = imread([handles.myData.mrArray(1).http 'out.jpg']);
    imshow(img); axis equal; shg;
    if isfield(handles.myData, 'zoomFactor')
        zoom(handles.zoomFactor);
    end
    frame = frame + 1;
    title(['LIVE STREAMING FRAME ' num2str(frame) '  --  DIMS = [ ' num2str(size(img)) ']']);
    pause(0.1);
end

img = imread(handles.myData.img_list(end).file);
hold off;
imshow(img); axis equal; shg;
hh = title(['STATIC CAM VIEW -- DIMS = [ ' num2str(size(img)) ']' 10 'Image = ' handles.myData.img_list(end).file]);
set(hh, 'Interpreter', 'none');


% --- Executes during object creation, after setting all properties.
function radiobutton1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to radiobutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

handles.myData.Stream_Obj = hObject;
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function text17_CreateFcn(hObject, eventdata, handles)
% hObject    handle to text17 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

handles.myData.Name_Obj = hObject;
guidata(hObject, handles);


% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over text17.
function text17_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to text17 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pushbutton16.
function pushbutton16_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton16 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

fn1    = handles.myData.mrArray(1).file_name;
mouse1 = fn1(1:(end-4));

mrArray1 = handles.myData.mrArray;
[fn2, path] = uigetfile('*.mat');
mouse2 = fn2(1:(end-4));

compareMouse1_2(mouse1, mouse2);


% --- Executes on button press in pushbutton17.
function pushbutton17_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton17 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.myData.mrArray(1).FS = mod(handles.myData.mrArray(1).FS + 1, 2);
get(gcf, 'Position')
if handles.myData.mrArray(1).FS == 1
    set(gcf, 'units', 'normalized', 'outerposition', [0 0 1 1]);
else
    set(gcf, 'units', 'normalized', 'outerposition', [0.0022 0.0039 0.9956 0.9661]);
end
guidata(hObject, handles);


% --- Executes on button press in pushbutton18.
function pushbutton18_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton18 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes when figure1 is resized.
function figure1_ResizeFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pushbutton19.
function pushbutton19_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton19 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

msg    = SendCommand(0, 'PZ');
z_steps = str2num(msg);

msg1    = SendCommand(0, 'RES,Z');
u_per_s = sscanf(msg1, '%f/r')';

z_micron = z_steps * u_per_s;
handles.myData.z_u_per_s = u_per_s;

set(handles.myData.zTopObjectMicron, 'String', [num2str(round(z_micron)) ' um']);
set(handles.myData.zTopObject,       'String', msg);
set(handles.myData.currentZObject,   'String', msg);
handles.myData.zTopIndex = str2num(msg);

N_stacks = str2num(get(handles.myData.N_zstacksObject, 'String'));
dz       = str2num(get(handles.myData.zTopObject,    'String')) - ...
           str2num(get(handles.myData.zBottomObject,  'String'));

handles.myData.stacks_dz = dz / N_stacks;
set(handles.myData.dz_zstacksObject, 'String', num2str(handles.myData.stacks_dz));

if (dz > 0) && (dz < 20000)
    set(handles.myData.stacks_GO_Object, 'BackgroundColor', [0 1 0.5]);
else
    set(handles.myData.stacks_GO_Object, 'BackgroundColor', [1 0 0]);
end

set(handles.myData.dzRelMicronObject, 'String', num2str(dz * u_per_s));

guidata(hObject, handles);


function edit13_Callback(hObject, eventdata, handles)
% hObject    handle to edit13 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes during object creation, after setting all properties.
function edit13_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit13 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end

handles.myData.zTopObjectMicron = hObject;

msg    = SendCommand(0, 'PZ');
z_steps = str2num(msg);

msg1    = SendCommand(0, 'RES,Z');
u_per_s = sscanf(msg1, '%f/r')';

z_micron = z_steps * u_per_s;
set(handles.myData.zTopObjectMicron, 'String', [num2str(round(z_micron)) ' um']);

guidata(hObject, handles);


function edit14_Callback(hObject, eventdata, handles)
% hObject    handle to edit14 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes during object creation, after setting all properties.
function edit14_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit14 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end

handles.myData.zTopObject = hObject;
msg = SendCommand(0, 'PZ');
set(handles.myData.zTopObject, 'String', msg);

guidata(hObject, handles);


% --- Executes on button press in pushbutton20.
function pushbutton20_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton20 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

msg    = SendCommand(0, 'PZ');
z_steps = str2num(msg);

msg1    = SendCommand(0, 'RES,Z');
msg2    = SendCommand(0, 'UPR,Z');
u_per_s = sscanf(msg1, '%f/r')';

z_micron = z_steps * u_per_s;

set(handles.myData.zBottomObject,       'String', msg);
set(handles.myData.zBottomObjectMicron, 'String', [num2str(round(z_micron)) ' um']);
set(handles.myData.currentZObject,      'String', msg);
handles.myData.zBottomIndex = str2num(msg);

N_stacks = str2num(get(handles.myData.N_zstacksObject, 'String'));
dz       = str2num(get(handles.myData.zTopObject,    'String')) - ...
           str2num(get(handles.myData.zBottomObject,  'String'));

handles.myData.stacks_dz = dz / N_stacks;
set(handles.myData.dz_zstacksObject, 'String', num2str(handles.myData.stacks_dz));

if (dz > 0) && (dz < 20000)
    set(handles.myData.stacks_GO_Object, 'BackgroundColor', [0 1 0.5]);
else
    set(handles.myData.stacks_GO_Object, 'BackgroundColor', [1 0 0]);
end

set(handles.myData.dzRelMicronObject, 'String', num2str(dz * u_per_s));

guidata(hObject, handles);


function edit15_Callback(hObject, eventdata, handles)
% hObject    handle to edit15 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes during object creation, after setting all properties.
function edit15_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit15 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end

handles.myData.zBottomObject = hObject;
msg = SendCommand(0, 'PZ');
set(handles.myData.zBottomObject, 'String', msg);

guidata(hObject, handles);


function edit16_Callback(hObject, eventdata, handles)
% hObject    handle to edit16 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes during object creation, after setting all properties.
function edit16_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit16 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end

handles.myData.zBottomObjectMicron = hObject;

msg    = SendCommand(0, 'PZ');
z_steps = str2num(msg);

msg1    = SendCommand(0, 'RES,Z');
u_per_s = sscanf(msg1, '%f/r')';

z_micron = z_steps * u_per_s;
set(handles.myData.zBottomObjectMicron, 'String', [num2str(round(z_micron)) ' um']);

guidata(hObject, handles);


% --- Executes on slider movement.
function slider1_Callback(hObject, eventdata, handles)
% hObject    handle to slider1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

z_bottom = str2num(get(handles.myData.zBottomObject, 'String'));
z_top    = str2num(get(handles.myData.zTopObject,    'String'));
z_rel    = z_top - z_bottom;
z_target = round(z_top - (1 - get(handles.myData.dzSliderObject, 'Value')) * z_rel);

msg     = SendCommand(0, 'PZ');
z_steps = str2num(msg);
msg1    = SendCommand(0, 'RES,Z');
u_per_s = sscanf(msg1, '%f/r');

set(handles.myData.currentZObject,   'String', num2str(z_target * u_per_s));
set(handles.myData.dzRelMicronObject, 'String', [num2str((z_top - z_target) * u_per_s) 'um']);

msg     = sendCommand(0, ['GZ,' num2str(z_target)]);
msg     = SendCommand(0, 'PZ');
z_steps = str2num(msg);
set(handles.myData.dzRelMicronObject, 'String', [num2str((z_top - z_steps) * u_per_s) 'um']);

guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function slider1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

if isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', [.5 .5 .9*0]);
end

handles.myData.dzSliderObject = hObject;
set(handles.myData.dzSliderObject, 'Min',   0);
set(handles.myData.dzSliderObject, 'Max',   1);
set(handles.myData.dzSliderObject, 'Value', 0.5);
numSteps = 100;
set(handles.myData.dzSliderObject, 'SliderStep', [1/(numSteps-1) 1/(numSteps-1)]);

guidata(hObject, handles);


function dc = dom_color(img)
% detectDominantHue  Determines if the image leans toward Red, Green, or Blue.
%
%   dc = dom_color(img)
%
%   Inputs:
%       img - n x m x 3 RGB image (uint8 or double)
%
%   Outputs:
%       dc - 1x3 RGB vector indicating the dominant hue

% Convert image to double if necessary
if ~isa(img, 'double')
    img_double = double(img);
else
    img_double = img;
end

threshold_non_white = 220;
threshold_color     = 150;
threshold_other     = 100;

mask_non_white = (img_double(:,:,1) < threshold_non_white) | ...
                 (img_double(:,:,2) < threshold_non_white) | ...
                 (img_double(:,:,3) < threshold_non_white);

mask_red   = (img_double(:,:,1) > threshold_color) & ...
             (img_double(:,:,2) < threshold_other) & ...
             (img_double(:,:,3) < threshold_other) & mask_non_white;

mask_green = (img_double(:,:,2) > threshold_color) & ...
             (img_double(:,:,1) < threshold_other) & ...
             (img_double(:,:,3) < threshold_other) & mask_non_white;

mask_blue  = (img_double(:,:,3) > threshold_color) & ...
             (img_double(:,:,1) < threshold_other) & ...
             (img_double(:,:,2) < threshold_other) & mask_non_white;

count_red   = sum(mask_red(:));
count_green = sum(mask_green(:));
count_blue  = sum(mask_blue(:));

total_non_white = sum(mask_non_white(:));

if total_non_white == 0
    dominant_hue = 'Neutral';
    return;
end

prop_red   = count_red   / total_non_white;
prop_green = count_green / total_non_white;
prop_blue  = count_blue  / total_non_white;

[max_prop, dominant_index] = max([prop_red, prop_green, prop_blue]);

min_proportion = 0.05;

if max_prop < min_proportion
    dominant_hue = 'Neutral';
else
    switch dominant_index
        case 1; dc = [1 0 0];
        case 2; dc = [0 1 0];
        case 3; dc = [0 0 1];
    end
end


% --- Executes on button press in pushbutton21.
function pushbutton21_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton21 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

clr = get(hObject, 'BackgroundColor');
set(handles.myData.Stream_Obj, 'Value', 0)

img = imread([handles.myData.mrArray(1).http 'out.jpg']);
imshow(img); axis equal; shg;
title(['Z-STACK ATTEMPT  --  DIMS = [ ' num2str(size(img)) ']']);
pause(0.1);

msg1    = SendCommand(0, 'RES,Z');
u_per_s = sscanf(msg1, '%f/r');

if clr(1) == 0
    set(hObject, 'BackgroundColor', [0 0.5 1]);

    ztop    = get(handles.myData.zTopObject,    'String');
    zBottom = get(handles.myData.zBottomObject, 'String');

    msg = sendCommand(0, ['GZ,' ztop]);
    pos = getPos(0, 'Z');
    msg = num2str(pos);
    set(handles.myData.currentZObject, 'String', msg);

    N_stacks = str2num(get(handles.myData.N_zstacksObject, 'String'));

    [pth, fn] = fileparts(handles.myData.mrArray(1).file_name);

    pth      = 'c:\test_img';
    dir_list = dir(fullfile(pth, [fn '_stack_dir_*']));
    stack_dir_number = length(dir_list) + 1;

    % Note: automatic folder numbering is disabled for stereology
    fn = fullfile(pth, [fn '_stack_dir_']);
    mkdir(fn);

    for i = 1:(N_stacks+1)
        z_next = num2str(round(str2num(ztop) - (i-1) * str2num(get(handles.myData.dz_zstacksObject, 'String'))));

        if (str2num(z_next) <= str2num(ztop)) && (str2num(z_next) >= str2num(zBottom))

            z_bottom = str2num(get(handles.myData.zBottomObject, 'String'));
            z_top    = str2num(get(handles.myData.zTopObject,    'String'));
            z_rel    = z_top - z_bottom;
            z_target = str2num(z_next);

            set(handles.myData.currentZObject,    'String', num2str(z_target * u_per_s));
            set(handles.myData.dzRelMicronObject,  'String', [num2str((z_top - z_target) * u_per_s) 'um']);
            set(handles.myData.dzSliderObject,    'Value',  1 - (z_top - z_target) / z_rel);

            msg = sendCommand(0, ['GZ,' z_next]);
            pos = getPos(0, 'Z');
            msg = num2str(pos);
            set(handles.myData.currentZObject, 'String', msg);

            zrel = (str2num(ztop) - pos) * u_per_s;
            set(handles.myData.dzRelMicronObject, 'String', [num2str(zrel) ' um']);
            set(handles.myData.currentZObject,    'String', msg);
        end

        img = imread([handles.myData.mrArray(1).http 'out.jpg']);
        imshow(img); axis equal; shg;

        bl = img(:,:,3); bl = sum(double(bl(:))/255 > 0.1);
        gr = img(:,:,2); gr = sum(double(gr(:))/255 > 0.1);
        rd = img(:,:,1); rd = sum(double(rd(:))/255 > 0.1);

        if     (rd > 2*bl) && (rd > 2*gr); cr = [1 0 0]; crs = 'RED';
        elseif (gr > 2*rd) && (gr > 2*bl); cr = [0 1 0]; crs = 'GREEN';
        elseif (bl > 1.3*rd) && (bl > 1.3*gr); cr = [0 0 1]; crs = 'BLUE';
        else;                                   cr = [1 1 0]; crs = 'RGB';
        end

        set(handles.myData.stacks_GO_Object, 'BackgroundColor', (i-1)/N_stacks * cr);

        % Draw current disector
        try
            um_per_pix_40x = 3.71 / 40 * (40 / handles.myData.cmag); % length of 1 pixel (micron) at 40x
        catch
            errordlg('OBJECTIVE Unknown - SELECT CURRENT OBJ - No Disector')
        end

        wdwSize = str2num(get(handles.myData.stereo_wdwSize_obj, 'string'));
        xc      = [1024; 822];
        ddx     = round(wdwSize / (2 * um_per_pix_40x));
        ddy     = ddx;
        xg      = xc*ones(1,3) + [-ddx -ddx  ddx; -ddy  ddy  ddy];
        xr      = xc*ones(1,3) + [ ddx  ddx -ddx;  ddy -ddy -ddy];
        plot(xr(1,:), xr(2,:), 'r');
        plot(xg(1,:), xg(2,:), 'g');

        % Embed red lines into img
        red = [255, 0, 0];
        for ii = 1:size(xr, 2)-1
            x0 = xr(1, ii);  y0 = xr(2, ii);
            x1 = xr(1, ii+1); y1 = xr(2, ii+1);
            numPoints = max(abs(x1-x0), abs(y1-y0)) + 1;
            x = round(linspace(x0, x1, numPoints));
            y = round(linspace(y0, y1, numPoints));
            validIdx  = x >= 1 & x <= size(img,2) & y >= 1 & y <= size(img,1);
            x = x(validIdx); y = y(validIdx);
            linearIdx = sub2ind(size(img(:,:,1)), y, x);
            img(linearIdx + numel(img(:,:,1)) * 0) = red(1);
            img(linearIdx + numel(img(:,:,1)) * 1) = red(2);
            img(linearIdx + numel(img(:,:,1)) * 2) = red(3);
        end

        % Embed green lines into img
        red = [0, 255, 0];
        for ii = 1:size(xg, 2)-1
            x0 = xg(1, ii);  y0 = xg(2, ii);
            x1 = xg(1, ii+1); y1 = xg(2, ii+1);
            numPoints = max(abs(x1-x0), abs(y1-y0)) + 1;
            x = round(linspace(x0, x1, numPoints));
            y = round(linspace(y0, y1, numPoints));
            validIdx  = x >= 1 & x <= size(img,2) & y >= 1 & y <= size(img,1);
            x = x(validIdx); y = y(validIdx);
            linearIdx = sub2ind(size(img(:,:,1)), y, x);
            img(linearIdx + numel(img(:,:,1)) * 0) = red(1);
            img(linearIdx + numel(img(:,:,1)) * 1) = red(2);
            img(linearIdx + numel(img(:,:,1)) * 2) = red(3);
        end

        try
            stereo_sec_num = num2str(handles.myData.setereoSectionNumber);
        catch
            stereo_sec_num = 'No_Stereo';
        end

        title(['Z-STACK ' num2str(i) '/' num2str(N_stacks+1) '  z= ' num2str(zrel) '   [' num2str(size(img)) ']    Color = ' crs]);
        drawnow; shg;

        img_name = [crs '_' num2str(round(zrel*100)/100) 'u_' num2str(i) '_' stereo_sec_num '.png'];
        imwrite(img, [fn '\' img_name]);
    end

    set(handles.myData.stacks_GO_Object, 'BackgroundColor', [0 1 0.5]);
end

guidata(hObject, handles);


function edit17_Callback(hObject, eventdata, handles)
% hObject    handle to edit17 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

N_stacks = str2num(get(handles.myData.N_zstacksObject, 'String'));
dz       = str2num(get(handles.myData.zTopObject,    'String')) - ...
           str2num(get(handles.myData.zBottomObject,  'String'));

if (dz > 0) && (dz < 20000)
    handles.myData.stacks_dz = dz / N_stacks;
    set(handles.myData.dz_zstacksObject, 'String', num2str(handles.myData.stacks_dz));
end

guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function edit17_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit17 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end
set(hObject, 'String', '10');
handles.myData.N_zstacksObject = hObject;
guidata(hObject, handles);


function edit18_Callback(hObject, eventdata, handles)
% hObject    handle to edit18 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes during object creation, after setting all properties.
function edit18_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit18 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end
handles.myData.currentZObject = hObject;
set(hObject, 'String', sendCommand(0, 'PZ'));
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function text20_CreateFcn(hObject, eventdata, handles)
% hObject    handle to text20 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes during object deletion, before destroying properties.
function text20_DeleteFcn(hObject, eventdata, handles)
% hObject    handle to text20 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes during object creation, after setting all properties.
function pushbutton19_CreateFcn(hObject, eventdata, handles)
% hObject    handle to pushbutton19 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes during object creation, after setting all properties.
function text21_CreateFcn(hObject, eventdata, handles)
% hObject    handle to text21 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes on button press in pushbutton22.
function pushbutton22_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton22 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

msg = SendCommand(0, 'PZ');
set(handles.myData.currentZObject, 'String', msg);
guidata(hObject, handles);


function edit19_Callback(hObject, eventdata, handles)
% hObject    handle to edit19 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes during object creation, after setting all properties.
function edit19_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit19 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end
set(hObject, 'String', '1');
handles.myData.dz_zstacksObject = hObject;
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function pushbutton21_CreateFcn(hObject, eventdata, handles)
% hObject    handle to pushbutton21 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

handles.myData.stacks_GO_Object = hObject;
set(handles.myData.stacks_GO_Object, 'BackgroundColor', [1 0 0]);
guidata(hObject, handles);


function edit20_Callback(hObject, eventdata, handles)
% hObject    handle to edit20 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes during object creation, after setting all properties.
function edit20_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit20 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end
set(hObject, 'String', '-')
handles.myData.dzRelMicronObject = hObject;
guidata(hObject, handles);


% --- Executes on button press in pushbutton23.
function pushbutton23_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton23 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pushbutton24.
function pushbutton24_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton24 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if isfield(handles.myData, 'combineDir_G')
    pth = handles.myData.combineDir_G;
else
    pth = [];
end

[file, pth, indx] = uigetfile(fullfile(pth, '*.jpg'), 'Select GREEN image');
if isequal(file, 0)
    disp('User selected Cancel');
else
    disp(['GREEN file= ' fullfile(pth, file)]);

    [file1, pth1, indx1] = uigetfile(fullfile(pth, '*.jpg'), 'Select BLUE image');
    if isequal(file1, 0)
        disp('User selected Cancel');
    else
        disp(['BLUE file= ' fullfile(pth1, file1)]);

        img_g = imread(fullfile(pth, file));
        if size(img_g, 3) == 3; img_g = rgb2gray(img_g); end

        img_b = imread(fullfile(pth1, file1));
        if size(img_b, 3) == 3; img_b = rgb2gray(img_b); end

        img_rgb(:,:,2) = imnorm0(double(img_g));
        img_rgb(:,:,3) = imnorm0(double(img_b));
        img_rgb(:,:,1) = img_b * 0;

        cfig = gcf;
        figure(100);
        hold off; imagesc(img_rgb);
        axis image;

        handles.myData.combineDir_G = pth;
        handles.myData.combineDir_B = pth1;
        title(['[' pth ']   G:' file '   B:' file1 '   [' pth1 ']']);
        figure(cfig);
        guidata(hObject, handles);
    end
end


% --- Executes on button press in pushbutton25.
function pushbutton25_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton25 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

msg = sendCommand(0, 'PX');
set(handles.myData.xObjectMicron, 'String', msg);
guidata(hObject, handles);


function edit21_Callback(hObject, eventdata, handles)
% hObject    handle to edit21 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes during object creation, after setting all properties.
function edit21_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit21 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end
handles.myData.xObjectMicron = hObject;
set(hObject, 'String', sendCommand(0, 'PX'));
guidata(hObject, handles);


function edit22_Callback(hObject, eventdata, handles)
% hObject    handle to edit22 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes during object creation, after setting all properties.
function edit22_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit22 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end
handles.myData.yObjectMicron = hObject;
set(hObject, 'String', sendCommand(0, 'PY'));
guidata(hObject, handles);


% --- Executes on button press in pushbutton27.
function pushbutton27_Callback(hObject, eventdata, handles)  % Pick Points
% hObject    handle to pushbutton27 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if 0 % Calibrate-first guard (disabled)
    f = msgbox('             Calibrate First');
    disp(' Calibrate First ');
else
    objlist  = [2, 4, 10, 20, 40, 50, 60, 100];
    obj_list = {'2x','4x','10x','20x','40x','50x','60x','100x'};

    calib_mag = handles.myData.pointList(1).Objective;
    magIndx   = find(strcmp(calib_mag, obj_list));
    handles.myData.cmagIndx = magIndx;
    magIndx     = handles.myData.cmagIndx;
    magIndx_ref = 3;

    file = 'out.jpg';
    try
        img = imread([handles.myData.mrArray(1).http file]);
    catch
        img = imread([handles.myData.mrArray(1).http file]);
    end
    hold off; imagesc(img);
    axis image; hold on;

    [y, x] = ginput(1);

    wdw = img(round(x)+(-55:55), round(y)+(-55:55), :);
    handles.myData.lastWdw = wdw;

    out = instrfind('Type', 'serial');
    if ~isempty(out)
        fclose(out);
        delete(out);
    end

    s1 = serial('COM1', 'BaudRate', 38400, 'DataBits', 8, 'StopBits', 1);
    fopen(s1);
    handles.myData.SerialPort = s1;
    rs232 = handles.myData.SerialPort;
    rs0   = rs232;

    xx = num2str(getPos(rs0, 'X'));
    yy = num2str(getPos(rs0, 'Y'));
    zz = sendCommand(rs0, 'PZ');

    handles.myData.lastPt = [str2num(xx) str2num(yy) str2num(zz)];

    plot(y, x, 'r+');
    text(y, x+10, [xx ',' yy ',' zz '.']);

    if isfield(handles.myData.pointList, 'xyz')
        handles.myData.pointList(end+1).xyz      = handles.myData.lastPt;
        handles.myData.pointList(end).xy_image   = [y, x];
        handles.myData.pointList(end).wdw        = wdw;
        handles.myData.pointList(end).magIdx     = magIndx;
    else
        handles.myData.pointList(1).xyz          = handles.myData.lastPt;
        handles.myData.pointList(1).xy_image     = [y, x];
        handles.myData.pointList(1).wdw          = wdw;
        handles.myData.pointList(1).magIdx       = magIndx;
    end

    xm       = handles.myData.pointList(end).xyz;
    xy_image = handles.myData.pointList(end).xy_image;

    handles.myData.Calib(magIndx_ref, magIndx_ref).L = 1;
    handles.myData.pointList(end).xyzg = global_xy(xm, xy_image, handles, magIndx);

    xy_g = handles.myData.pointList(end).xyzg;
    K    = handles.myData.Calib_K(magIndx_ref).K;
    L    = handles.myData.Calib(magIndx_ref, magIndx).L;

    xyz    = round([xy_g; 1] - K*L*[size(img,2)/2; size(img,1)/2; 1]);
    xyz(3) = str2num(zz);
    handles.myData.pointList(end).xyz      = xyz;
    handles.myData.pointList(end).xy_image = [size(img,2)/2; size(img,1)/2];
    handles.myData.pointList(end).wdw      = wdw;

    guidata(hObject, handles);

    pnum = length(handles.myData.pointList);
    xyz  = handles.myData.pointList(pnum).xyz;
    xy   = handles.myData.pointList(pnum).xy_image;

    title(['Stage Moving... ']);
    msg  = sendCommand(rs0, ['GX,' num2str(xyz(1))]);
    posx = getPos(rs0, 'X');
    msg  = sendCommand(rs0, ['GY,' num2str(xyz(2))]);
    posy = getPos(rs0, 'Y');

    xx = num2str(getPos(rs0, 'X'));
    yy = num2str(getPos(rs0, 'Y'));
    title(['Moved to Point # : ' num2str(pnum)]);

    file = 'out.jpg';
    try
        img = imread([handles.myData.mrArray(1).http file]);
    catch
        img = imread([handles.myData.mrArray(1).http file]);
    end

    try
        img = imread([handles.myData.mrArray(1).http file]);
    catch
        img = imread([handles.myData.mrArray(1).http file]);
    end

    hold off; imagesc(img); axis image; hold on;

    z   = xyz(3);
    [xy_g, xyi] = global_xy(xyz(1:2), xy, handles, magIndx);

    if isfield(handles.myData.pointList, 'K')
        K   = handles.myData.Calib_K(magIndx_ref).K;
        L   = handles.myData.Calib(magIndx_ref, magIndx).L;
        xyz = round([xy_g; 1] - K*L*[size(img,2)/2; size(img,1)/2; 1]);
        xy  = [size(img,2)/2; size(img,1)/2];
    end

    if 0  %  This is redundant: fine-adjustment pass disabled for speed
        msg  = sendCommand(rs0, ['GX,' num2str(xyz(1))]);
        msg  = sendCommand(rs0, ['GY,' num2str(xyz(2))]);
        posx = getPos(rs0, 'X');
        posy = getPos(rs0, 'Y');
    end

    try
        img = imread([handles.myData.mrArray(1).http file]);
    catch
        img = imread([handles.myData.mrArray(1).http file]);
    end
    hold off; imagesc(img); axis image; hold on;
    plot(xy(1), xy(2), 'r*');
    plot(xy(1), xy(2), 'rs', 'MarkerSize', 15);
    plot(xy(1), xy(2), 'bs', 'MarkerSize',  9);
    text(xy(1)+100, xy(2), ['[P_' num2str(pnum) ']'], 'Color', 'b');
end

guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function pushbutton27_CreateFcn(hObject, eventdata, handles)
% hObject    handle to pushbutton27 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes on button press in pushbutton28.  Goto Point# (X,Y)
function pushbutton28_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton28 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

pnum = str2num(char(inputdlg({['Point # (of ' num2str(length(handles.myData.pointList)) ' points)']}))); 

xyz      = handles.myData.pointList(pnum).xyz;
xy       = handles.myData.pointList(pnum).xy_image;
magIdx   = handles.myData.pointList(pnum).magIdx;
cmagIdx  = handles.myData.cmagIndx;

file = 'out.jpg';
try
    img = imread([handles.myData.mrArray(1).http file]);
catch
    img = imread([handles.myData.mrArray(1).http file]);
end
hold off; imagesc(img); axis image; hold on;

z = xyz(3);
[xy_g, xyi] = global_xy(xyz(1:2), xy, handles, magIdx);

mag10 = 3;
K10   = handles.myData.Calib_K10;

if isfield(handles.myData.pointList, 'K')
    K   = handles.myData.pointList(pnum).K;
    L   = handles.myData.Calib(mag10, cmagIdx).L;
    xyz = round([xy_g; 1] - (K10*L) * [size(img,2)/2; size(img,1)/2; 1]);
    xy  = [size(img,2)/2; size(img,1)/2];
end

msg  = sendCommand(0, ['GX,' num2str(xyz(1))]);
msg  = sendCommand(0, ['GY,' num2str(xyz(2))]);
posx = getPos(0, 'X');
posy = getPos(0, 'Y');

try
    img = imread([handles.myData.mrArray(1).http file]);
catch
    img = imread([handles.myData.mrArray(1).http file]);
end
hold off; imagesc(img); axis image; hold on;
plot(xy(1), xy(2), 'r.');
plot(xy(1), xy(2), 'ms', 'MarkerSize', 15);
text(xy(1)+25, xy(2), ['[Cent_' num2str(pnum) ']'], 'Color', 'g');

L = handles.myData.Calib(mag10, cmagIdx).L;

for i = 1:length(handles.myData.pointList)
    xyzp   = handles.myData.pointList(i).xyz;
    xyp    = handles.myData.pointList(i).xy_image;
    magIdx = handles.myData.pointList(i).magIdx;

    xy_g     = global_xy(xyzp(1:2), xyp, handles, magIdx);
    x10      = inv(K10) * round([xy_g; 1] - [posx(1); posy(1); 1]);
    x10(3)   = 1;
    xyp_hat  = inv(L) * x10;
    polyXY(i,:) = xyp_hat;

    hold all;
    plot(xyp_hat(1), xyp_hat(2), 'ms', 'MarkerSize', 15);
    plot(xyp_hat(1), xyp_hat(2), 'ys', 'MarkerSize',  9);
    plot(xyp_hat(1), xyp_hat(2), 'r.');
    text(xyp_hat(1)+25, xyp_hat(2), ['[P_' num2str(i) ']'], 'Color', 'b');
end

polyXY(end+1,:) = polyXY(1,:);
plot(polyXY(:,1), polyXY(:,2), 'm');

guidata(hObject, handles);


% --- Executes on button press in pushbutton29.  Plot Points
function pushbutton29_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton29 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

pnum    = 1;
xyz     = handles.myData.pointList(pnum).xyz;
xy      = handles.myData.pointList(pnum).xy_image;
magIdx  = handles.myData.pointList(pnum).magIdx;
cmagIdx = handles.myData.cmagIndx;

title(['Stage Moving... ']);

file = 'out.jpg';
try
    img = imread([handles.myData.mrArray(1).http file]);
catch
    img = imread([handles.myData.mrArray(1).http file]);
end
hold off; imagesc(img); axis image; hold on;

z = xyz(3);
[xy_g, xyi] = global_xy(xyz(1:2), xy, handles, magIdx);

mag10 = 3;
K10   = handles.myData.Calib_K10;

if isfield(handles.myData.pointList, 'K')
    K   = handles.myData.pointList(pnum).K;
    L   = handles.myData.Calib(mag10, cmagIdx).L;
    xyz = round([xy_g; 1] - K10*L * [size(img,2)/2; size(img,1)/2; 1]);
    xy  = [size(img,2)/2; size(img,1)/2];
end

posx = getPos(0, 'X');
posy = getPos(0, 'Y');

try
    img = imread([handles.myData.mrArray(1).http file]);
catch
    img = imread([handles.myData.mrArray(1).http file]);
end
hold off; imagesc(img); axis image; hold on;

L = handles.myData.Calib(mag10, cmagIdx).L;

for i = 1:length(handles.myData.pointList)
    xyzp   = handles.myData.pointList(i).xyz;
    xyp    = handles.myData.pointList(i).xy_image;
    magIdx = handles.myData.pointList(i).magIdx;

    xy_g     = global_xy(xyzp(1:2), xyp, handles, magIdx);
    x10      = inv(K10) * round([xy_g; 1] - [posx(1); posy(1); 1]);
    x10(3)   = 1;
    xyp_hat  = inv(L) * x10;
    polyXY(i,:) = xyp_hat;

    hold all;
    plot(xyp_hat(1), xyp_hat(2), 'ms', 'MarkerSize', 15);
    plot(xyp_hat(1), xyp_hat(2), 'ys', 'MarkerSize',  9);
    plot(xyp_hat(1), xyp_hat(2), 'r.');
    text(xyp_hat(1)+25, xyp_hat(2), ['[P_' num2str(i) ']'], 'Color', 'b');
end

polyXY(end+1,:) = polyXY(1,:);
plot(polyXY(:,1), polyXY(:,2), 'm');

guidata(hObject, handles);

% Global point map
figure(100);
rr = range([handles.myData.pointList.xyzg]');
dx = rr(1)/90;
dy = rr(2)/90;
for i = 1:length(handles.myData.pointList)
    xyzp   = handles.myData.pointList(i).xyz;
    xyp    = handles.myData.pointList(i).xy_image;
    magIdx = handles.myData.pointList(i).magIdx;
    xyp    = global_xy(xyzp(1:2), xyp, handles, magIdx);

    plot(xyp(1), xyp(2), 'ms', 'MarkerSize', 15);
    hold all;
    plot(xyp(1), xyp(2), 'cs', 'MarkerSize', 11);
    text(xyp(1)-dx, xyp(2), num2str(i), 'Color', 'b', 'Fontsize', 8);
end
axis ij; axis xy;
title([num2str(length(handles.myData.pointList)) '  Points']);


% --- Executes on button press in pushbutton30.
function pushbutton30_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton30 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pushbutton31.
function pushbutton31_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton31 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pushbutton32.  Calibrate
function pushbutton32_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton32 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

objlist  = [2, 4, 10, 20, 40, 50, 60, 100];
[indx, tf] = listdlg('ListString', {'2x','4x','10x','20x','40x','50x','60x','100x'}, ...
    'SelectionMode', 'single', 'ListSize', [120 120], 'Name', '  OBJECTIVE : ');
handles.myData.pointList(1).Objective = objlist(indx);

magIndx  = indx;
str      = get(handles.myData.curr_obj_Obj, 'String');
curr_mag = str2num(str(1:(end-1)));
calib_mag = handles.myData.pointList(1).Objective;
alpha    = curr_mag / calib_mag;

handles.myData.pointList(1).alpha = alpha;

file = 'out.jpg';
try
    img = imread([handles.myData.mrArray(1).http file]);
catch
    img = imread([handles.myData.mrArray(1).http file]);
end
hold off; imagesc(img);
axis image; axis off; hold on;

zoom off;
pause(2);
[y, x] = ginput(1);
zoom out; zoom off;
drawnow; shg;

f2 = 6;
t  = [0 30 60 90 120 150 180 210 240 270 300 330];

msg = sendCOmmand(0, ['SMS 5']);
msg = sendCOmmand(0, ['SAS 5']);

xx = sendCommand(0, 'PX');
yy = sendCommand(0, 'PY');
zz = sendCommand(0, 'PZ');

xm(1,:) = [str2num(xx) str2num(yy)];
m50  = 30;
m100 = m50 * f2 * 2;

for i = 1:length(t)
    if i == 1
        wdw   = img(round(x)+(-m50:m50), round(y)+(-m50:m50), :);
        wdw_e = edge(double(rgb2gray(wdw)), 'prewitt');
    end

    xx = sendCommand(0, 'PX');
    yy = sendCommand(0, 'PY');
    zz = sendCommand(0, 'PZ');

    plot(y, x, 'r+');
    text(y, x+10, [xx ',' yy ',' zz '.'], 'Color', 'y');

    dm(i,:)    = 4350 * [cosd(t(i)), sind(t(i))] * f2 / calib_mag;
    xm(i+1,:) = [xm(1,1)+dm(i,1) xm(1,2)+dm(i,2)];

    msg = sendCommand(0, ['GX,' num2str(xm(i+1,1))]);
    msg = sendCommand(0, ['GY,' num2str(xm(i+1,2))]);
    pause(1);
    msg = sendCommand(0, ['GX,' num2str(xm(i+1,1))]);
    msg = sendCommand(0, ['GY,' num2str(xm(i+1,2))]);

    posx = getPos(0, 'X');
    posy = getPos(0, 'Y');

    try
        img = imread([handles.myData.mrArray(1).http file]);
        img = imread([handles.myData.mrArray(1).http file]);
    catch
        img = imread([handles.myData.mrArray(1).http file]);
        img = imread([handles.myData.mrArray(1).http file]);
    end

    hold off; imagesc(img);
    axis image; axis off; shg; hold on;
    plot(y, x, 'g+');

    wdw2 = img(round(x)+(-m100:m100), round(y)+(-m100:m100), :);

    C   = normxcorr2(double(rgb2gray(wdw)),  double(rgb2gray(wdw2)));
    C_e = normxcorr2(double(rgb2gray(wdw)),  double(rgb2gray(wdw2)));
    [dx,  dy]   = find(C   == max(C(:)));
    [dx_e, dy_e] = find(C_e == max(C_e(:)));

    dx   = dx   - size(C, 1)/2 + 1/2;
    dy   = dy   - size(C, 2)/2 + 1/2;
    dx_e = dx_e - size(C, 1)/2;
    dy_e = dy_e - size(C, 2)/2;

    plot(y+dy, x+dx, 'm+');
    plot([y y+dy], [x x+dx], 'g');
    text(y, x+10, '1', 'Color', 'r');
    drawnow;

    ddx(:,i) = [dy; dx];
end

dr = (ddx(1,:).^2 + ddx(2,:).^2)';
[mm, nn] = hist(dr);
[~, id]  = max(mm);
gidx     = find(abs(dr - nn(id)) < dr*0.05);
gidx     = 1:size(dm, 1);

K = -[[dm(gidx,:)'];  [dm(gidx,1)*0+1]'] * pinv([[ddx(:,gidx)]; [dm(gidx,1)*0+1]']);

xg = [xm(1,:)'; 1] + K*[y; x; 1]';

xm_hat = round(xg - K*[size(img,2)/2; size(img,1)/2; 1]);

msg = sendCommand(0, ['GX,' num2str(xm_hat(1))]);
msg = sendCommand(0, ['GY,' num2str(xm_hat(2))]);
msg = sendCommand(0, ['GX,' num2str(xm_hat(1))]);
msg = sendCommand(0, ['GY,' num2str(xm_hat(2))]);

posx = getPos(0, 'X');
posy = getPos(0, 'Y');

pause(1);
try
    img = imread([handles.myData.mrArray(1).http file]);
    img = imread([handles.myData.mrArray(1).http file]);
catch
    img = imread([handles.myData.mrArray(1).http file]);
    img = imread([handles.myData.mrArray(1).http file]);
end

hold off; imagesc(img);
axis image; axis off; shg; hold on;
plot(y, x, 'g+');
plot(y+dy, x+dx, 'ro');
drawnow;
hold all;
plot(y, x, 'g+');
plot(size(img,2)/2, size(img,1)/2, 'rs');

dxe = norm([y, x] - [size(img,2)/2, size(img,1)/2]);
title(num2str(K));

handles.myData.pointList(1).K    = K;
handles.myData.Calib_K(magIndx).K = K;
handles.myData.Calib_xy  = [x, y];
handles.myData.Calib_xyg = xg;

if magIndx == 3
    handles.myData.Calib_K10 = K;
    save K10x K
end

Calib_K = handles.myData.Calib_K;
save Calib_K_tmp Calib_K

guidata(hObject, handles);


function [xg, xii] = global_xy(xm, xi, handles, magIndx)
% global_xy  Compute global (motor) coordinates from stage position and image point.
%
%   xm      : stepper motor [x y]
%   xi      : image [x y]
%   magIndx : magnification index of xi (assumed same as current view)

magIndx_ref = 3;

img = imread([handles.myData.mrArray(1).http 'out.jpg']);
y   = xi(1); x = xi(2);
xm1 = [xm(1); xm(2)];

if isfield(handles.myData.pointList, 'K')
    handles.myData.Calib_K(magIndx_ref);
    K = handles.myData.Calib_K(magIndx_ref).K;
    handles.myData.Calib(magIndx_ref, magIndx);
    L = handles.myData.Calib(magIndx_ref, magIndx).L;
    xg = [xm1; 1] + K*L*[y; x; 1];
    xg = [xg(1) xg(2)]';
    xii = [size(img,2); size(img,1)] / 2;
else
    xg  = xm1;
    xii = xi;
end


function [xg, xii] = global_xy_center(xm, xi, handles)
% global_xy_center  Compute global coordinates centred on image midpoint.
%
%   xm : stepper motor [x y]
%   xi : image [x y]

alpha = handles.myData.pointList(1).alpha;
img   = imread([handles.myData.mrArray(1).http 'out.jpg']);
y     = xi(1); x = xi(2);
xm1   = [xm(1); xm(2)];

if isfield(handles.myData.pointList, 'K')
    K  = handles.myData.pointList(1).K;
    xg = [xm1; 1] + K*[y; x; 1];
    xg = [xg(1) xg(2)]';
    xii = [size(img,2); size(img,1)] / 2;
else
    xg  = xm1;
    xii = xi;
end


% --- Executes on button press in pushbutton33.  Objective Button
function pushbutton33_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton33 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

obj_list = {'2x','4x','10x','20x','40x','50x','60x','100x'};
[indx, tf] = listdlg('ListString', obj_list, 'SelectionMode', 'single', ...
    'ListSize', [120 120], 'Name', '  OBJECTIVE : ');
msg = char(obj_list{indx});

set(handles.myData.curr_obj_Obj, 'String', msg);
handles.myData.pointList(1).curr_obj_Obj = handles.myData.curr_obj_Obj;

str      = get(handles.myData.curr_obj_Obj, 'String');
curr_mag = str2num(str(1:(end-1)));

indx = find(strcmp(obj_list, str) == 1);
handles.myData.cmagIndx = indx;
handles.myData.cmag     = curr_mag;
handles.myData.pointList(1).Objective = str;
guidata(hObject, handles);


% --- Executes on button press in pushbutton26.
function pushbutton26_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton26 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

msg = sendCommand(0, 'PY');
set(handles.myData.yObjectMicron, 'String', msg);
guidata(hObject, handles);


function edit23_Callback(hObject, eventdata, handles)
% hObject    handle to edit23 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

obj_list = {'2x','4x','10x','20x','40x','50x','60x','100x'};
str      = get(handles.myData.curr_obj_Obj, 'String');
curr_mag = str2num(str(1:(end-1)));
indx     = find(strcmp(obj_list, str) == 1);
handles.myData.cmagIndx = indx;
handles.myData.cmag     = curr_mag;
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function edit23_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit23 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end
handles.myData.curr_obj_Obj = hObject;
set(hObject, 'String', '4x');
guidata(hObject, handles);


% --- Executes on button press in pushbutton34.  fun_zoom
function pushbutton34_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton34 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

zoom on;
pause()
zoom off;
zoom out;
drawnow; shg;


% --- Executes on button press in pushbutton35.  Calib L
function pushbutton35_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton35 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%
% Calibration relation:
%   xs1 = Calib(indx1,indx2).L * xs2
%   xs2 = Calib(indx2,indx1).L * xs1

objlist  = [2, 4, 10, 20, 40, 50, 60, 100];
obj_list = {'2x','4x','10x','20x','40x','50x','60x','100x'};

[indx, tf] = listdlg('ListString', {'2x','4x','10x','20x','40x','50x','60x','100x'}, ...
    'SelectionMode', 'single', 'ListSize', [120 120], 'Name', '  Scale 1 / 2 : ');
dans = questdlg(['PUT OBJECTIVE ON : * ' char(obj_list{indx}) ' *'], ...
    'OBJ CHANGE', 'OK', 'NO');

indx1 = indx;

if 0  % indx1==2 || indx1==3: load from file (disabled)
    load Calib_L1;
    handles.myData.Calib = Calib_L;
    title('Loaded Calibration L from file L1');
else
    handles.myData.pointList(1).Objective = objlist(indx);
    magIndx  = indx;
    str      = get(handles.myData.curr_obj_Obj, 'String');
    curr_mag = str2num(str(1:(end-1)));
    calib_mag = handles.myData.pointList(1).Objective;

    file = 'out.jpg';
    try
        img = imread([handles.myData.mrArray(1).http file]);
    catch
        img = imread([handles.myData.mrArray(1).http file]);
    end
    hold off; imagesc(img);
    axis image; axis off; hold on;

    zoom on;
    pause();

    [ys1, xs1] = ginput(4);
    zoom out; zoom off;
    drawnow; shg;

    [indx, tf] = listdlg('ListString', obj_list, 'SelectionMode', 'single', ...
        'ListSize', [120 120], 'Name', '  Scale 2 / 2 : ');
    indx2 = indx;

    dans = questdlg(['PUT OBJECTIVE ON : * ' char(obj_list{indx}) ' *'], ...
        'OBJ CHANGE', 'OK', 'NO');

    zoom on;
    disp('Press Any Key to Exit Zoom')
    pause();
    zoom off;
    [ys2, xs2] = ginput(4);
    zoom out; zoom off;
    drawnow; shg;

    L = [ys1(1:3) xs1(1:3) xs1(1:3)*0+1]' * pinv([ys2(1:3) xs2(1:3) xs2(1:3)*0+1]');

    handles.myData.Calib(indx1, indx2).L = L;
    handles.myData.Calib(indx2, indx1).L = pinv(L);
    handles.myData.Calib(indx1, indx1).L = 1;
    handles.myData.Calib(indx2, indx2).L = 1;

    Calib_L = handles.myData.Calib;

    fn = ['L_' num2str(indx1) '_' num2str(indx2) '.mat'];
    eval(['save  ' fn ' L']);
    eval(['save  Calib_L   Calib_L']);

    title(num2str(L))
end

guidata(hObject, handles);


% --- Executes on button press in pushbutton36.
function pushbutton36_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton36 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

open_stereo_core(hObject, eventdata, handles);


% --- Executes on mouse press over axes background.
function axes1_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to axes1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


function saveState1(handles)
state = [];
guiFields = fields(handles);
for k = 1:length(guiFields)
    obj = handles.(guiFields{k});
    if isscalar(obj) && ishghandle(obj) && isfield(get(obj), 'Style')
        style = get(obj, 'Style');
        if strcmpi(style, 'radiobutton')
            state.(guiFields{k}) = get(obj, 'BackgroundColor');
        end
    end
end
save('state.mat', 'state');


function loadState1(handles)
filename = 'state.mat';
if exist(filename, 'file')
    load(filename);
    stateFields = fields(state);
    for k = 1:length(stateFields)
        set(handles.(stateFields{k}), 'BackgroundColor', state.(stateFields{k}));
    end
end


% --- Executes during object creation, after setting all properties.
function pushbutton32_CreateFcn(hObject, eventdata, handles)
% hObject    handle to pushbutton32 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes on key press with focus on pushbutton32 and none of its controls.
function pushbutton32_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to pushbutton32 (see GCBO)
% eventdata  structure with the following fields (see UICONTROL)
%   Key: name of the key that was pressed, in lower case
%   Character: character interpretation of the key(s) that was pressed
%   Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)


% --- Executes during object creation, after setting all properties.
function pushbutton23_CreateFcn(hObject, eventdata, handles)
% hObject    handle to pushbutton23 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


function edit25_Callback(hObject, eventdata, handles)
% hObject    handle to edit25 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

['disector_h= ' get(hObject, 'string')]
get(handles.myData.disector_h_obj, 'string')
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function edit25_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit25 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

handles.myData.disector_h_obj = hObject;
guidata(hObject, handles);


function edit26_Callback(hObject, eventdata, handles)
% hObject    handle to edit26 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

goodList = str2num(get(handles.myData.stereo_points_obj, 'string'));
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function edit26_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit26 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end
handles.myData.stereo_points_obj = hObject;
goodList = str2num(get(handles.myData.stereo_points_obj, 'string'));
guidata(hObject, handles);


function edit27_Callback(hObject, eventdata, handles)
% hObject    handle to edit27 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

wdwSize = str2num(get(handles.myData.stereo_wdwSize_obj, 'string'));
guidata(hObject, handles)


% --- Executes during object creation, after setting all properties.
function edit27_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit27 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end
handles.myData.stereo_wdwSize_obj = hObject;
guidata(hObject, handles)


function edit28_Callback(hObject, eventdata, handles)
% hObject    handle to edit28 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.myData.disector_K_obj = hObject;
get(handles.myData.disector_K_obj, 'string')
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function edit28_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit28 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end
handles.myData.disector_K_obj = hObject;
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function pushbutton22_CreateFcn(hObject, eventdata, handles)
% hObject    handle to pushbutton22 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes during object creation, after setting all properties.
function pushbutton36_CreateFcn(hObject, eventdata, handles)
% hObject    handle to pushbutton36 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes during object deletion, before destroying properties.
function pushbutton36_DeleteFcn(hObject, eventdata, handles)
% hObject    handle to pushbutton36 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes during object creation, after setting all properties.
function pushbutton34_CreateFcn(hObject, eventdata, handles)
% hObject    handle to pushbutton34 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes during object deletion, before destroying properties.
function pushbutton34_DeleteFcn(hObject, eventdata, handles)
% hObject    handle to pushbutton34 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes during object creation, after setting all properties.
function figure1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes during object deletion, before destroying properties.
function pushbutton6_DeleteFcn(hObject, eventdata, handles)
% hObject    handle to pushbutton6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes during object creation, after setting all properties.
function pushbutton6_CreateFcn(hObject, eventdata, handles)
% hObject    handle to pushbutton6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
