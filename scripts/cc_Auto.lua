dofile("cc_Assist.lua");

askText = "Automatically runs many charcoal hearths or ovens simultaneously.\n\nMake sure this window is in the TOP-RIGHT corner of the screen.\n\nTap Shift (while hovering ATITD window) to continue.";

BEGIN = 1;
WOOD = 2;
WATER = 3;
CLOSE = 4;
OPEN = 5;
FULL = 6;

woodAddedTotal = 0;
waterAddedTotal = 0;

-- Standard mode, teh default, where each oven runs independently
-- Synchronous mode, where one oven is watched, and all receive the same commands
synchronousMode = 0;

function ccMenu()
  local passCount = 1;
  local done = false;
  while not done do
    lsPrint(5, 5, 5, 0.7, 0.7, 0xffffffff, "How many passes?");
    done, passCount = lsEditBox("pass_count", 5, 35, z, 100, 30, 0.7, 0.7, 0x000000ff, passCount);
    synchronousMode = CheckBox(5, 65, 10, 0xd0d0d0ff, " Synchronous Mode", synchronousMode, 0.7, 0.7);
    lsPrint(5, 80, 10, 0.6, 0.6, 0xd0d0d0ff, "    Runs all ovens identically");
    if lsButtonText(5, 110, z, 50, 0xffffffff, "OK") then
      done = true;
    end

    lsDoFrame();
    lsSleep(25);
    checkBreak();
  end

  askForFocus();

  startTime = lsGetTimer();
  for i = 1, passCount do
    woodAdded = 0;
    waterAdded = 0;
    woodx1Click = 0;
    drawWater(1); -- Refill Jugs. The parameter of 1 means don't do the animation countdown. Since we won't be running somewhere, not needed
    lsSleep(100);
    Do_Take_All_Click(); -- Make sure ovens are empty. If a previous run didn't complete and has wood leftover, will cause a popup 'Your oven already has wood' and throw macro off
    runCommand(buttons[1]);
    lsSleep(1500);
    ccRun(i, passCount);
  end

  Do_Take_All_Click(); -- All done, empty ovens
  lsPlaySound("Complete.wav");
  lsMessageBox("Elapsed Time:", getElapsedTime(startTime), 1);
end

function findOvens()
  local result = findAllImages("ThisIs.png");
  for i=1,#result do
    local corner = findImageInWindow("charcoal/mm-corner.png",
                     result[i][0], result[i][1], 100);
    if not corner then
      error("Failed to find corner of cc window.");
    end
    result[i][0] = corner[0];
    result[i][1] = corner[1];
  end
  return result;
end

function setupVents(ovens)
  local result = {};
  for i = 1, #ovens do
    result[i] = 0;
  end
  return result;
end

function findButton(pos, index)
  return findImageInWindow(buttons[index].image, pos[0], pos[1]);
end

function clickButton(pos, index, counter)
  local count = nil;

  if synchronousMode then
    count = runCommand(buttons[index]);
  else
    local buttonPos = findButton(pos, index);
    if buttonPos then
      safeClick(buttonPos[0] + buttons[index].offset[0], buttonPos[1] + buttons[index].offset[1]);
      count = 1;
    end
  end

  if counter ~= nil and count ~= nil then
    if index == 3 then -- Water
      waterAdded = waterAdded + count;
      waterAddedTotal = waterAddedTotal + count;
    end
    if index == 2 then -- Wood
      woodAdded = woodAdded + count;
      woodAddedTotal = woodAddedTotal + count;
    end
  end
end

function ccRun(pass, passCount)
  local ovens = findOvens();
  local vents = setupVents(ovens);
  local done = false;
  while not done do
    sleepWithStatus(500,
      "Waiting on next tick ...\n\n" ..
      "[" .. pass .. "/" .. passCount .. "] Passes\n\n" ..
      "Totals: [This Pass/All Passes]\n\n" ..
      "[".. woodAdded*3 .. "/" .. woodAddedTotal * 3 .. "] Wood Used - Actual\n" ..
      "[" .. woodAdded .. "/" .. woodAddedTotal .. "] 'Add Wood' Button Clicked (x1)\n\n"..
      "[" .. waterAdded .. "/" .. waterAddedTotal .."] Water Used\n" ..
      "             (Excluding cooldown water)\n\n\n" ..
      "Elapsed Time: " .. getElapsedTime(startTime), nil, 0.7);
    done = true;
    srReadScreen();

    local count = #ovens;
    if synchronousMode then
      count = 1;
    end
    for i = 1, count do
      if not findButton(ovens[i], BEGIN) then
        vents[i] = processOven(ovens[i], vents[i]);
        done = false;
      end
    end
  end
