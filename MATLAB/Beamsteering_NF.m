function beamsteering
close all
clear 
% Predefined theta and phi values (64 combinations)
    thetaCombinations = [0,linspace(10,60,6),linspace(3,60,20),flip(linspace(10,60,6)),linspace(20,60,5),linspace(3,60,20),linspace(20,60,5),0];
    phiCombinations = [0,linspace(0,75,6),repmat(90,1,20),linspace(105,180,6),linspace(195,255,5),repmat(270,1,20),linspace(285,345,5),0];

% Main figure setup
fig = figure('Position', [200, 200, 800, 600], 'Name', 'Beam Steering Control Panel', ...
             'NumberTitle', 'off', 'MenuBar', 'none', 'Color', [0.8 0.8 0.8]);

% Panels
controlPanel = uipanel(fig, 'Title', 'Controls', 'FontSize', 12, 'BackgroundColor', [0.9 0.9 0.9], ...
                        'Position', [0.02, 0.1, 0.96, 0.85]);
statusPanel = uipanel(fig, 'Title', 'Status', 'FontSize', 12, 'BackgroundColor', [0.9 0.9 0.9], ...
                       'Position', [0.02, 0.02, 0.96, 0.08]);

% Theta and Phi input fields using Unicode for Greek characters
uicontrol('Parent', controlPanel, 'Style', 'text', 'String', 'θ (Theta):', ...
          'Position', [10, 460, 100, 25], 'FontSize', 12, 'BackgroundColor', [0.9 0.9 0.9]);
thetaBox = uicontrol('Parent', controlPanel, 'Style', 'edit', 'String', '0', ...
          'Position', [115, 460, 50, 25], 'FontSize', 12);

uicontrol('Parent', controlPanel, 'Style', 'text', 'String', 'φ (Phi):', ...
          'Position', [10, 420, 100, 25], 'FontSize', 12, 'BackgroundColor', [0.9 0.9 0.9]);
phiBox = uicontrol('Parent', controlPanel, 'Style', 'edit', 'String', '0', ...
          'Position', [115, 420, 50, 25], 'FontSize', 12);





% Communication Settings
uicontrol('Parent', controlPanel, 'Style', 'text', 'String', 'Port Name:', ...
          'Position', [200, 300, 100, 25], 'FontSize', 12, 'BackgroundColor', [0.9 0.9 0.9]);
portTextBox = uicontrol('Parent', controlPanel, 'Style', 'edit', 'String', 'COM1', ...
          'Position', [310, 300, 120, 25], 'FontSize', 12);

uicontrol('Parent', controlPanel, 'Style', 'text', 'String', 'Delay (ms):', ...
          'Position', [200, 260, 100, 25], 'FontSize', 12, 'BackgroundColor', [0.9 0.9 0.9]);
delayBox = uicontrol('Parent', controlPanel, 'Style', 'edit', 'String', '10', ...
          'Position', [310, 260, 50, 25], 'FontSize', 12);

uicontrol('Parent', controlPanel, 'Style', 'text', 'String', 'Baud Rate:', ...
          'Position', [200, 220, 100, 25], 'FontSize', 12, 'BackgroundColor', [0.9 0.9 0.9]);
baudRateBox = uicontrol('Parent', controlPanel, 'Style', 'edit', 'String', '9600', ...
          'Position', [310, 220, 50, 25], 'FontSize', 12);

uicontrol('Parent', controlPanel, 'Style', 'text', 'String', 'Chunk Size:', ...
          'Position', [200, 180, 100, 25], 'FontSize', 12, 'BackgroundColor', [0.9 0.9 0.9]);
chunkSizeBox = uicontrol('Parent', controlPanel, 'Style', 'edit', 'String', '1', ...
          'Position', [310, 180, 50, 25], 'FontSize', 12);

% Execute Button
executeButton = uicontrol('Parent', controlPanel, 'Style', 'pushbutton', 'String', 'Execute', ...
                          'Position', [650, 30, 120, 40], 'FontSize', 12, 'Callback', @executeButton_Callback, ...
                          'Enable', 'on', 'TooltipString', 'Click to start calculations');

% Status Text
statusText = uicontrol('Parent', statusPanel, 'Style', 'text', 'String', 'Ready', ...
                       'Position', [10, 5, 770, 25], 'FontSize', 12, 'BackgroundColor', [0.9 0.9 0.9], ...
                       'HorizontalAlignment', 'left');
