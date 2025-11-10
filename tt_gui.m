function tt_gui
% Brain-simple task tracker GUI. Run: tt_gui
store = fullfile(pwd,'tasks.mat');

% load or init
if isfile(store)
    S = load(store,'T'); T = S.T;
else
    T = table(int32([]), string([]), double([]), false(0,1), datetime.empty(0,1), ...
        'VariableNames', {'ID','Task','Minutes','Done','Created'});
    save(store,'T');
end

% ui
f = uifigure('Name','Tasks','Position',[100 100 600 360]);
gl = uigridlayout(f,[3 1]); 
gl.RowHeight = {48,'1x',48};            % <-- fix: RowHeight (singular)

row = uigridlayout(gl,[1 6]); 
row.ColumnWidth = {220,80,80,80,80,'1x'};
name = uieditfield(row,'text','Placeholder','task name');
mins = uieditfield(row,'numeric','Limits',[0 Inf],'RoundFractionalValues','on');
mins.ValueDisplayFormat = '%.0f'; mins.Value = 30;
uibutton(row,'Text','Add','ButtonPushedFcn',@onAdd);
uibutton(row,'Text','Delete sel','ButtonPushedFcn',@onDelete);
uicheckbox(row,'Text','Hide done','ValueChangedFcn',@refresh,'Tag','hide');
uibutton(row,'Text','Clear all','ButtonPushedFcn',@onClear);

tbl = uitable(gl,'Data',T, ...
    'ColumnEditable',[false true true true false]);
tbl.ColumnName = {'ID','Task','Minutes','Done','Created'};
tbl.Tag = 'table';
% Some versions don't have Multiselect; selection still works.
if isprop(tbl,'DisplayDataChangedFcn')
    tbl.DisplayDataChangedFcn = @onEditDD;   % new-ish MATLAB
else
    tbl.CellEditCallback = @onCellEdit;      % fallback
end

footer = uigridlayout(gl,[1 4]); 
footer.ColumnWidth = {'1x',120,120,120};
lbl = uilabel(footer,'Text',summaryText(T));
uibutton(footer,'Text','Save now','ButtonPushedFcn',@(~,~)saveNow());
uibutton(footer,'Text','Mark done','ButtonPushedFcn',@onMarkDone);
uibutton(footer,'Text','Mark undone','ButtonPushedFcn',@onMarkUndone);

refresh();

% --- callbacks
    function onAdd(~,~)
        desc = strtrim(name.Value);
        dur  = mins.Value;
        if desc == "" || ~isfinite(dur) || dur<0, return; end
        nextID = int32(1); if ~isempty(T), nextID = int32(max(T.ID)+1); end
        T = [T; {nextID, string(desc), double(round(dur)), false, datetime('now')}];
        saveNow(); name.Value = ""; refresh();
    end

    function onDelete(~,~)
        idx = selectedRows();
        if isempty(idx), return; end
        T(idx,:) = [];
        saveNow(); refresh();
    end

    function onClear(~,~)
        T(:,:) = [];
        saveNow(); refresh();
    end

    function onMarkDone(~,~)
        idx = selectedRows(); if isempty(idx), return; end
        T.Done(idx) = true; saveNow(); refresh();
    end

    function onMarkUndone(~,~)
        idx = selectedRows(); if isempty(idx), return; end
        T.Done(idx) = false; saveNow(); refresh();
    end

    % Callback for newer MATLAB where DisplayDataChangedFcn exists
    function onEditDD(src,~)
        DT = src.DisplayData;
        for k = 1:height(DT)
            id = DT.ID(k);
            ii = find(T.ID==id,1);
            if ~isempty(ii)
                T.Task(ii)    = string(DT.Task(k));
                T.Minutes(ii) = double(DT.Minutes(k));
                T.Done(ii)    = logical(DT.Done(k));
            end
        end
        saveNow();
        lbl.Text = summaryText(T);
    end

    % Fallback for older MATLAB using CellEditCallback
    function onCellEdit(~,evt)
        if isempty(evt.Indices), return; end
        r = evt.Indices(1); c = evt.Indices(2);
        vis = tbl.Data; id = vis.ID(r);
        ii = find(T.ID==id,1);
        if isempty(ii), return; end
        switch c
            case 2, T.Task(ii)    = string(evt.NewData);
            case 3, T.Minutes(ii) = double(evt.NewData);
            case 4, T.Done(ii)    = logical(evt.NewData);
        end
        saveNow();
        lbl.Text = summaryText(T);
    end

% --- helpers
    function idx = selectedRows()
        sel = tbl.Selection;        % available in most releases
        if isempty(sel), idx = []; return; end
        r = unique(sel(:,1));
        vis = tbl.DisplayData;      % if older MATLAB lacks DisplayData, Data works the same here
        if isempty(vis), vis = tbl.Data; end
        ids = vis.ID(r);
        idx = arrayfun(@(id)find(T.ID==id,1), ids);
    end

    function refresh(~,~)
        hideDone = findobj(f,'Tag','hide').Value;
        Ts = T;
        if hideDone, Ts = Ts(~Ts.Done,:); end
        if ~isempty(Ts)
            Ts = sortrows(Ts, {'Done','Created','ID'});
        end
        tbl.Data = Ts;
        lbl.Text = summaryText(T);
    end

    function saveNow()
        save(store,'T');
    end

    function s = summaryText(Tab)
        total = height(Tab);
        doneN = sum(Tab.Done);
        todoN = total - doneN;
        minsTodo = sum(Tab.Minutes(~Tab.Done));
        s = sprintf('Total %d | Todo %d | Done %d | Todo minutes %d', ...
            total,todoN,doneN,round(minsTodo));
    end
end
