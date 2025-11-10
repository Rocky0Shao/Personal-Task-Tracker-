function crossy_road_test()
% CROSSY-QUEEN: minimal Crossy-Road style using simpleGameEngine
% Converted to a function with nested helpers so it runs in MATLAB.

% --- SPRITE IDs: set these to your sheet -------------------------------
BLANK = 1;                  % background tile
GRASS = 6;                  % safe lane
ROAD  = 9;                  % road lane
GOAL  = 1;                  % goal row at top
CAR_L = 32*3 + 31;          % car facing left
CAR_R = 32*3 + 31;          % car facing right
QUEEN = 32*3 + 30;          % your queen index from before
% -----------------------------------------------------------------------

% Scene config
ROWS = 18; COLS = 32;
cinScene = simpleGameEngine("retro_pack.png",16,16,5,[0,0,0]);

% Lane spec: each row has a type and speed (cells per tick). Positive => right.
% Top row is GOAL, bottom row is GRASS start
laneType = strings(ROWS,1);
laneSpd  = zeros(ROWS,1);

laneType(1)    = "goal";
laneType(ROWS) = "grass";
laneSpd(ROWS)  = 0;

% Build middle lanes alternating GRASS and ROAD with varying speeds
rng(1);  % deterministic
for r = 2:ROWS-1
    if mod(r,2)==0
        laneType(r) = "road";
        laneSpd(r)  = 1 * (-1)^(r);  % 1 cell/tick, flip direction
    else
        laneType(r) = "grass";
        laneSpd(r)  = 0;
    end
end

% Obstacles: for each road row keep a logical occupancy vector
cars = false(ROWS, COLS);
carDensity = 0.18;  % fraction of columns initially filled with cars on road lanes
for r = 1:ROWS
    if laneType(r)=="road"
        cars(r, :) = rand(1,COLS) < carDensity;
        % avoid full walls
        if all(~cars(r,:)), cars(r, randi(COLS)) = true; end
    end
end

% Player state
pi = ROWS; pj = round(COLS/2);
bestRow = pi;    % for score
level   = 1;

% Initialize first frame
drawFrame();

% Game loop
targetFPS = 60;
tick = 0;
running = true;
set(cinScene.my_figure,'Renderer','opengl','GraphicsSmoothing','off');

while running && isvalid(cinScene.my_figure)
    tic;
    tick = tick + 1;

    % --- INPUT ---
    key = pollKey();
    if strcmp(key,'escape'), close(cinScene.my_figure); break; end
    if strcmp(key,'uparrow')   && pi>1,   pi = pi-1; end
    if strcmp(key,'downarrow') && pi<ROWS, pi = pi+1; end
    if strcmp(key,'leftarrow') && pj>1,   pj = pj-1; end
    if strcmp(key,'rightarrow')&& pj<COLS, pj = pj+1; end

    % --- UPDATE WORLD ---
    % move obstacles every tick
    if mod(tick,2)==0
        stepCars();
    end
    % track best progress
    if pi < bestRow, bestRow = pi; end

    % collisions: car on road
    if laneType(pi)=="road" && cars(pi,pj)
        % death: reset to start, keep level
        pi = ROWS; pj = round(COLS/2); bestRow = pi;
    end

    % reached goal
    if laneType(pi)=="goal"
        resetPlayer(true);
    end

    % --- RENDER ---
    drawFrame();

    % --- TIMING ---
    elapsed = toc;
    pause(max(0, 1/targetFPS - elapsed));
end

% --- Nested helper functions ---
    function drawFrame()
        bg = BLANK*ones(ROWS,COLS);
        for rr = 1:ROWS
            if laneType(rr)=="grass", bg(rr,:) = GRASS; end
            if laneType(rr)=="road",  bg(rr,:) = ROAD;  end
            if laneType(rr)=="goal",  bg(rr,:) = GOAL;  end
        end
        % choose car sprite by lane direction
        fg = BLANK*ones(ROWS,COLS);
        for rr = 1:ROWS
            if laneType(rr)=="road"
                fg(rr, cars(rr,:)&(laneSpd(rr)<0)) = CAR_L;
                fg(rr, cars(rr,:)&(laneSpd(rr)>0)) = CAR_R;
            end
        end
        fg(pi,pj) = QUEEN;
        drawScene(cinScene, bg, fg);
        drawnow limitrate nocallbacks
    end

    % Non-blocking key poll using guidata written by SGE's KeyPressFcn
    function key = pollKey()
        k = guidata(cinScene.my_figure);
        if isempty(k) || isequal(k,0), key = ''; else, key = k; end
        guidata(cinScene.my_figure, 0);  % consume
    end

    % Move cars one step with wrap-around
    function stepCars()
        for rr = 1:ROWS
            s = laneSpd(rr);
            if s==0, continue; end
            if s > 0
                for kk = 1:s
                    cars(rr,:) = [cars(rr,end), cars(rr,1:end-1)];
                end
            else
                for kk = 1:(-s)
                    cars(rr,:) = [cars(rr,2:end), cars(rr,1)];
                end
            end
        end
    end

    % Reset player to start and optionally increase difficulty
    function resetPlayer(success)
        if success
            level = level + 1; %#ok<NASGU>
            % increase speeds slightly
            for rr = 2:ROWS-1
                if laneType(rr)=="road"
                    laneSpd(rr) = sign(laneSpd(rr)) * 1;
                end
            end
        end
        pi = ROWS; pj = round(COLS/2);
        bestRow = pi; %#ok<NASGU>
    end

end