% N and M settings adjusted for visibility
uicontrol('Parent', controlPanel, 'Style', 'text', 'String', 'N (Rows):', ...
          'Position', [10, 150, 90, 25], 'FontSize', 12, 'BackgroundColor', [0.9 0.9 0.9]);
nBox = uicontrol('Parent', controlPanel, 'Style', 'edit', 'String', '50', ...
          'Position', [105, 150, 50, 25], 'FontSize', 12);

uicontrol('Parent', controlPanel, 'Style', 'text', 'String', 'M (Columns):', ...
          'Position', [10, 100, 100, 25], 'FontSize', 12, 'BackgroundColor', [0.9 0.9 0.9]);
mBox = uicontrol('Parent', controlPanel, 'Style', 'edit', 'String', '37', ...
          'Position', [115, 100, 50, 25], 'FontSize', 12);

% Entering distance to the receiver
uicontrol('Parent', controlPanel, 'Style', 'text', 'String', 'D (Distance):', ...
          'Position', [10, 50, 110, 25], 'FontSize', 12, 'BackgroundColor', [0.9 0.9 0.9]);
r = uicontrol('Parent', controlPanel, 'Style', 'edit', 'String', '2', ...
          'Position', [125, 50, 50, 25], 'FontSize', 12);


% Store components for global access
    setappdata(fig, 'statusText', statusText);
    setappdata(fig, 'executeButton', executeButton);
    setappdata(fig, 'portTextBox', portTextBox);
    setappdata(fig, 'delayBox', delayBox);
    setappdata(fig, 'baudRateBox', baudRateBox);
    setappdata(fig, 'chunkSizeBox', chunkSizeBox);
    setappdata(fig, 'nBox', nBox);
    setappdata(fig, 'mBox', mBox);
    setappdata(fig, 'thetaBox', thetaBox);
    setappdata(fig, 'phiBox', phiBox);
    setappdata(fig, 'r', r);

% Image selector input field
    selectorLabel = uicontrol('Parent', controlPanel, 'Style', 'text', 'String', 'Image Selector (0-63):', ...
              'Position', [10, 350, 150, 45], 'FontSize', 12, 'BackgroundColor', [0.9 0.9 0.9]);
    selectorBox = uicontrol('Parent', controlPanel, 'Style', 'edit', 'String', '0', ...
              'Position', [170, 350, 50, 45], 'FontSize', 12);

    % Button to apply the selected image configuration
    selectButton = uicontrol('Parent', controlPanel, 'Style', 'pushbutton', 'String', 'Apply Selection', ...
              'Position', [230, 350, 120, 45], 'FontSize', 12, 'Callback', @applySelection);
% Send Index Button
sendIndexButton = uicontrol('Parent', controlPanel, 'Style', 'pushbutton', 'String', 'Send Index', ...
                            'Position', [380, 350, 120, 45], 'FontSize', 12, 'Callback', @sendIndexButton_Callback, ...
                            'TooltipString', 'Click to send the index to the serial port');
% Frequency Setting
uicontrol('Parent', controlPanel, 'Style', 'text', 'String', 'Frequency (GHz):', ...
          'Position', [200, 120, 120, 45], 'FontSize', 12, 'BackgroundColor', [0.9 0.9 0.9]);
frequencyBox = uicontrol('Parent', controlPanel, 'Style', 'edit', 'String', '3.5', ...  % Default to 3.5 GHz
          'Position', [330, 120, 80, 45], 'FontSize', 12);

    setappdata(fig, 'frequencyBox', frequencyBox);
    setappdata(fig, 'selectorBox', selectorBox);

% Apply Selection Callback Function
    function applySelection(~, ~)
        % Get the selected index
        index = str2double(get(selectorBox, 'String'));
        %r = str2double(get(r, 'String'));
        % Validate the index
        if isnan(index) || index < 0 || index > 63
            errordlg('Please enter a valid index between 0 and 63.', 'Invalid Index');
            return;
        end
        if r > 12
            errordlg('Please enter a valid distance between 0 and 12.', 'Invalid Index');
            return;
        end

        % Set the theta and phi values based on the selected index
        set(thetaBox, 'String', num2str(thetaCombinations(index + 1)));  % +1 for MATLAB indexing
        set(phiBox, 'String', num2str(phiCombinations(index + 1)));

        % Optionally, update status or execute automatically
        updateStatusText(fig, ['Selected theta: ', get(thetaBox, 'String'), '°, phi: ', get(phiBox, 'String'), '°']);
    end

