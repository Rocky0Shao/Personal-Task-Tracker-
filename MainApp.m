clc
clear
close all

task_list = {}; % store string task list
keepGoing = true;

% Initialize Scene
main_scene = simpleGameEngine('retro_cards.png', 16, 16, 10, [207,198,184]);

% Initialize visual rows (Starts with one empty row [2,2,2,2,2])
row_space_holder = [1,1,1,1,1]; 
drawScene(main_scene, row_space_holder);

while keepGoing
   
    [task_list, keepGoing, row_space_holder] = updateTask(task_list, main_scene, row_space_holder);
    
    if keepGoing
        clc;
        disp('--- Current Task List ---');
        disp(task_list');
        drawScene(main_scene, row_space_holder);
        disp('Waiting for input... (Left-Click: Add, Right-Click: Delete, Space: Quit)');
    else
        clc;
        disp('Program Ended. Final List:');
        disp(task_list');
        break
    end
end

function [updated_list, keepGoing, new_row_space_holder] = updateTask(current_list, scene, row_space_holder)
    % b=1 (Left Mouse), b=3 (Right Mouse), b=32 (Space)
    disp('(Left-Click) for new task, (Right-Click) to delete task, (Press Space Bar) to quit: ');
    [r,c,b] = getMouseInput(scene);
    new_row_space_holder = row_space_holder;
    updated_list = current_list;
    keepGoing = true;
    
    if b == 1
        % Add task and Add visual row
        updated_list = addTask(current_list);
        new_row_space_holder = addRow(row_space_holder);
        
    elseif b == 3
         % Delete task
         updated_list = deleteTask(current_list);
         
         % Only delete visual row if the list got smaller (task actually deleted)
         if length(updated_list) < length(current_list)
            new_row_space_holder = deleteRow(row_space_holder);
         end
       
    elseif b == 32 % Space Bar (ASCII code 32)
            keepGoing = false;
        
    else
        % Handle invalid input so code doesn't crash
        disp('Invalid option.');
    end
end

function updated_list = addTask(current_list)
     newItem = input('Enter new task name: ', 's');
     updated_list = current_list;
     updated_list{end+1} = newItem; 
end

function updated_list = deleteTask(current_list)
    task_to_delete = input('Enter the task you want to delete: ', 's');
    
    if ismember(task_to_delete, current_list)
        match_index = strcmp(current_list, task_to_delete);
        current_list(match_index) = []; 
        updated_list = current_list;
        disp('Task deleted.');
    else
        disp('Task does not exist.');
        updated_list = current_list;
    end
end

function newToDo = addRow(row_space_holder)
    % Add a new row of [2,2,2,2,2] to the bottom of the matrix
    newRow = [2, 2, 2, 2, 2];
    newToDo = [row_space_holder; newRow];
end

function new_row_space_holder = deleteRow(row_space_holder)
    % Remove the last row if the matrix is not empty
    if ~isempty(row_space_holder)
        row_space_holder(end, :) = [];
    end
    new_row_space_holder = row_space_holder;
end