end

-- 0% = 56, 100% = 249, each % = 1.94

minHeat = makePoint(199, 15); --80%
minHeatProgress = makePoint(152, 15); --60%
minOxy = makePoint(80, 33); --32%
maxOxy = makePoint(116, 33); --47%
maxOxyLowHeat = makePoint(160, 33); --64%
minWood = makePoint(108, 50); --43%
minWater = makePoint(61, 70); --24%
minWaterGreen = makePoint(96, 70); --39%
maxDangerGreen = makePoint(205, 90); --82%
maxDanger = makePoint(219, 90); --88%
uberDanger = makePoint(228, 90); --92%
progressGreen = makePoint(62, 110); --25%

greenColor = 0x01F901;
barColor = 0x0101F9;

function processOven(oven, vent)
  local newVent = vent;
  if pixelMatch(oven, progressGreen, greenColor, 4) then
    if not pixelMatch(oven, minWaterGreen, barColor, 8) then
      clickButton(oven, WATER);
      clickButton(oven, WATER);
    end

    if pixelMatch(oven, maxDangerGreen, barColor, 4) then
      clickButton(oven, WATER);
    elseif vent ~= 3 then
      newVent = 3;
      clickButton(oven, FULL);
    end
  else
    if not pixelMatch(oven, minHeat, barColor, 8) then
      if not pixelMatch(oven, minWood, barColor, 8) then
        clickButton(oven, WOOD, 1);
      end
    end

    if not pixelMatch(oven, minOxy, barColor , 8) then
      if vent ~= 3 then
        newVent = 3;
        clickButton(oven, FULL);
      end
    else
      local point = maxOxy;
      if not pixelMatch(oven, minHeatProgress, barColor, 8) then
        point = maxOxyLowHeat;
      end
      if pixelMatch(oven, point, barColor, 8) then
        if vent ~= 1 then
          newVent = 1;
          clickButton(oven, CLOSE);
        end
      else
        if vent ~= 2 then
          newVent = 2;
          clickButton(oven, OPEN);
        end
      end
    end

    if pixelMatch(oven, maxDanger, barColor, 8) then
      if not pixelMatch(oven, minWater, barColor, 8) then
        clickButton(oven, WATER, 1);
        if pixelMatch(oven, uberDanger, barColor, 8) then
          clickButton(oven, WATER, 1);
        end
      end
    end
  end

  return newVent;
end

function Do_Take_All_Click()
  statusScreen("Checking / Emptying Ovens ...",nil, 0.7);
  -- refresh windows
  clickAll("ThisIs.png", 1);
  lsSleep(100);

  clickAll("take.png", 1);
  lsSleep(100);

  clickAll("everything.png", 1);
  lsSleep(100);

  -- refresh windows, one last time so we know for sure the machine is empty (Take menu disappears)
  clickAll("ThisIs.png", 1);
  lsSleep(100);
end

function clickAll(image_name)
  -- Find buttons and click them!
  srReadScreen();
  xyWindowSize = srGetWindowSize();
  local buttons = findAllImages(image_name);

  if #buttons == 0 then
    -- statusScreen("Could not find specified buttons...");
    -- lsSleep(1500);
  else
    -- statusScreen("Clicking " .. #buttons .. "button(s)...");
    if up then
      for i=#buttons, 1, -1  do
        srClickMouseNoMove(buttons[i][0]+5, buttons[i][1]+3);
        lsSleep(per_click_delay);
      end
    else
      for i=1, #buttons  do
        srClickMouseNoMove(buttons[i][0]+5, buttons[i][1]+3);
        lsSleep(per_click_delay);
      end
    end
    -- statusScreen("Done clicking (" .. #buttons .. " clicks).");
    -- lsSleep(100);
  end
end
