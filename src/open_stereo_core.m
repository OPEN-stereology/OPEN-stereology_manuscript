
% Part of OPEN-Stereology Core Function suite – Reviewer Copy ONLY
%
% Copyright (c) 2021-2025, OPEN-Stereology
% Licensed under the PolyForm Noncommercial License 1.0.0
% https://polyformproject.org/licenses/noncommercial/1.0.0
%
% Developed by the OPEN-Stereology project team at UC San Diego (UCSD).
% For more information, see: https://github.com/OPEN-Stereology
%
% ───────────────────────────────────────────────────────────────
% This version is provided for peer review only and is not yet
% released for general use. Redistribution, reuse, or modification
% is prohibited outside the scope of scholarly evaluation by
% designated reviewers or journals.
%
% This software will be made publicly available upon publication.
% ───────────────────────────────────────────────────────────────
%
% NO WARRANTY: This code is provided “as is” without warranty of any kind,
% express or implied. The authors and affiliated institutions disclaim all
% liability for any use, misuse, or interpretation of the software.
%
% DO NOT POST OR CIRCULATE WITHOUT PERMISSION.


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

function open_stereo_core(hObject, eventdata, handles)
    % Main stereology analysis function for microscopy data
    % Performs systematic sampling with disector methodology
    
    clear('global', 'pointFlag')
    global pointFlag
    
    % Calculate microns per pixel at current magnification
    try
        um_per_pix_40x = 3.71 / 40 * (40 / handles.myData.cmag);
    catch
        errordlg('OBJECTIVE Unknown - SELECT CURRENT OBJ')
        return
    end
    
    % Check if live streaming is active
    go_color = get(handles.myData.stacks_GO_Object, 'BackgroundColor');
    if go_color(2) < 1
        errordlg(['PUT ON LIVE-STREAMING and' char(10) 'SET Z-TOP and Z-BOTTOM FIRST'])
        return
    end
    
    % Initialize point flag structure
    pointFlag(1).count = 0;
    pointFlag(1).xy = [0 0];
    pointFlag = rmfield(pointFlag, 'xy');
    pointFlag(1).xy = [0 0];
    
    % Get user-defined point list and parameters
    goodList = str2num(get(handles.myData.stereo_points_obj, 'string'));
    wdwSize = str2num(get(handles.myData.stereo_wdwSize_obj, 'string'));
    disector_K = str2num(get(handles.myData.disector_K_obj, 'string'));
    
    % Calculate window distance based on disector factor
    wdwDist = wdwSize * disector_K;
    
    % Get initial point data
    pnum = 1;
    xyz = handles.myData.pointList(pnum).xyz;
    xy = handles.myData.pointList(pnum).xy_image;
    magIdx = handles.myData.pointList(pnum).magIdx;
    cmagIdx = handles.myData.cmagIndx;
    
    % Load and display initial image
    file = 'out.jpg';
    try
        img = imread([handles.myData.mrArray(1).http file]);
    catch
        img = imread([handles.myData.mrArray(1).http file]);
    end
    hold off; 
    imagesc(img); 
    axis image;
    hold all;
    hold(gca, 'on')
    
    % Get z position and calibration data
    z = xyz(3);
    [xy_g, xyi] = global_xy(xyz(1:2), xy, handles, magIdx);
    
    % Load calibration matrices
    mag10 = 3;
    K10 = handles.myData.Calib_K10;
    
    % Calculate transformation if calibration data exists
    if isfield(handles.myData.pointList, 'K')
        K = handles.myData.pointList(pnum).K;
        L = handles.myData.Calib(mag10, cmagIdx).L;
        
        xyz = round([xy_g; 1] - K10 * L * [size(img,2)/2; size(img,1)/2; 1]);
        xy = [size(img,2)/2; size(img,1)/2];
    end
    
    % Get current motor positions
    posx = getPos(0, 'X');
    posy = getPos(0, 'Y');
    
    % Reload image after positioning
    try
        img = imread([handles.myData.mrArray(1).http file]);
    catch
        img = imread([handles.myData.mrArray(1).http file]);
    end
    hold off; 
    imagesc(img); 
    axis image;
    hold all;
    
    % Calculate transformation matrix
    L = handles.myData.Calib(mag10, cmagIdx).L;
    
    % Process all points in the good list - first pass for display
    for ii = 1:length(goodList)
        i = goodList(ii);
        xyzp = handles.myData.pointList(i).xyz;
        xyp = handles.myData.pointList(i).xy_image;
        magIdx = handles.myData.pointList(i).magIdx;
        
        % Convert to global coordinates
        xy_g = global_xy(xyzp(1:2), xyp, handles, magIdx);
        x10 = inv(K10) * round([xy_g; 1] - [posx(1); posy(1); 1]);
        x10(3) = 1;
        xyp_hat = inv(L) * x10;
        polyXY(ii,:) = xyp_hat;
        
        % Plot points
        hold all;
        plot(xyp_hat(1), xyp_hat(2), 'ms', 'MarkerSize', 15);
        plot(xyp_hat(1), xyp_hat(2), 'ys', 'MarkerSize', 9);
        plot(xyp_hat(1), xyp_hat(2), 'r.');
        text(xyp_hat(1)+25, xyp_hat(2), ['[P_' num2str(i) ']'], 'Color', 'b');
    end
    
    % Plot polygon outline
    plot(polyXY(:,1), polyXY(:,2), 'm');
    xmin = min(polyXY(:,1)); xmax = max(polyXY(:,1));
    ymin = min(polyXY(:,2)); ymax = max(polyXY(:,2));
    
    axis ij
    hold on
    clear polyXY;
    
    % Second pass - recalculate for global coordinates
    for ii = 1:length(goodList)
        i = goodList(ii);
        xyzp = handles.myData.pointList(i).xyz;
        xyp = handles.myData.pointList(i).xy_image;
        magIdx = handles.myData.pointList(i).magIdx;
        
        xy_g = global_xy(xyzp(1:2), xyp, handles, magIdx);
        x10 = inv(K10) * round([xy_g; 1] - [posx(1); posy(1); 1]);
        x10(3) = 1;
        xyp_hat = inv(L) * x10;
        polyXY(ii,:) = xyp_hat;
        polyXYg(ii,:) = xy_g;
        
        hold all;
        plot(xyp_hat(1), xyp_hat(2), 'ms', 'MarkerSize', 15);
        plot(xyp_hat(1), xyp_hat(2), 'ys', 'MarkerSize', 9);
        plot(xyp_hat(1), xyp_hat(2), 'r.');
        text(xyp_hat(1)+25, xyp_hat(2), ['[P_' num2str(i) ']'], 'Color', 'b');
    end
    
    % Plot global coordinates
    plot(polyXY(:,1), polyXY(:,2), 'g');
    xming = min(polyXYg(:,1)); xmaxg = max(polyXYg(:,1));
    yming = min(polyXYg(:,2)); ymaxg = max(polyXYg(:,2));
    
    xbxg = [xming xming xmaxg xmaxg xmaxg xming; yming ymaxg ymaxg ymaxg yming yming]';
    
    plot(polyXYg(:,1), polyXYg(:,2), 'g');
    hold all;
    plot(xbxg(:,1), xbxg(:,2), 'm');
    axis image;
    axis ij
    
    % Calculate sampling window parameters
    dx = xmax - xmin;
    dy = ymax - ymin;
    
    % Convert window size to pixels
    Dx = wdwSize / (um_per_pix_40x);
    DDx = wdwDist / (um_per_pix_40x);
    
    % Calculate global parameters
    dxg = xmaxg - xming;
    dyg = ymaxg - yming;
    Dxg = dxg / dx * Dx;
    DDxg = dxg / dx * DDx;
    
    % Create sampling grid
    [xi, yi] = meshgrid(xmin:DDx:xmax, ymin:DDx:ymax);
    [xig, yig] = meshgrid(xming:DDxg:xmaxg, yming:DDxg:ymaxg);
    
    % Apply random rotation to avoid systematic bias
    theta = 40 * (rand - 0.5) * pi / 180;
    handles.myData.pointList(1).thetaDegrees = theta * 180 / pi;
    center = [mean(xig(:)), mean(yig(:))];
    center = repmat(center', 1, length(yig(:)));
    RR = [cos(theta) -sin(theta); sin(theta) cos(theta)];
    xxx = RR * ([xig(:), yig(:)]' - center) + center;
    xig = xxx(1,:);
    yig = xxx(2,:);
    
    % Determine points inside polygon
    A = 1 - Dx / dx;
    xt = polyXYg(:,1);
    yt = polyXYg(:,2);
    
    [inp, onp] = inpolygon(xig(:), yig(:), xt, yt);
    
    plot(xig(:), yig(:), 'g.');
    hold on
    plot(xig(inp), yig(inp), 'm.');
    
    st_xg = xig(inp);
    st_yg = yig(inp);
    
    % Initialize counters
    tot = 0;
    tot(2) = 0;
    
    % Main sampling loop
    for l = 1:length(st_xg)
        xy_g = [st_xg(l); st_yg(l)];
        
        % Move to sampling point
        [xm, xy] = GotoXY(hObject, eventdata, handles, xy_g, cmagIdx);
        text(1024+25, 822, ['[' num2str(l) ']'], 'Color', 'm');
        
        posx = xm(1);
        posy = xm(2);
        
        % Update point positions for current location
        for ii = 1:length(goodList)
            i = goodList(ii);
            xyzp = handles.myData.pointList(i).xyz;
            xyp = handles.myData.pointList(i).xy_image;
            magIdx = handles.myData.pointList(i).magIdx;
            
            xy_g_temp = global_xy(xyzp(1:2), xyp, handles, magIdx);
            x10 = inv(K10) * round([xy_g_temp; 1] - [posx(1); posy(1); 1]);
            x10(3) = 1;
            xyp_hat = inv(L) * x10;
            polyXY(ii,:) = xyp_hat;
            
            hold all;
            plot(xyp_hat(1), xyp_hat(2), 'ms', 'MarkerSize', 15);
            plot(xyp_hat(1), xyp_hat(2), 'ys', 'MarkerSize', 9);
            plot(xyp_hat(1), xyp_hat(2), 'r.');
            text(xyp_hat(1)+25, xyp_hat(2), ['[P_' num2str(i) ']'], 'Color', 'b');
        end
        plot(polyXY(:,1), polyXY(:,2), 'g');
        
        % Display image in axes3
        axes(handles.axes3)
        try
            img = imread([handles.myData.mrArray(1).http file]);
        catch
            img = imread([handles.myData.mrArray(1).http file]);
        end
        hold off; 
        imagesc(img); 
        axis image;
        hold all;
        
        posx = xm(1);
        posy = xm(2);
        
        % Get Z resolution
        msg1 = SendCommand(0, 'RES,Z');
        u_per_s = sscanf(msg1, '%f/r')';
        
        ddz = str2num(get(handles.myData.dzRelMicronObject, 'String'));
        
        % Update point positions again for stereology display
        for ii = 1:length(goodList)
            i = goodList(ii);
            xyzp = handles.myData.pointList(i).xyz;
            xyp = handles.myData.pointList(i).xy_image;
            magIdx = handles.myData.pointList(i).magIdx;
            
            xy_g_temp = global_xy(xyzp(1:2), xyp, handles, magIdx);
            x10 = inv(K10) * round([xy_g_temp; 1] - [posx(1); posy(1); 1]);
            x10(3) = 1;
            xyp_hat = inv(L) * x10;
            polyXY(ii,:) = xyp_hat;
            polyXYg(ii,:) = xy_g_temp;
            
            hold all;
            plot(xyp_hat(1), xyp_hat(2), 'ms', 'MarkerSize', 15);
            plot(xyp_hat(1), xyp_hat(2), 'ys', 'MarkerSize', 4);
            plot(xyp_hat(1), xyp_hat(2), 'r.');
        end
        
        % Display sampling grid on axes3
        axes(handles.axes3)
        hold off
        plot(xig(:), yig(:), 'g.');
        hold on;
        plot(xig(inp), yig(inp), 'k.');
        
        plot(polyXYg(:,1), polyXYg(:,2), 'm');
        plot(polyXYg(:,1), polyXYg(:,2), 'b*');
        
        % Calculate sampling window size
        try
            dr = sqrt((st_xg(1) - st_xg(2))^2 + (st_yg(1) - st_yg(2))^2);
        catch
            errordlg('Bad combination of Disector Width/K_factor')
            return
        end
        
        dr = [dr, dr] / 2;
        Kfactor = wdwSize / wdwDist;
        dr = dr * Kfactor;
        
        % Draw sampling windows
        for iii = 1:length(st_xg)
            pbx = [st_xg(iii)-dr(1) st_xg(iii)-dr(1) st_xg(iii)+dr(1) st_xg(iii)+dr(1) st_xg(iii)-dr(1)];
            pby = [st_yg(iii)-dr(2) st_yg(iii)+dr(2) st_yg(iii)+dr(2) st_yg(iii)-dr(2) st_yg(iii)-dr(2)];
            
            plot(pbx, pby, 'b');
            
            if iii == l
                plot(pbx, pby, 'm');
                plot(xig(inp), yig(inp), 'g.');
            end
        end
        
        axis image;
        axis off;
        axes(handles.axes1)
        
        % Initialize counting interface
        nn = 0;
        bb = -1;
        rec_obj = handles.myData.mrArray(1).record_obj;
        
        pointFlag = pointFlag(1);
        pointFlag(1).count = 0;
        handles.myData.nextPointFlag = 0;
        handles.myData.currentObj = hObject;
        handles.myData.setereoSectionNumber = num2str(l);
        
        guidata(hObject, handles);
        
        % Set up mouse callback for point marking
        set(handles.figure1, 'WindowButtonDownFcn', {@pKey, hObject});
        
        cellNum = 0;
        pointFlag(1).xy = [];
        
        % Interactive counting loop
        while pointFlag(1).count >= 0
            try
                img = imread([handles.myData.mrArray(1).http file]);
            catch
                img = imread([handles.myData.mrArray(1).http file]);
            end
            hold off; 
            imagesc(img); 
            axis image;
            hold all;
            
            if pointFlag(1).count >= 0
                cellNum = pointFlag(1).count;
            end
            
            try
                tot(l+1) = cellNum + tot(l);
            catch
                keyboard
            end
            
            ddz = str2num(get(handles.myData.dzRelMicronObject, 'String'));
            
            title(['** LIVE ** Stereology Point ' num2str(l) ' of ' num2str(length(st_xg)) ...
                   ' Total Wdw= ' num2str(cellNum) ' Grand Total=' num2str(cellNum+tot(l)) ...
                   ' dZ=' num2str(ddz)]);
            
            % Draw counting window
            xc = [1024; 822];
            ddx = round(wdwSize / (2 * (um_per_pix_40x)));
            ddy = ddx;
            
            xg = xc * ones(1,3) + [-ddx -ddx ddx; -ddy ddy ddy];
            xr = xc * ones(1,3) + [ddx ddx -ddx; ddy -ddy -ddy];
            plot(xr(1,:), xr(2,:), 'r');
            plot(xg(1,:), xg(2,:), 'g');
            text(mean(xg(1,:)), max(xg(2,:)) + 30, ...
                 [' Window Size= [ ' num2str(abs(Dx)*um_per_pix_40x) ' ] microns']);
            
            zoomFactor = 822 / ddx * 0.90;
            drawnow;
            shg;
            
            axes(handles.axes1)
        end
        
        % Store stereology data
        try
            stereoArray(1).pointFlag = pointFlag;
            
            for kk = 1:(length(pointFlag))
                stereoArray(l).xy(kk).xy = pointFlag(kk).xy;
                stereoArray(l).xy(kk).xyg = pointFlag(kk).xyg;
                stereoArray(l).xy(kk).dz = ddz;
                stereoArray(l).xy(kk).xyg = pointFlag(kk).xyg;
                stereoArray(l).xy(kk).z = pointFlag(kk).z;
                stereoArray(l).xy(kk).ztop = pointFlag(kk).ztop;
                stereoArray(l).xy(kk).zbottom = pointFlag(kk).zbottom;
                stereoArray(l).xy(kk).z_u_per_s = pointFlag(kk).z_u_per_s;
                stereoArray(l).xy(kk).disector_h = pointFlag(kk).disector_h;
                stereoArray(l).xy(kk).k_factor = pointFlag(kk).k_factor;
            end
        catch
            keyboard
        end
        
        % Reset interface
        zoom(1);
        set(gcf, 'Pointer', 'arrow')
        set(handles.figure1, 'WindowButtonDownFcn', {});
    end
    
    % Final display
    title(['** DONE ** Stereology Point ' num2str(l) ' of ' num2str(length(st_xg)) ...
           ' Grand Total cells= ' num2str(tot(end))]);
    
    % Save results
    handles.myData.stereoArray = stereoArray;
    stereoArray(1).pointList = handles.myData.pointList;
    stereoArray(1).goodList = goodList;
    stereoArray(1).pointFlag = pointFlag;
    
    % Generate unique filename
    stereoFile = ['stereoArray_' get(handles.myData.Name_Obj, 'String')];
    stereoFile_base = stereoFile(1:(end-4));
    
    k = 1;
    while exist(stereoFile)
        stereoFile = [stereoFile_base '_' num2str(k) '.mat'];
        k = k + 1;
    end
    
    save(stereoFile, 'stereoArray');
    guidata(hObject, handles);
end

function [xm, xs] = GotoXY(hObject, eventdata, handles, xy_g, cmagIdx)
    % Move microscope stage to specified global coordinates
    global pointFlag
    
    axes(handles.axes1)
    shg;
    
    % Load current image
    file = 'out.jpg';
    try
        img = imread([handles.myData.mrArray(1).http file]);
    catch
        img = imread([handles.myData.mrArray(1).http file]);
    end
    hold off; 
    imagesc(img);
    axis image;
    hold on;
    
    % Get calibration data
    mag10 = 3;
    K10 = handles.myData.Calib_K10;
    L = handles.myData.Calib(mag10, cmagIdx).L;
    
    % Calculate motor coordinates
    xy = [size(img,2)/2; size(img,1)/2];
    xyz = round([xy_g; 1] - K10 * L * [xy; 1]);
    
    % Send movement commands
    msg = sendCommand(0, ['GX,' num2str(xyz(1))]);
    msg = sendCommand(0, ['GY,' num2str(xyz(2))]);
    
    % Get actual positions
    posx = getPos(0, 'X');
    posy = getPos(0, 'Y');
    
    % Reload and display image at new position
    try
        img = imread([handles.myData.mrArray(1).http file]);
    catch
        img = imread([handles.myData.mrArray(1).http file]);
    end
    hold off; 
    imagesc(img); 
    axis image;
    hold on;
    plot(xy(1), xy(2), 'm.');
    plot(xy(1), xy(2), 'gs', 'MarkerSize', 8);
    
    % Return motor and screen coordinates
    xm = [posx; posy];
    xs = xy;
end

function pKey(src, event, hObject)
    % Handle mouse clicks for point marking during stereology counting
    global pointFlag;
    
    try
        handles = guidata(src);
        coordinate = get(handles.axes1, 'CurrentPoint');
        mButton = get(handles.figure1, 'SelectionType');
        
        if strcmp(mButton, 'normal')
            % Left click - add point
            plot(coordinate(1,1), coordinate(1,2), 'r*')
            plot(coordinate(1,1), coordinate(1,2), 'go', 'MarkerSize', 6)
            plot(coordinate(1,1), coordinate(1,2), 'mo', 'MarkerSize', 9)
            plot(coordinate(1,1), coordinate(1,2), 'yo', 'MarkerSize', 9)
            
            % Store point data
            pointFlag(pointFlag(1).count+1).xy = [coordinate(1,1); coordinate(1,2); 0];
            posx = getPos(0, 'X');
            posy = getPos(0, 'Y');
            posz = getPos(0, 'Z');
            
            text(coordinate(1,1)+15, coordinate(1,2)+15, ['z(steps) = ' num2str(posz)])
            [xg, xii] = global_xy([posx posy], [coordinate(1,1); coordinate(1,2)], handles, 5);
            
            % Store comprehensive point information
            pointFlag(pointFlag(1).count+1).xyg = xg;
            pointFlag(pointFlag(1).count+1).z = posz;
            pointFlag(pointFlag(1).count+1).ztop = str2num(get(handles.myData.zTopObject, 'String'));
            pointFlag(pointFlag(1).count+1).zbottom = str2num(get(handles.myData.zBottomObject, 'String'));
            pointFlag(pointFlag(1).count+1).z_u_per_s = handles.myData.z_u_per_s;
            pointFlag(pointFlag(1).count+1).disector_h = str2double(get(handles.myData.disector_h_obj, 'String'));
            pointFlag(pointFlag(1).count+1).k_factor = str2double(get(handles.myData.disector_K_obj, 'String'));
            
            % Save screenshot of marked point
            stereoFile = ['stereoArray_' get(handles.myData.Name_Obj, 'String')];
            stereoFile_base = stereoFile(1:(end-4));
            if ~exist(['I:\stacks\' stereoFile_base])
                eval(['!mkdir I:\stacks\' stereoFile_base])
            end
            
            frame = getframe(gcf);
            stackNum = length(dir([fullfile('I:\stacks\', stereoFile_base) '\*.png'])) + 1;
            stack = frame.cdata(56:961, 271:1402, :);
            imwrite(stack, [fullfile('I:\stacks\', stereoFile_base) '\' num2str(stackNum) '.png'])
            pointFlag(1).count = pointFlag(1).count + 1;
            
        elseif strcmp(mButton, 'alt')
            % Right click - remove last point
            plot(coordinate(1,1), coordinate(1,2), 'g*')
            pointFlag(1).count = max(0, pointFlag(1).count - 1);
            pointFlag = pointFlag(1:pointFlag(1).count+1);
            
        else
            % Middle click or other - finish counting
            pointFlag(1).count = pointFlag(1).count + 1;
            plot(coordinate(1,1), coordinate(1,2), 'ys');
            pointFlag(1).count = -1;
        end
        
    catch
        keyboard
    end
end

