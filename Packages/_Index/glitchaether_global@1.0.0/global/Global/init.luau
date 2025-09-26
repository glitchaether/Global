local RunService = game:GetService('RunService')

if RunService:IsServer() then
	return require(script.GlobalServer)
else
	return require(script.GlobalClient)
end