% === simpleGameEngine task UI with per-row icons ===

% Config
ICON_ID = 10;                 % pick a sprite index from retro_pack.png
ROW_GAP_TILES = 4;            % row spacing

% Scene
card_scene = simpleGameEngine('retro_pack.png',16,16,4,[255,255,255]);

% Background (100x100 tiles, sprite #1)
bg = ones(100,100);

% App state
drawScene(card_scene,bg);
fig = card_scene.my_figure;
setappdata(fig,'bg',bg);
setappdata(fig,'tasks',{});                  % cell array of task names
setappdata(fig,'iconId',ICON_ID);
setappdata(fig,'rowGap',ROW_GAP_TILES);
drawTaskList(card_scene, getappdata(fig,'tasks'));

% ------------------ keyboard-driven demo sequence ------------------
% 1) wait for key -> populate with 3 random tasks
getKeyboardInput(card_scene);
pool = ["Calibrate sensors","Write lab memo","Refactor parser", ...
        "Email TA","Review PR #42","Test waypoint filter","Plan demo"];
idx = randperm(numel(pool),3);
tasks = cellstr(pool(idx));
setappdata(fig,'tasks',tasks);
drawScene(card_scene,bg); drawTaskList(card_scene,tasks);

% 2) wait for key -> delete a task (last if any)
getKeyboardInput(card_scene);
tasks = getappdata(fig,'tasks');
if ~isempty(tasks)
    tasks(end) = [];
    setappdata(fig,'tasks',tasks);
    drawScene(card_scene,bg); drawTaskList(card_scene,tasks);
end

% 3) wait for key -> add one task
getKeyboardInput(card_scene);
tasks = getappdata(fig,'tasks');
tasks{end+1} = sprintf('Another Important Thing', numel(tasks)+1);
setappdata(fig,'tasks',tasks);
drawScene(card_scene,bg); drawTaskList(card_scene,tasks);
% -------------------------------------------------------------------

% UI strip at bottom
createTaskUI(card_scene);

% ===================== UI + Callbacks =====================

function createTaskUI(sge)
    fig = sge.my_figure;

    figPos = getpixelposition(fig);
    h = 44; pad = 8;
    pnl = uipanel('Parent',fig,'Units','pixels', ...
        'Position',[pad pad figPos(3)-2*pad h], ...
        'BackgroundColor',[0.96 0.96 0.96], 'BorderType','line');

    % edit field
    edt = uicontrol(pnl,'Style','edit','Units','pixels', ...
        'Position',[10 8 figPos(3)-260 28], 'FontName','Consolas', ...
        'HorizontalAlignment','left','String','');
    setappdata(fig,'edt',edt);

    % Add
    uicontrol(pnl,'Style','pushbutton','Units','pixels','String','Add', ...
        'Position',[figPos(3)-240 8 90 28], ...
        'Callback',@(src,~) cbAdd(src,sge));

    % Delete selected
    uicontrol(pnl,'Style','pushbutton','Units','pixels','String','Delete selected', ...
        'Position',[figPos(3)-140 8 110 28], ...
        'Callback',@(src,~) cbDeleteSelected(src,sge));
end

function cbAdd(src,sge)
    fig = ancestor(src,'figure');
    edt = getappdata(fig,'edt');
    name = strtrim(get(edt,'String'));
    if isempty(name), return; end

    tasks = getappdata(fig,'tasks');
    name = ensureUnique(name,tasks);
    tasks{end+1} = name; %#ok<AGROW>
    setappdata(fig,'tasks',tasks);
    set(edt,'String','');

    bg = getappdata(fig,'bg');
    drawScene(sge,bg);
    drawTaskList(sge,tasks);
end

function cbDeleteSelected(src,sge)
    fig   = ancestor(src,'figure');
    tasks = getappdata(fig,'tasks');
    if isempty(tasks), return; end

    idx = pickTaskIndex(sge,tasks);
    if idx==0, return; end

    tasks(idx) = [];
    setappdata(fig,'tasks',tasks);

    bg = getappdata(fig,'bg');
    drawScene(sge,bg);
    drawTaskList(sge,tasks);
