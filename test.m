clc
clear
close all

%% Example showing playing card faces on a grey background
card_scene1 = simpleGameEngine('retro_cards.png', 16, 16, 5, [207,198,184]);
drawScene(card_scene1,[21:33;34:46;47:59;60:72])

%% Example showing how to use two layers
% the first layer has blank cards and card backs
% the second layer has numbers and card faces
card_scene2 = simpleGameEngine('retro_cards.png', 16, 16, 10, [0,200,0]);
bg = [1 2 3 4 5 6 7 8 9 10
      1 2 2 2 2 2 2 2 2 2];
fg = [1,  12:20
      11, 21:6:74];
drawScene(card_scene2,bg,fg)

%% Example using the simple dice sprite sheet
simple_dice_scene = simpleGameEngine('retro_simple_dice.png', 16, 16, 10, [0,0,0]);
drawScene(simple_dice_scene,[1 2 3 4 5 6 7 8 9 10])

%% Example using the dice sprite sheet, which allows dice of different colors
dice_scene = simpleGameEngine('retro_dice.png', 16, 16, 10, [0,0,0]);
drawScene(dice_scene,[1 2 3 4 5 6 7 8 9 10],[1,11:19])

%% Example of user input from mouse, then keyboard
[r,c,b] = getMouseInput(card_scene1)
k = getKeyboardInput(simple_dice_scene)
