--[[ 
	pathfinding module
		a totally broken and unoptimized pathfinding module made by me ( v4lentinee )
		supposed to be my 'personal' pathfinding module and won't be publicized but,
		for my portofolio :>
		
	(need to be used on Model and has Humanoid and PrimaryPart set);
]]

local pathfindingService = game:GetService('PathfindingService');

local pathfinding = {};
pathfinding.__index = pathfinding;

-- // path agent params
export type agentParams = {
	AgentRadius: number;
	AgentHeight: number;
	WaypointSpacing: number;
	AgentCanJump: boolean;
	AgentCanClimb: boolean;
	Costs: {[string]: any};
}

-- // CONSTRUCTOR
function pathfinding.new(model: Model?, agentParams: agentParams)
	if not model or not model:IsA('Model') then error('[pathfinding] model is not type of Model'); end;

	local self = setmetatable({}, pathfinding);
	self.model = model;
	self.path = pathfindingService:CreatePath(agentParams or {
		AgentRadius = 5;
		AgentHeight = 2;
		WaypointSpacing = 2;
		AgentCanJump = true;
		AgentCanClimb = true;
		Costs = {};
	});
	
	return self;
end;

-- // create part to visualize waypoint
local function visualizePoint(waypoint: PathWaypoint)
	local part = Instance.new("Part")
	part.Position = waypoint.Position
	part.Size = Vector3.new(0.5, 0.5, 0.5)
	part.Color = Color3.new(1, 0, 1)
	part.Anchored = true;
	part.CanCollide = false;
	part.Parent = workspace;
	
	task.delay(1, function()
		part:Destroy();
	end);
	
	return part;
end;

local function getRandomPart(pathFolder: Folder)
	local getWaypoints = pathFolder:GetChildren();
	local randomPoint = math.random(1, #getWaypoints);
	return getWaypoints[randomPoint];
end

-- // get the path status
function pathfinding:getPathStatus()
	return self.path.Status;
end;

-- // make the agent walk to a SINGLE part
function pathfinding:walkToPoint(finishPosition: Vector3)
	if not finishPosition then error('[pathfinding] finishPosition not provided'); end;
	
	local model: Model? = self.model;
	local humanoid: Humanoid = model:FindFirstChildOfClass('Humanoid');

	if not humanoid then error('[pathfinding] humanoid not found') return; end;
	if model.PrimaryPart == nil then error('[pathfinding] PrimaryPart is not set'); end;

	local success, no = pcall(function()
		self.path:ComputeAsync(model.PrimaryPart.Position, finishPosition);
	end);

	if success then
		if self:getPathStatus() == Enum.PathStatus.Success then
			for i, waypoint in self.path:GetWaypoints() do
				visualizePoint(waypoint);
				humanoid:MoveTo(waypoint.Position);
				humanoid.MoveToFinished:Wait();
			end;
		end;
	else
		error('[pathfinding] compute failed '..tostring(no));
	end;
	
end;

-- // make the agent walk and patroling following paths in a FOLDER
function pathfinding:walkCycle(folder: Folder)
	if not folder or not folder:IsA('Folder') then error('[pathfinding] the container is not provided / not folder'); end;
	
	local model: Model? = self.model;
	local humanoid: Humanoid = model:FindFirstChildOfClass('Humanoid');

	if not humanoid then error('[pathfinding] humanoid not found') return; end;
	if model.PrimaryPart == nil then error('[pathfinding] PrimaryPart is not set'); end;
	
	local waypoints = {};
	for _, child in ipairs(folder:GetChildren()) do
		if child:IsA('BasePart') then
			table.insert(waypoints, child);
		end;
	end;
	
	if #waypoints == 0 then error('[pathfinding] no waypoint in table'); end;

	while true do
		local waypoint = getRandomPart(folder);
		
		self:walkToPoint(waypoint.Position);
		task.wait();
	end;
end;

return pathfinding;