end

function sendIndexButton_Callback(hObject, ~)
    % Retrieve the COM port name and settings
    fig = ancestor(hObject, 'figure');
    portTextBox = getappdata(fig, 'portTextBox');
    portName = get(portTextBox, 'String');
    Delay = getappdata(fig, 'delayBox');
    Delay = str2double(get(Delay, 'String'));
    Rate = getappdata(fig, 'baudRateBox');
    Rate = str2double(get(Rate, 'String'));
    Size = getappdata(fig, 'chunkSizeBox');
    Size = str2double(get(Size, 'String'));

    % Get the index from the GUI
    selectorBox = getappdata(fig, 'selectorBox');
    index = str2double(get(selectorBox, 'String'));  % Now you can safely use selectorBox
    r = getappdata(fig, 'r');
    r = str2double(get(r, 'String'));
    if isnan(index) || index < 0 || index > 63
        errordlg('Invalid index. Please enter a number between 0 and 63.', 'Error');
        return;
    end
    if r > 12
            errordlg('Please enter a valid distance between 0 and 12.', 'Invalid Index');
            return;
    end
try
    % Example of setting buffer size and timeout
    port = serial(portName, 'BaudRate', Rate, 'Terminator', 'LF', 'Timeout', 10);
    set(port, 'OutputBufferSize', Size);  % Set the buffer size to a suitable value
    % Clearing the buffers
    flushinput(port);  % Clear the input buffer
    flushoutput(port); % Clear the output buffer        fopen(port);
    % Opening the port
    fopen(port);
    disp('Port opened successfully');            % Attempt to create a serial port object
     % if ~isempty(instrfind('sp', portName))
     %     fclose(instrfind('sp', portName)); % Close ports that were previously opened
     % end
       
    % Write the index to the serial port
    %write(port, 'Test Command', 'string');  % Adjust command as per your device
    fwrite(port, uint8(index),'uint8');
    pause(Delay * 1e-3); % Pause for the specified delay
        fclose(port);
        delete(port);
        clear port;
    disp(['Index ', num2str(index), ' sent to ', portName]);
    catch e
        disp(['Failed to send index to ', portName, ': ', e.message]);
       
        if exist('port', 'var')
            fclose(port);
            delete(port);
            clear port;
        end
end

    % Send the index to the COM port using serialport
    % try
    %     % Open serial port
    %     sp = serialport(portName, Rate);
    %     set(sp, 'DataBits', 8);
    %     set(sp, 'StopBits', 1);
    %     set(sp, 'Parity', 'none');
    %     set(sp, 'FlowControl', 'none');
    %     set(sp, 'Timeout', 10);
    %     set(sp, 'OutputBufferSize', Size);
    % 
    %     % Write the index to the serial port
    %     write(sp, uint8(index), 'uint8');
    %     pause(Delay * 1e-3);  % Pause for the specified delay
    % 
    %     % Clean up
    %     delete(sp);
    %     clear sp;
    %     disp(['Index ', num2str(index), ' sent to ', portName]);
    % catch e
    %     errordlg(['Failed to send index to ', portName, ': ', e.message], 'Serial Port Error');
    % end
end


% function createAngleButtons(panel, buttonType, symbol, position)
%     btnGroup = uibuttongroup('Parent', panel, 'Title', [buttonType ' Selection'], 'FontSize', 12, ...
%                              'BackgroundColor', [0.9 0.9 0.9], 'Position', position);
%     if strcmp(buttonType, 'Phi')
%         angles = [0,30,45,60,90,135,180,225,270,315];  % Extended range for Phi
%     else
%         angles = 0:10:90;   % Standard range for Theta
%     end
%     for i = 1:length(angles)
%         angle = angles(i);
%         uicontrol('Parent', btnGroup, 'Style', 'togglebutton', 'String', [symbol, ' = ', num2str(angle)], ...
%                   'Position', [10, 290 - 20 * i, 120, 20], 'FontSize', 10, ...
%                   'Callback', {@angleButton_Callback, buttonType, angle});
%     end
% end

function angleButton_Callback(src, ~, buttonType, angle)
    fig = ancestor(src, 'figure');
    updateStatusText(fig, ['Selected ', buttonType, ': ', num2str(angle), ' degrees']);
    setappdata(fig, [lower(buttonType) 'Value'], angle);
    enableExecuteButton(fig);