end

% ===================== Rendering =====================

function drawTaskList(sge,tasks,selectedIdx)
    if nargin<3, selectedIdx = 0; end
    [ax, tw, th] = sgeAxesAndTileSize(sge);

    % clear prior overlays
    delete(findall(ax,'Type','text'));
    delete(findall(ax,'Type','rectangle'));
    delete(findall(ax,'Type','image','Tag','sge-sprite')); % clear row icons

    startRow  = 5;                 % list top row
    startCol  = 5;                 % text left col
    iconCol   = startCol-1;        % icon sits one tile left of text
    stepTiles = getappdata(sge.my_figure,'rowGap');

    hold(ax,'on');
    drawTextTile(sge,'Tasks:', startRow-2, startCol, 'FontWeight','bold');

    iconId = getappdata(sge.my_figure,'iconId');

    for i = 1:numel(tasks)
        row = startRow + (i-1)*stepTiles;

        % background strip
        y  = (row-1)*th;
        x  = (iconCol-1)*tw;       % include icon column
        w  = 26*tw;                % width in tiles; adjust as needed
        h  = 1.1*th;
        if i==selectedIdx
            face = [.95 .95 1];
        else
            face = [1 1 1];
        end
        rectangle(ax,'Position',[x y w h],'FaceColor',face,'EdgeColor','none');

        % icon sprite in its own tile
        drawSpriteTile(sge, iconId, row, iconCol);

        % text
        label = sprintf('%02d: %s', i, tasks{i});
        drawTextTile(sge,label,row,startCol,'FontSize',14);
    end
    hold(ax,'off');
end

% ===================== Hit-testing =====================

function idx = pickTaskIndex(sge,tasks)
    [row,~,~] = getMouseInput(sge);
    startRow  = 5;
    stepTiles = getappdata(sge.my_figure,'rowGap');
    idx = floor((row - startRow)/stepTiles) + 1;
    if idx < 1 || idx > numel(tasks)
        idx = 0;
    end
end

% ===================== Utilities =====================

function name = ensureUnique(name,tasks)
    if ~any(strcmp(tasks,name)), return; end
    base = name; k = 2;
    while any(strcmp(tasks, sprintf('%s (%d)',base,k)))
        k = k + 1;
    end
    name = sprintf('%s (%d)',base,k);
end

function h = drawTextTile(sge, str, row, col, varargin)
    [ax, tw, th] = sgeAxesAndTileSize(sge);
    x = (col-1)*tw + 2;     % padding inside tile
    y = (row-1)*th + 2;
    h = text(ax, x, y, str, ...
        'Units','data','Color','k','FontName','Consolas','FontSize',14, ...
        'HorizontalAlignment','left','VerticalAlignment','top', ...
        'Interpreter','none','Clipping','off', varargin{:});
end

function drawSpriteTile(sge, spriteId, row, col)
% Blit one sprite into a tile using the sprite's transparency.
    [ax, tw, th] = sgeAxesAndTileSize(sge);
    % sprite image and alpha
    C  = sge.sprites{spriteId};
    A3 = sge.sprites_transparency{spriteId};   % 3-channel alpha 0..255
    % scale to zoom size
    Cbig = imresize(C, sge.zoom, 'nearest');
    Abig = imresize(A3(:,:,1), sge.zoom, 'nearest'); % single channel alpha

    % top-left pixel for this tile
    x = (col-1)*tw;
    y = (row-1)*th;

    % draw as an image with alpha
    image(ax, 'XData', [x x+size(Cbig,2)], 'YData', [y y+size(Cbig,1)], ...
              'CData', Cbig, 'AlphaData', double(Abig)/255, ...
              'Tag','sge-sprite');   % tag so we can delete later
end

function [ax, tw, th] = sgeAxesAndTileSize(sge)
    ax = ancestor(sge.my_image,'axes');
    set(ax,'YDir','reverse');                 % top-left origin
    tw = sge.sprite_width  * sge.zoom;
    th = sge.sprite_height * sge.zoom;
end
