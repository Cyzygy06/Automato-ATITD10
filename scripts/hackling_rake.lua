dofile("common.inc");

do_click_refresh = 1;
do_click_refresh_when_end_red = 1;
improved_rake = 0;
num_flax = 0;
num_loops = 0;
per_rake = 10;
repairAttempt = 0;


function promptRakeNumbers()
	scale = 0.8;
	local z = 0;
	local is_done = nil;
	local value = nil;
	-- Edit box and text display
	while not is_done do
		-- Put these everywhere to make sure we don't lock up with no easy way to escape!
		checkBreak("disallow pause");

		lsPrint(10, 10, z, scale, scale, 0xFFFFFFff, "Hackling Raking Setup");

		-- lsEditBox needs a key to uniquely name this edit box
		--   let's just use the prompt!
		-- lsEditBox returns two different things (a state and a value)
		local y = 40;
		lsPrint(5, y, z, scale, scale, 0xFFFFFFff, "How much flax: ");
		is_done, num_flax = lsEditBox("passes",
			160, y, z, 70, 30, scale, scale,
			0x000000ff, 1);
		if not tonumber(num_flax) then
			is_done = nil;
			lsPrint(5, y+18, z+10, 0.7, 0.7, 0xFF2020ff, "MUST BE A NUMBER");
			num_flax = 1;
		end
		y = y + 50;
		improved_rake = CheckBox(10, y, z, 0xFFFFFFff, " Improved Rake", improved_rake);
		lsSetCamera(0,0,lsScreenX/1.0,lsScreenY/1.0);

		if improved_rake then
			per_rake = 30;
		else
			per_rake = 10;
		end

		num_loops = math.floor(num_flax / per_rake);
			if num_loops == 0 then
				num_loops = 1;
			end
		y = y + 32;

		if lsButtonText(10, lsScreenY - 30, z, 100, 0xFFFFFFff, "Next") then
			is_done = 1;
		end

		lsPrintWrapped(10, y, z+10, lsScreenX - 20, 0.7, 0.7, 0xD0D0D0ff, "This will attempt to rake " .. num_flax .. " rotten flax, requiring " .. num_loops .. " cycles.");

		if is_done and (not num_flax) then
			error 'Canceled';
		end

		if lsButtonText(lsScreenX - 110, lsScreenY - 30, z, 100, 0xFFFFFFff, "End script") then
			error "Clicked End Script button";
		end

		lsDoFrame();
		lsSleep(10); -- Sleep just so we don't eat up all the CPU for no reason
	end
end


function doit()
	promptRakeNumbers();
	askForWindow("Pin Hacking Rake or Flax Comb window up and have Rotten Flax in your inventory.\n\nMake sure your rake is showing \"Step 1, Remove Straw\" before starting.\n\nYou MUST have Skills window open and everything from Strength to Perception skill should be visible.\n\nYou can optionally pin 'Eat some Grilled Onion' menu to eat it whenever your endurance is not green.");

	step = 1;
	local task = "";
	local task_text = "";
	local warn_small_font=nil;
	local warn_large_font=nil;
	local loop_count=1;
	local straw = 0;
	local tow = 0;
	local lint = 0;
	local clean = 0;
	local eatTimer = 0;
	local startTime = lsGetTimer();

	checkCurrentStep(); -- Verify what step we're on when you start macro and update.
        if step > 1 then
          delay_loop_count = 1; --If we're starting in the middle of a previous session, then don't advance loop_count (later). Finish up what's already being processed.
	  end

	while num_loops do
		runTimer = lsGetTimer();
		srReadScreen();
		OK = srFindImage("ok.png"); -- If we got an OK popup, this suggests "Your Flax Comb/Hackling Rake has wore out", quit
		foundRepair = srFindImage("repair.png");
		endurance_stat = srFindImage("stats/endurance.png");
		this = srFindImage("ThisIs.png")

		if step == 1 then
			task = srFindImage("rake/separate.png");
			task_text = "Remove Straw";
		elseif step == 2 then
			task = srFindImage("rake/process.png");
			task_text = "Separate Tow";
		elseif step == 3 then
			task = srFindImage("rake/process.png");
			task_text = "Refine the Lint";
		elseif step == 4 then
			task = srFindImage("rake/clean.png");
			task_text = "Clean the Rake";
		end
		
		
		--Task somehow didn't set try and find the next step
		srReadScreen();
		if (task == null) then
		    task = srFindImage("rake/separate.png");
			task_text = "Remove Straw";
			step = 1;
			
			if (task == null) then
			    task = srFindImage("rake/process.png");
			    task_text = "Separate Tow";
				step = 2;
			end
			
			if (task == null) then
			    task = srFindImage("rake/process.png");
			    task_text = "Refine the Lint";
				step = 3;
			end
			
			if (task == null) then
			    task = srFindImage("rake/clean.png");
			    task_text = "Clean the Rake";
				step = 4;
			end
			
		end
		