end

function enableExecuteButton(fig)
    theta = getappdata(fig, 'thetaValue');
    phi = getappdata(fig, 'phiValue');
    executeButton = getappdata(fig, 'executeButton');
    if ~isempty(theta) && ~isempty(phi)
        set(executeButton, 'Enable', 'on');
    else
        set(executeButton, 'Enable', 'off');
    end
end

function executeButton_Callback(~, ~)
    fig = gcf;
    % Retrieve values from input boxes using appdata
    thetaBox = getappdata(fig, 'thetaBox');
    phiBox = getappdata(fig, 'phiBox');
    frequencyBox = getappdata(fig, 'frequencyBox');  % Retrieve the handle first

    frequency = str2double(get(frequencyBox, 'String'));  % Retrieve frequency from the box

    theta = str2double(get(thetaBox, 'String'));  % Convert input from string to double
    phi = str2double(get(phiBox, 'String'));  % Convert input from string to double

    % Remaining GUI elements retrieval
    portTextBox = getappdata(fig, 'portTextBox');
    portName = get(portTextBox, 'String');
    
    nBox = getappdata(fig, 'nBox');
    mBox = getappdata(fig, 'mBox');
    N = str2double(get(nBox, 'String'));
    M = str2double(get(mBox, 'String'));
    
    r = getappdata(fig, 'r');  % distance
    r = str2double(get(r, 'String'));
    
    delayBox = getappdata(fig, 'delayBox');
    Delay = str2double(get(delayBox, 'String'));
    baudRateBox = getappdata(fig, 'baudRateBox');
    Rate = str2double(get(baudRateBox, 'String'));
    chunkSizeBox = getappdata(fig, 'chunkSizeBox');
    Size = str2double(get(chunkSizeBox, 'String'));

    selectorBox = getappdata(fig, 'selectorBox');  % Retrieve the handle of selectorBox
    index = str2double(get(selectorBox, 'String'));  % Now you can safely use selectorBox
    updateStatusText(fig, 'Executing calculation...');
    calculate(theta, phi, portName, Delay, Rate, Size, N, M,frequency,index,r);  % Ensure the calculate function uses this portName
    updateStatusText(fig, 'Calculation completed.');
end

function calculate(theta, phi, portName, Delay, Rate, Size, N, M, frequency, index, r)
    % Constants
    c = 299792458;                 % Speed of light (m/s)
    f = frequency * 1e9;           % Frequency (Hz)
    lambda = c / f;                % Wavelength (m)
    k = 2 * pi / lambda;           % Wavenumber
    dist = r;                      % UE range (m)
    D = 0.4;                       % RIS aperture diameter (m)
    offset_coeff = (pi * D^2) / (4 * lambda);   % (π D^2)/(4 λ)

    % Phase quantization (10-bit example)
    nbits = 10;
    E = 2 * pi / 2^nbits * linspace(0, 2^nbits - 1, 2^nbits);
    E(end + 1) = 2 * pi;           % include wrap point

    % Angles (Rx from UI; Tx assumed normal incidence)
    thetaR = deg2rad(theta);
    phiR   = deg2rad(phi);
    thetaI = 0;                     % θ_i = 0
    phiI   = 0;

    % Element spacing
    du = 11.30e-3; % meters

    % RIS grid indices aligned from (0,0) like your original code
    %jx = 0:(N-1);
    %iy = 0:(M-1);

    % Physical coordinates (z=0 plane)
    %[xg, yg] = meshgrid(jx*du, iy*du);
    jx = (0:N-1) - (N-1)/2;                   % 1xN
    iy = (0:M-1) - (M-1)/2;                   % 1xM
    [xg, yg] = meshgrid(jx*du, iy*du);        % MxN grids (x along columns, y along rows)

    % Transmitter (BS) and Receiver (UE) positions
    dist_tx = 12;                   % BS range (m)
    %P_TX = [0, 0, dist_tx];         % BS directly above origin
    
    cos2_theta_i = 1;               % θ_i = 0  ⇒ cos^2 θ_i = 1
    cos2_theta_r = cos(thetaR)^2;   % θ_r = theta (UI)
    offset = offset_coeff .* (cos2_theta_i ./ dist_tx + cos2_theta_r ./ r);
    
    d_focal = [0, 0, offset];
    P_RX = dist * [cos(phiR)*sin(thetaR), sin(phiR)*sin(thetaR), cos(thetaR)];


    % Distances per element
    d_TX = sqrt((xg - d_focal(1)).^2 + (yg - d_focal(2)).^2 + (0 - d_focal(3)).^2);
    d_RX = sqrt((P_RX(1) - xg).^2 + (P_RX(2) - yg).^2 + (P_RX(3) - 0).^2);

    % Phase per element: LaTeX Eq. (NF)
    Psi = -k .* (d_TX + d_RX); 
         % + offset_coeff .* (cos2_theta_i ./ d_TX + cos2_theta_r ./ d_RX);

    % Wrap to [0, 2π)
    Psi = mod(Psi, 2*pi);

    % Quantize
    B = zeros(M, N);
    for i = 1:M
        for j = 1:N
            [~, pidx] = min(abs(E - Psi(i,j)));
            B(i,j) = E(pidx);
        end
    end

    % Save / process
    processAndSaveData(B, portName, Delay, Rate, Size, M, N, index);
