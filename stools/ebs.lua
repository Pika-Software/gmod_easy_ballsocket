local constraint_RemoveConstraints = SERVER and constraint.RemoveConstraints
local constraint_AdvBallsocket = SERVER and constraint.AdvBallsocket
local util_IsValidPhysicsObject = util.IsValidPhysicsObject
local undo_AddEntity = SERVER and undo.AddEntity
local undo_SetPlayer = SERVER and undo.SetPlayer
local language_Add = CLIENT and language.Add
local undo_Create = SERVER and undo.Create
local undo_Finish = undo.Finish
local table_Add = table.Add
local IsValid = IsValid
local ipairs = ipairs

TOOL.Category = "Constraints"
TOOL.Name = "Easy Ballsocket"

TOOL.ClientConVar["nocollide"] = 0
TOOL.ClientConVar["axle"] = 0
TOOL.ClientConVar["flex"] = 10

if CLIENT then
    language_Add("tool.ebs.name", "Easy Ballsocket")
    language_Add("tool.ebs.listname", "Easy Ballsocket")
    language_Add("tool.ebs.desc", "Creates An Easy Ballsocket!")
    language_Add("tool.ebs.0", "Click on a wall, prop or ragdoll")
    language_Add("tool.ebs.1", "Now click on something else to attach it to")
    language_Add("tool.ebs.nocollide", "No-Collide entities")
    language_Add("tool.ebs.axle", "Ballsocket for axles")
    language_Add("tool.ebs.flex", "How much the axle can flex in degrees")
    language_Add("Undone_Easy Ballsocket", "Undone Easy Ballsocket")

    function TOOL.BuildCPanel( pnl )
        pnl:AddControl("Header", {
            ["Text"] = "Easy Ballsocket",
            ["Description"] = "#tool.ebs.desc"
        })

        pnl:AddControl("CheckBox", {
            ["Label"] = "#tool.ebs.nocollide",
            ["Description"] = "",
            ["Command"] = "ebs_nocollide"
        })

        pnl:AddControl("CheckBox", {
            ["Label"] = "#tool.ebs.axle",
            ["Description"] = "",
            ["Command"] = "ebs_axle"
        })

        pnl:AddControl("Slider", {
            ["Label"] = "Axle flex in degrees",
            ["Description"] = "",
            ["Type"] = "Integer",
            ["Min"] = "10",
            ["Max"] = "90",
            ["Command"] = "ebs_flex"
        })
    end
end

local dec_const = 0.0001
function TOOL:LeftClick(tr)
    local ent = tr.Entity
    if IsValid(ent) and ent:IsPlayer() then
        return
    end

    if SERVER and not util_IsValidPhysicsObject(ent, tr.PhysicsBone) then
        return false
    end

    local num = self:NumObjects()
    local phys = ent:GetPhysicsObjectNum(tr.PhysicsBone)
    if IsValid( phys ) then
        self:SetObject(num + 1, ent, tr.HitPos, phys, tr.PhysicsBone, tr.HitNormal)
    end

    if (num > 0) then
        if CLIENT then
            return true
        end

        local ent1, ent2 = self:GetEnt(1), self:GetEnt(2)
        if not IsValid( ent1 ) and not IsValid( ent2 ) then
            self:ClearObjects()
            return
        end

        local Bone1, Bone2 = self:GetBone(1), self:GetBone(2)
        local LPos1, LPos2 = self:GetLocalPos(1), self:GetLocalPos(2)

        local nocollide = self:GetClientNumber("nocollide", 0)
        local flex = self:GetClientNumber("flex", 10)

        local const_list = {}
        if (self:GetClientNumber("axle", 0) == 0) then
            table_Add(const_list, { constraint_AdvBallsocket(ent1, ent2, Bone1, Bone2, LPos1, LPos2, 0, 0, -180, -dec_const, -dec_const, 180, dec_const, dec_const, 0, 0, 0, 1, nocollide) })
            table_Add(const_list, { constraint_AdvBallsocket(ent1, ent2, Bone1, Bone2, LPos1, LPos2, 0, 0, -180, dec_const, dec_const, 180, -dec_const, -dec_const, 0, 0, 0, 1, nocollide) })
        else
            table_Add(const_list, { constraint_AdvBallsocket(ent1, ent2, Bone1, Bone2, LPos1, LPos2, 0, 0, -180, -flex, -0.01, 180, flex, 0.01, 0, 0, 0, 1, nocollide) })
            table_Add(const_list, { constraint_AdvBallsocket(ent1, ent2, Bone1, Bone2, LPos1, LPos2, 0, 0, -0.01, -flex, -180, 0.01, flex, 180, 0, 0, 0, 1, nocollide) })
            table_Add(const_list, { constraint_AdvBallsocket(ent1, ent2, Bone1, Bone2, LPos1, LPos2, 0, 0, -0.01, -flex, -0.01, 0.01, flex, 0.01, 0, 0, 0, 1, nocollide) })
        end

        undo_Create("Easy Ballsocket")

        for k, v in ipairs(const_list) do
            undo_AddEntity(v)
        end

        undo_SetPlayer(self:GetOwner())
        undo_Finish()

        self:ClearObjects()
    else
        self:SetStage(num + 1)
    end

    return true
end

function TOOL:Reload(tr)
    local ent = tr.Entity
    if not IsValid(ent) or ent:IsPlayer() then
        return false
    end

    if CLIENT then
        return true
    end

    self:SetStage(0)
    return constraint_RemoveConstraints(ent, "AdvBallsocket")
end