GUI = "Next Step: " .. step .. "/4 - " .. task_text .. "\n\n----------------------------------------------\n1) Straw Removed: " .. straw .."/" .. num_loops*per_rake .. "\n2) Tow Seperated: " .. tow .. "/" .. num_loops*per_rake .. "\n3) Lint Refined: " .. lint .. "/" .. num_loops*per_rake .. "\n4) Cleanings: " .. clean .. "/" .. num_loops .. "\n----------------------------------------------\n\nFlax Processed: " .. (loop_count-1)*per_rake .. "\nFlax Remaining: " .. (num_loops*per_rake) - straw .. "\nRepair Attempts: " .. repairAttempt .. "\n\nElapsed Time: " .. getElapsedTime(startTime);

		if loop_count > num_loops or OK then
			num_loops = nil;

		elseif foundRepair then
		  repairRake();
			srReadScreen();
			safeClick(this[0], this[1]); -- Refresh window
		  lsSleep(100);
		elseif endurance_stat then
			sleepWithStatus(200, GUI, nil, 0.7, "Waiting on Endurance Timer");
		else
			safeClick(this[0], this[1]);
			lsSleep(100);
			safeClick(task[0], task[1]);
			lsSleep(100);
			if step == 1 then
				straw = straw + per_rake;
			elseif step == 2 then
				tow = tow + per_rake;
			elseif step == 3 then
				lint = lint + per_rake;
			elseif
				step == 4 then
				clean = clean + 1;
				step = 0;
				  if delay_loop_count then  -- We started macro while flax comb was in middle of processing... Finish this up before we advance loop counter (so that we can still process the "How much Flax?" at beginning.
				    delay_loop_count = nil;
				  else
				    loop_count= loop_count +1;
				  end
			end
			step = step + 1;
			sleepWithStatus(100, GUI, nil, 0.7, "Endurance OK - Clicking window(s)");
			clickAllText("This is")
			lsSleep(100);
		end

end

		lsPlaySound("Complete.wav");
		lsMessageBox("Elapsed Time:", getElapsedTime(startTime));
end


function checkCurrentStep()
	srReadScreen();
  findAllImages("ThisIs.png");
  lsSleep(100);
  taskStep1 = findAllImages("rake/separate.png");
  taskStep2 = findAllImages("rake/process.png");
  taskStep3 = findAllImages("rake/process.png");
  taskStep4 = findAllImages("rake/clean.png");
  taskStep5 = findAllImages("repair.png");
  if taskStep1 then
    step = 1;
  elseif taskStep2 then
    step = 2;
  elseif taskStep3 then
    step = 3;
  elseif taskStep4 then
    step = 4;
  elseif taskStep5 then
    step = 1;
  else
    error("Could not find Flax Comb or Hackling Rake menus pinned");
  end
end


function repairRake()
  step = 1;
  lsPlaySound("error.wav");
  repairAttempt = repairAttempt + 1;
  sleepWithStatus(1000, "Attempting to Repair Rake !")
  local repair = srFindImage("repair.png")
  local material;
  local plusButtons;
  local maxButton;

  if repair then
    clickText(repair);
		lsSleep(500);

		srReadScreen();
		local loadMaterials = srFindImage("loadMaterials.png")
    clickText(loadMaterials);

    lsSleep(500);
    srReadScreen();
    plusButtons = findAllImages("plus.png");

	for i=1,#plusButtons do
		local x = plusButtons[i][0];
		local y = plusButtons[i][1];
             srClickMouseNoMove(x, y);

		if i == 1 then
		  material = "Boards";
		elseif i == 2 then
		  material = "Bricks";
		elseif i == 3 then
		  material = "Thorns";
		else
		  material = "What the heck?";
		end

             sleepWithStatus(1000,"Loading " .. material, nil, 0.7);

		srReadScreen();
		OK = srFindImage("ok.png")

		if OK then
		  sleepWithStatus(5000, "You don\'t have any \'" .. material .. "\', Aborting !\n\nClosing Build Menu and Popups ...", nil, 0.7)
		  srClickMouseNoMove(OK[0], OK[1]);
		  srReadScreen();
		  blackX = srFindImage("blackX.png");
		  srClickMouseNoMove(blackX[0], blackX[1]);
		  num_loops = nil;
		  break;

		else -- No OK button, Load Material

		  srReadScreen();
		  maxButton = srFindImage("max.png");
		  if maxButton then
		    srClickMouseNoMove(maxButton[0], maxButton[1]);
		  end

		  sleepWithStatus(1000,"Loaded " .. material, nil, 0.7);
		end -- if OK
	end -- for loop
  end -- if repair
end