end


function processAndSaveData(B, portName, Delay, Rate, Size, M, N,index)

    % Reshape and scale the matrix
    B_scaled = round(B * 255 / pi / 2);

    % Define filenames
    filename1 = 'Decimal.xlsx';
    filename2 = 'Characters.xlsx';
    filename3 = 'Hex.xlsx';
    filename4 = 'Voltage.xlsx';
    filename5 = 'phase.xlsx';
    filename6 = 'DAC.xlsx';
    filename7 = 'Hex2.xlsx';
    filename8 = 'portdata.xlsx';



    % Delete existing files if they exist
    if exist(filename1, 'file')
        delete(filename1);
        disp(['Deleted existing file: ', filename1]);
    end
    if exist(filename2, 'file')
        delete(filename2);
        disp(['Deleted existing file: ', filename2]);
    end
    if exist(filename3, 'file')
        delete(filename3);
        disp(['Deleted existing file: ', filename3]);
    end
    if exist(filename4, 'file')
        delete(filename4);
        disp(['Deleted existing file: ', filename4]);
    end
    if exist(filename5, 'file')
        delete(filename5);
        disp(['Deleted existing file: ', filename5]);
    end
    if exist(filename6, 'file')
        delete(filename6);
        disp(['Deleted existing file: ', filename6]);
    end
    if exist(filename7, 'file')
        delete(filename7);
        disp(['Deleted existing file: ', filename7]);
    end
    if exist(filename8, 'file')
        delete(filename8);
        disp(['Deleted existing file: ', filename8]);
    end

    % Save scaled data to new files
    try
        % Save scaled data as Excel file
        writematrix(B_scaled, filename1);
        disp(['Data written to Excel file: ', filename1]);


        % Convert scaled data to ASCII characters and ensure correct dimensions
        asciiData = arrayfun(@(x) char(x), B_scaled, 'UniformOutput', false);  % Convert each element to character
        writecell(asciiData, filename2);  % asciiData should be MxN cell array directly
        disp(['ASCII data written to Excel file: ', filename2]);

        % Convert scaled data to hexadecimal format and save as Excel
        hexData = dec2hex(B_scaled);
        hexMatrix = reshape(cellstr(hexData), [], N); % Reshape hex data to MxN matrix of cells
        writecell(hexMatrix, filename3);
        disp(['Hexadecimal data written to Excel file: ', filename3]);

        % Convert scaled data to vol format and save as Excel

phasesheet=[-74+360,-76.31+360,-79.95+360,-83.94+360,-92.58+360,-104.29+360,-130.16+360,-154.53+360,-171.46+360,171.43,121.30,103.78,80.83,51.80,36.95,27.70,20.81,15.52,10.01];
Voltsheet=[23,20,18,16,14,12,10,9,8.5,8,7,6.5,6,5,4,3,2,1,0];
phssheet=flip(phasesheet);
vltsheet=flip(Voltsheet);
K=length(vltsheet);
     BD=B*180/pi;
     BV=BD;

for i=1:M
    for j=1:N
        if BD(i,j)<=phssheet(1)+(phssheet(2)-phssheet(1))/2 || BD(i,j)>phssheet(19)+(phssheet(1)+360-phssheet(19))/2
            BV(i,j)=vltsheet(1);
        elseif BD(i,j)<=phssheet(19)+(phssheet(1)+360-phssheet(19))/2 && BD(i,j)>phssheet(18)+(phssheet(19)-phssheet(18))/2
            BV(i,j)=vltsheet(19);
        end
        for k=1:K-2
            if BD(i,j)<=phssheet(k+1)+(phssheet(k+2)-phssheet(k+1))/2 && BD(i,j)>phssheet(k)+(phssheet(k+1)-phssheet(k))/2
            BV(i,j)=vltsheet(k+1);
            end
        end
    end
end

        % Assuming BV contains the voltage values in numeric format
        BV_str = arrayfun(@(x) num2str(x, '%.10f'), BV, 'UniformOutput', false);

        % Write the cell array of strings to Excel
        writecell(BV_str, filename4);
        disp(['Voltage data written to Excel file: ', filename4]);

        writematrix(BD, filename5);
        disp(['Phase data written to Excel file: ', filename5]);


        DAC=B_scaled/255*5;
        writematrix(DAC, filename6);
        disp(['DAC data written to Excel file: ', filename6]);

        % Continue using the numeric data for further calculations
        V_Dec = round(BV * 255 / 23);  % Use the numeric array BV, not the string array BV_str
        HexData = dec2hex(V_Dec);
        hexMatrix = reshape(cellstr(HexData), [], N); % Reshape hex data to MxN matrix of cells
        writecell(hexMatrix, filename7);
        disp(['Hex data written to Excel file: ', filename7]);

        portval=hex2dec(hexMatrix);
        portVal=reshape(portval, [], N);
        PortValue=portVal.';
        portValue=PortValue(:);
        writematrix(portValue, filename8);
        disp(['Port data written to Excel file: ', filename8]);
    catch e
        disp(['Error writing to files: ', e.message]);
    end

    % Send data to serial port if necessary
    sendDataInChunks(portValue, portName, Delay, Rate, Size,index);
    % Display the result
    plotResult(BV);
end


function sendDataInChunks(portValue, portName, Delay, Rate, Size,index)
    try
        port = serial(portName, 'BaudRate', Rate, 'Terminator', 'LF', 'Timeout', 10);
        set(port, 'OutputBufferSize', Size);  % Set the buffer size to a suitable value
        fopen(port);
        disp('Port opened successfully');

         % Convert the index to a string and send it
        %indexStr = num2str(index);
        fwrite(port, uint8(index), 'uint8');  % Ensure index is in a suitable data type
        pause(Delay * 1e-3);  % Optional delay after sending the index

        % Determine the chunk size
        chunkSize = Size;  % Adjust this size based on your OutputBufferSize
        numChunks = ceil(length(portValue) / chunkSize);
        
        for i = 1:numChunks
            startIndex = (i-1) * chunkSize + 1;
            endIndex = min(startIndex + chunkSize - 1, length(portValue));
            fwrite(port, portValue(startIndex:endIndex));
            
            pause(Delay*1e-3);  % 10 ms delay after sending each chunk
        end
        
        fclose(port);
        delete(port);
        clear port;
        disp(['Data sent to port: ', portName]);
    catch e
        disp(['Error with serial port ', portName, ': ', e.message]);
       
        if exist('port', 'var')
            fclose(port);
            delete(port);
            clear port;
        end
    end
end


function plotResult(BV)

    box on;
%    xlabel('Excess Delay (ns)', 'Interpreter', 'latex', 'FontSize', 16);
%    ylabel('Complex Channel Coefficient (dB)', 'Interpreter', 'latex', 'FontSize', 16);
%    title('Voltage Configuration on Metasurface', 'Interpreter', 'latex', 'FontSize', 16);
%    legend('Interpreter', 'latex', 'Location', 'northeast');
%    grid on;
%    set(gca, 'FontSize', 16, 'TickLabelInterpreter', 'latex');

    figure(2), surf(BV); % Plot Phase configuration on the metasurface
    colorbar; % Adds a color bar to the plot for scale reference
    colormap(hsv)
    xlabel('Unit cell on x-axis', 'Interpreter', 'latex', 'FontSize', 16);
    ylabel('Unit cell on y-axis', 'Interpreter', 'latex', 'FontSize', 16);
    title('Voltage Configuration on Metasurface', 'Interpreter', 'latex', 'FontSize', 16);
    grid on;
    set(gca, 'FontSize', 16, 'TickLabelInterpreter', 'latex');
%    title('Voltage Configuration on Metasurface');
    view(0,90)
end


function updateStatusText(fig, message)
    statusText = getappdata(fig, 'statusText');
    set(statusText, 'String', message);
end