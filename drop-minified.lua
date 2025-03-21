-- UI Element Types
local b = {
    Unknown = 0,
    Root = 1,
    Category = 2,
    Section = 3,
    Header = 4,
    Entry = 5,
    UiElement = 6,
}

-- Base Class for UI Elements
local c = {}
c.__index = c

function c:New(I, J, K)
    local L = setmetatable({}, c)
    L.Type = I or b.Unknown
    L.Parent = J or L.Parent
    L.Children = {}
    L.GuiObject = K or nil
    if J then J:AddChild(L) end
    return L
end

function c:AddChild(I)
    I.Parent = self
    table.insert(self.Children, I)
    if I.GuiObject and self.GuiObject then
        I.GuiObject.Parent = self.GuiObject
    end
end

function c:RecursiveUpdateGui()
    self:UpdateGui()
    for _, J in ipairs(self.Children) do
        J:RecursiveUpdateGui()
    end
end

function c:UpdateGui() end

-- UI Element Classes
local d = {}
d.__index = d
setmetatable(d, c)

function d:New(I, J, K)
    local L = setmetatable(c:New(b.UiElement), d)
    L.Value = nil
    L.Title = K
    L.Size = I
    L.Position = J
    return L
end

function d:SetValue() end
function d:GetValue() return self.Value end

-- UI Styles and Constants
local e = {
    PrimaryColor = Color3.fromRGB(27, 38, 59),
    SecondaryColor = Color3.fromRGB(13, 27, 42),
    AccentColor = Color3.fromRGB(41, 115, 115),
    TextColor = Color3.new(1, 1, 1),
    Font = Enum.Font.Gotham,
    TextSize = 13,
    HeaderWidth = 300,
    HeaderHeight = 32,
    EntryMargin = 1,
    AnimationDuration = 0.4,
    AnimationEasingStyle = Enum.EasingStyle.Quint,
    DefaultEntryHeight = 35,
}

-- Header Class
local f = {}
f.__index = f
setmetatable(f, d)

function f:New()
    local I = setmetatable(d:New(UDim2.new(0, 20, 0, 20), UDim2.new(1, -20 - 5, 0.5, -20 / 2), ""), f)
    I.GuiObject = Instance.new("TextButton")
    I.GuiObject.MouseButton1Click:Connect(function()
        I.Parent.Parent.Collapsed = not I.Parent.Parent.Collapsed
        if I.Parent.Parent.Collapsed then
            I.Parent.Parent:Collapse()
        else
            I.Parent.Parent:Expand()
        end
    end)
    return I
end

function f:Collapse() self.GuiObject.Text = "+" end
function f:Expand() self.GuiObject.Text = "-" end

function f:UpdateGui()
    self.GuiObject.TextScaled = true
    self.GuiObject.TextColor3 = e.TextColor
    self.GuiObject.BackgroundTransparency = 1
    self.GuiObject.Size = self.Size
    self.GuiObject.Position = self.Position
    self.GuiObject.Text = self.Parent.Parent.Collapsed and "+" or "-"
end

-- Entry Class
local h = {}
h.__index = h
setmetatable(h, c)

function h:New(I)
    local J = setmetatable(c:New(b.Entry), h)
    J.Value = nil
    J.Height = I or e.DefaultEntryHeight
    J.GuiObject = Instance.new("Frame")
    return J
end

function h:SetValue() end
function h:GetValue() end

function h:UpdateGui()
    self.GuiObject.BackgroundColor3 = e.PrimaryColor
    self.GuiObject.BorderSizePixel = 0
    self.GuiObject.Size = UDim2.new(1, 0, 0, self.Height)
end

-- Section Class
local i = {}
i.__index = i
setmetatable(i, c)

function i:New(I)
    local J = setmetatable(c:New(b.Section), i)
    J.Collapsed = false
    J.Height = 0
    J.GuiObject = Instance.new("Frame")
    J.Header = f:New()
    J.Title = I or ""
    J:AddChild(J.Header)
    return J
end

function i:UpdateGui()
    self.GuiObject.Size = UDim2.new(0, e.HeaderWidth, 0, 0)
    self.GuiObject.BackgroundColor3 = e.SecondaryColor
    self.GuiObject.BorderSizePixel = 0
    self.GuiObject.ClipsDescendants = true
    self:ReorderGui(true)
end

function i:ReorderGui(I)
    I = I or false
    local J = e.AnimationDuration
    if I then J = 0 end
    self.Height = e.HeaderHeight
    if not self.Collapsed then
        for _, L in pairs(self.Children) do
            if L.Type ~= b.Header then
                L.GuiObject:TweenPosition(UDim2.new(0, 0, 0, self.Height), Enum.EasingDirection.InOut, e.AnimationEasingStyle, J, true)
                self.Height = self.Height + L.Height + e.EntryMargin
            end
        end
        self.Height = self.Height - e.EntryMargin
    end
    self.GuiObject:TweenSize(UDim2.new(0, e.HeaderWidth, 0, self.Height), Enum.EasingDirection.InOut, e.AnimationEasingStyle, J, true)
    if self.Parent.Type ~= b.Root then
        self.Parent:ReorderGui(I)
    end
end

function i:Collapse()
    self.Collapsed = true
    self.Header.CollapseButton:Collapse()
    self:ReorderGui()
end

function i:Expand()
    self.Collapsed = false
    self.Header.CollapseButton:Expand()
    self:ReorderGui()
end

function i:AddEntry(I)
    self:AddChild(I)
    I:RecursiveUpdateGui()
    self:ReorderGui(true)
end

-- Category Class
local j = {}
j.__index = j
setmetatable(j, i)

function j:New(I)
    local J = setmetatable(i:New(I, b.Section), j)
    return J
end

function i:CreateSection(I)
    local J = j:New(I)
    self:AddChild(J)
    J:RecursiveUpdateGui()
    return J
end

-- Draggable Category Class
local l = {}
l.__index = l
setmetatable(l, i)

function l:New(I, J)
    local K = setmetatable(i:New(I, b.Category), l)
    K.Draggable = J or true
    K.Position = UDim2.new(0, 0, 0, 0)
    K:ApplyDraggability()
    return K
end

function l:MoveTo(I)
    self.Position = I
    self.GuiObject.Position = I
end

function l:AutoMove()
    self:MoveTo(UDim2.fromOffset(100 + (#self.Parent.Children - 1) * (e.HeaderWidth * 1.25), 36))
end

function l:ApplyDraggability()
    self.LastMousePosition = game:GetService("User InputService"):GetMouseLocation()
    self.DragActive = false
    self.Header.GuiObject.InputBegan:Connect(function(I)
        if I.UserInputType == Enum.UserInputType.MouseButton1 and self.Draggable then
            self.DragActive = true
        end
    end)
    self.Header.GuiObject.InputEnded:Connect(function(I)
        if I.UserInputType == Enum.UserInputType.MouseButton1 then
            self.DragActive = false
        end
    end)
    game:GetService("User InputService").InputChanged:Connect(function(I)
        if I.UserInputType == Enum.UserInputType.MouseMovement then
            if self.DragActive then
                local J = game:GetService("User InputService"):GetMouseLocation() - self.LastMousePosition
                self:MoveTo(UDim2.new(self.GuiObject.Position.X.Scale, self.GuiObject.Position.X.Offset + J.X, self.GuiObject.Position.Y.Scale, self.GuiObject.Position.Y.Offset + J.Y))
            end
            self.LastMousePosition = game:GetService("User InputService"):GetMouseLocation()
        end
    end)
end

-- Button Class
local m = {}
m.__index = m
setmetatable(m, d)

function m:New(I, J, K, L)
    local M = setmetatable(d:New(I, J, K), m)
    M.Callback = L
    M.GuiObject = Instance.new("TextButton")
    M.GuiObject.MouseButton1Click:Connect(M.Callback)
    return M
end

function m:UpdateGui()
    self.GuiObject.BorderSizePixel = 0
    self.GuiObject.BackgroundColor3 = e.SecondaryColor
    self.GuiObject.TextColor3 = e.TextColor
    self.GuiObject.Size = self.Size
    self.GuiObject.Position = self.Position
    self.GuiObject.Text = self.Title
    self.GuiObject.TextSize = e.TextSize
    self.GuiObject.Font = e.Font
end

function i:CreateButton(I, J)
    local K = h:New()
    K:AddChild(m:New(UDim2.new(1, -10, 1, -10), UDim2.new(0, 5, 0, 5), I, J))
    self:AddEntry(K)
    return K
end

-- Slider Class
local o = {}
o.__index = o
setmetatable(o, d)

function o:New(I, J, K, L, M, N, O, P, Q, R)
    local S = setmetatable(d:New(I, J, K), o)
    S.Callback = L
    S.Dynamic = P or false
    Q = Q or M
    S.Step = O or 0.01
    S.Max = N
    S.Min = M
    S.CustomColor = R
    S.Value = Q or S.Min
    S.GuiObject = Instance.new("Frame")
    S.Bg = Instance.new("Frame", S.GuiObject)
    S.Box = Instance.new("TextBox", S.GuiObject)
    S.Overlay = Instance.new("Frame", S.Bg)
    S.Handle = Instance.new("Frame", S.Overlay)
    S.Label = Instance.new("TextLabel", S.Bg)
    S.Active = false

    -- Input Handling
    S.Bg.InputBegan:Connect(function(T)
        if T.UserInputType == Enum.UserInputType.MouseButton1 then
            S.Active = true
            local U = math.clamp(T.Position.X - S.Bg.AbsolutePosition.X, 0, S.Bg.AbsoluteSize.X) / S.Bg.AbsoluteSize.X
            S:SetValue(S.Min + (U * (S.Max - S.Min)))
        end
    end)

    S.Bg.InputEnded:Connect(function(T)
        if T.UserInputType == Enum.UserInputType.MouseButton1 then
            S.Active = false
            S.Callback(S.Value)
        end
    end)

    game:GetService("User InputService").InputChanged:Connect(function(T)
        if T.UserInputType == Enum.UserInputType.MouseMovement then
            if S.Active then
                local U = math.clamp(T.Position.X - S.Bg.AbsolutePosition.X, 0, S.Bg.AbsoluteSize.X) / S.Bg.AbsoluteSize.X
                S:SetValue(S.Min + (U * (S.Max - S.Min)))
                if S.Dynamic then S.Callback(S.Value) end
            end
        end
    end)

    S.Box.FocusLost:Connect(function()
        local T = tonumber(S.Box.Text)
        if T then
            S:SetValue(T)
            S.Callback(S.Value)
        else
            S.Box.Text = S.Value
        end
    end)

    return S
end

function o:SetValue(I)
    self.Value = math.clamp(I - I % self.Step, self.Min, self.Max)
    self.Overlay.Size = UDim2.new((self.Value - self.Min) / (self.Max - self.Min), 0, 1, 0)
    self.Box.Text = tostring(self.Value)
end

function o:UpdateGui()
    self.GuiObject.BackgroundColor3 = e.SecondaryColor
    self.GuiObject.Size = self.Size
    self.GuiObject.Position = self.Position
    self.GuiObject.BorderSizePixel = 0
    self.GuiObject.BackgroundTransparency = 1
    self.Bg.BorderSizePixel = 0
    self.Bg.Size = UDim2.new(1 - 0.2, 0, 1, 0)
    self.Bg.BackgroundColor3 = e.SecondaryColor
    self.Box.Size = UDim2.new(0.2, -5, 1, 0)
    self.Box.Position = UDim2.new(0.8, 5, 0, 0)
    self.Box.BorderSizePixel = 0
    self.Box.BackgroundColor3 = e.SecondaryColor
    self.Box.TextColor3 = e.TextColor
    self.Box.TextWrapped = true
    self.Overlay.BorderSizePixel = 0
    self.Overlay.BackgroundColor3 = self.CustomColor or e.AccentColor
    self.Handle.Size = UDim2.new(0, 5, 1, 0)
    self.Handle.Position = UDim2.new(1, -(5 / 2), 0, 0)
    self.Handle.BackgroundColor3 = Color3.new(1, 1, 1)
    self.Handle.BorderSizePixel = 0
    self.Label.Text = self.Title
    self.Label.Font = e.Font
    self.Label.TextSize = e.TextSize
    self.Label.BackgroundTransparency = 1
    self.Label.Size = UDim2.new(1, 0, 1, 0)
    self.Label.TextColor3 = e.TextColor
    self:SetValue(self.Value)
end

-- Slider Entry Class
local p = {}
p.__index = p
setmetatable(p, h)

function p:New(I, J, K, L, M, N, O)
    local P = setmetatable(h:New(), p)
    P.Slider = o:New(UDim2.new(1, -10, 1, -14), UDim2.new(0, 5, 0, 7), I, function(Q)
        P.Value = Q
        pcall(J, P.Value)
    end, K, L, M, N, O)
    P:SetValue(O or P:GetValue())
    P:AddChild(P.Slider)
    return P
end

function p:SetValue(I)
    self.Slider:SetValue(I)
end

function p:GetValue()
    return self.Slider.Value
end

function i:CreateSlider(I, J, K, L, M, N, O)
    local P = p:New(I, J, K, L, M, N, O)
    self:AddEntry(P)
    return P
end

-- TextBox Class
local r = {}
r.__index = r
setmetatable(r, d)

function r:New(I, J, K, L, M, N, O)
    local P = setmetatable(d:New(I, J, K), r)
    P.Callback = L
    P.Dynamic = N or false
    P.Value = O or ""
    P.AcceptFormat = M or "^.*$"
    P.GuiObject = Instance.new("TextBox")
    
    -- Input Handling
    P.GuiObject.FocusLost:Connect(function()
        if string.match(P.GuiObject.Text, P.AcceptFormat) then
            P:SetValue(P.GuiObject.Text)
            P.Callback(P.Value)
        end
    end)

    P.GuiObject.Changed:Connect(function(Q)
        if P.Dynamic and Q == "Text" and P.GuiObject:IsFocused() then
            if string.match(P.GuiObject.Text, P.AcceptFormat) then
                P:SetValue(P.GuiObject.Text)
                P.Callback(P.Value)
            else
                P.GuiObject.Text = P.Value
            end
        end
    end)

    return P
end

function r:SetValue(I)
    self.GuiObject.Text = I
    self.Value = I
end

function r:UpdateGui()
    self.GuiObject.BackgroundColor3 = e.SecondaryColor
    self.GuiObject.TextColor3 = e.TextColor
    self.GuiObject.PlaceholderText = self.Title
    self.GuiObject.Position = self.Position
    self.GuiObject.Size = self.Size
    self.GuiObject.TextSize = e.TextSize
    self.GuiObject.Font = e.Font
    self.GuiObject.BorderSizePixel = 0
    self:SetValue(self.Value)
end

-- TextBox Entry Class
local s = {}
s.__index = s
setmetatable(s, h)

function s:New(I, J, K, L, M)
    local N = setmetatable(h:New(), s)
    N.TextBox = r:New(UDim2.new(1, -10, 1, -10), UDim2.new(0, 5, 0, 5), I, J, K, L, M)
    N:AddChild(N.TextBox)
    return N
end

function s:SetValue(I)
    self.TextBox:SetValue(I)
end

function s:GetValue()
    return self.TextBox.Value
end

function i:CreateTextBox(I, J, K, L, M)
    local N = s:New(I, J, K, L, M)
    self:AddEntry(N)
    return N
end

-- Color Picker Class
local u = {}
u.__index = u
setmetatable(u, d)

function u:New(I, J, K, L, M, N, O)
    local P = setmetatable(d:New(I, J, K), u)
    P.Callback = L
    P.Dynamic = N or false
    P.Value = O or e.AccentColor
    P.GuiObject = Instance.new("Frame")
    P.ColorImg = Instance.new("ImageLabel", P.GuiObject)
    P.Cursor = Instance.new("Frame", P.ColorImg)
    
    -- Sliders for RGB
    P.RSlider = o:New(UDim2.new(0.5, -10, 1 / 6, 0), UDim2.new(0.5, 5, 0 / 6, 2), "Red", function(Q)
        P:SetValue(Color3.new(Q / 255, P.Value.G, P.Value.B))
    end, 0, 255, 1, true, P.Value.R, Color3.new(0.75, 0, 0))
    P:AddChild(P.RSlider)

    P.GSlider = o:New(UDim2.new(0.5, -10, 1 / 6, 0), UDim2.new(0.5, 5, 1 / 6, 4), "Green", function(Q)
        P:SetValue(Color3.new(P.Value.R, Q / 255, P.Value.B))
    end, 0, 255, 1, true, P.Value.G, Color3.new(0, 0.75, 0))
    P:AddChild(P.GSlider)

    P.BSlider = o:New(UDim2.new(0.5, -10, 1 / 6, 0), UDim2.new(0.5, 5, 2 / 6, 6), "Blue", function(Q)
        P:SetValue(Color3.new(P.Value.R, P.Value.G, Q / 255))
    end, 0, 255, 1, true, P.Value.B, Color3.new(0, 0, 0.75))
    P:AddChild(P.BSlider)

    -- Hex Input
    P.HexBox = r:New(UDim2.new(0.5, -10, 1 / 6, 0), UDim2.new(0.5, 5, 3 / 6, 8), "", function(Q)
        local R = {}
        for S in Q:gmatch("%x%x") do
            table.insert(R, tonumber("0x" .. S))
        end
        P:SetValue(Color3.fromRGB(unpack(R)))
    end, "^%x%x%x%x%x%x$")
    P:AddChild(P.HexBox)

    -- Value Slider
    P.VSlider = o:New(UDim2.new(0.5, -10, 1 / 6, 0), UDim2.new(0.5, 5, 5 / 6, -2), "Value", function(Q)
        local R, S = Color3.toHSV(P.Value)
        P:SetValue(Color3.fromHSV(R, S, Q / 255))
    end, 0, 255, 1, true, ({ Color3.toHSV(P.Value) })[3], Color3.new(0.75, 0.75, 0.75))
    P:AddChild(P.VSlider)

    -- Color Image Mouse Handling
    P.ColorImg.MouseMoved:Connect(function(Q, R)
        if game:GetService("User InputService"):IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
            local S = Vector2.new(Q, R - 36) - P.ColorImg.AbsolutePosition
            local T, U = 1 - S.X / P.ColorImg.AbsoluteSize.X, 1 - S.Y / P.ColorImg.AbsoluteSize.Y
            P:SetValue(Color3.fromHSV(T, U, P.VSlider.Value / 255))
        end
    end)

    P.ColorImg.InputBegan:Connect(function(Q)
        if Q.UserInputType == Enum.UserInputType.MouseButton1 then
            local R = Vector2.new(Q.Position.X, Q.Position.Y) - P.ColorImg.AbsolutePosition
            local S, T = 1 - R.X / P.ColorImg.AbsoluteSize.X, 1 - R.Y / P.ColorImg.AbsoluteSize.Y
            P:SetValue(Color3.fromHSV(S, T, P.VSlider.Value / 255))
        end
    end)

    P:SetValue(P.Value)
    return P
end

function u:SetValue(I)
    self.Value = I
    local J, K, L = Color3.toHSV(I)
    self.Cursor.Position = UDim2.new(1 - J, -2, 1 - K, -2)
    self.VSlider:SetValue(L * 255)
    self.RSlider:SetValue(I.R * 255)
    self.GSlider:SetValue(I.G * 255)
    self.BSlider:SetValue(I.B * 255)
    self.HexBox:SetValue(string.format("%02x%02x%02x", self.Value.R * 255, self.Value.G * 255, self.Value.B * 255))
    self.Callback(self.Value)
end

function u:UpdateGui()
    self.GuiObject.Size = self.Size
    self.GuiObject.Position = self.Position
    self.GuiObject.BackgroundTransparency = 1
    self.ColorImg.Image = "rbxassetid://698052001"
    self.ColorImg.Size = UDim2.new(0.5, -10, 1, -10)
    self.ColorImg.BorderSizePixel = 0
    self.ColorImg.Position = UDim2.new(0, 5, 0, 5)
    self.Cursor.Size = UDim2.new(0, 4, 0, 4)
    self.Cursor.BorderSizePixel = 0
    self.Cursor.BackgroundColor3 = Color3.new(1, 1, 1)
    self:SetValue(self.Value)
end

-- Color Picker Entry Class
local v = {}
v.__index = v
setmetatable(v, h)

function v:New(I, J, K, L)
    local M = setmetatable(h:New(), v)
    M.Title = I
    M.Dynamic = K
    M.Callback = J
    M.ColorPicker = u:New(UDim2.new(1, 0, 0, e.HeaderWidth / 2), UDim2.new(0, 0, 0, e.DefaultEntryHeight), I, function(N)
        M.ColorButton.BackgroundColor3 = N
        M.Value = N
        if M.Dynamic and M.Toggled then pcall(M.Callback, N) end
    end, L)
    M.Toggled = false
    M.ColorButton.MouseButton1Click:Connect(function()
        if M.Toggled then
            M.Height = e.DefaultEntryHeight
            pcall(J, M.Value)
        else
            M.Height = e.HeaderWidth / 2 + e.DefaultEntryHeight
        end
        M.GuiObject:TweenSize(UDim2.new(1, 0, 0, M.Height), Enum.EasingDirection.InOut, e.AnimationEasingStyle, e.AnimationDuration, true)
        M.Parent:ReorderGui()
        M.Toggled = not M.Toggled
    end)
    M:SetValue(L or M:GetValue())
    M:AddChild(M.ColorPicker)
    return M
end

function v:SetValue(I)
    self.ColorPicker:SetValue(I)
end

function v:GetValue()
    return self.ColorPicker.Value
end

function i:CreateColorPicker(I, J, K, L)
    local M = v:New(I, J, K, L)
    self:AddEntry(M)
    M:RecursiveUpdateGui()
    return M
end

-- Selector Class
local y = {}
y.__index = y
setmetatable(y, d)

function y:New(I, J, K, L, M)
    local N = setmetatable(d:New(I, J, K), y)
    N.Callback = L
    N.Getcall = M
    N.GuiObject = Instance.new("Frame")
    N.ScrollBox = Instance.new("ScrollingFrame", N.GuiObject)
    N.SearchBox = r:New(UDim2.new(1, 0, 0, 30), UDim2.new(0, 0, 0, 0), "Search", function(O)
        N:SetList(x(M(), O))
    end, nil, true)
    N:AddChild(N.SearchBox)
    return N
end

function y:SetList(I)
    local J = 0
    self.ScrollBox:ClearAllChildren()
    for _, L in pairs(I) do
        local M = Instance.new("TextButton", self.ScrollBox)
        M.Text = tostring(L)
        M.BackgroundColor3 = e.SecondaryColor
        M.TextColor3 = e.TextColor
        M.BorderColor3 = e.PrimaryColor
        M.Size = UDim2.new(1, -4, 0, 30)
        M.Position = UDim2.new(0, 2, 0, self.ScrollBox.AbsoluteSize.Y * J)
        M.MouseButton1Click:Connect(function()
            self.Callback(L)
            self:SetList(x(self.Getcall(), self.SearchBox.Value))
        end)
        J = J + 1
    end
    self.ScrollBox.CanvasSize = UDim2.new(0, 0, 0, #I * 30)
end

function y:UpdateGui()
    self.GuiObject.BorderSizePixel = 0
    self.GuiObject.BackgroundTransparency = 1
    self.GuiObject.Size = self.Size
    self.GuiObject.Position = self.Position
    self.ScrollBox.Position = UDim2.new(0, 0, 0, 30 + 2)
    self.ScrollBox.BackgroundTransparency = 1
    self.ScrollBox.BorderSizePixel = 0
    self.ScrollBox.ScrollBarThickness = 3
    self.ScrollBox.Size = UDim2.new(1, 0, 1, -30)
    self:SetList(self.Getcall())
end

-- Selector Entry Class
local z = {}
z.__index = z
setmetatable(z, h)

function z:New(I, J, K, L)
    local M = setmetatable(h:New(), z)
    M.Title = I
    M.Callback = J
    M.Selector = y:New(UDim2.new(1, 0, 0, e.DefaultEntryHeight * 5), UDim2.new(0, 0, 0, e.DefaultEntryHeight), I, function(N)
        if not game:GetService("User InputService"):IsKeyDown(Enum.KeyCode.LeftShift) then
            M:Toggle()
        end
        M:SetValue(N)
        M.Callback(N)
    end, K)
    M:AddChild(M.Selector)
    M.Button = Instance.new("TextButton", M.GuiObject)
    M.Indicator = Instance.new("TextLabel", M.Button)
    M.Indicator.Text = "▼"
    M.Toggled = false

    M.Button.MouseButton1Click:Connect(function()
        M:Toggle()
        M.Selector:SetList(x(M.Selector.Getcall(), M.Selector.SearchBox.Value))
    end)

    M:SetValue(L)
    return M
end

function z:Toggle()
    if self.Toggled then
        self.Height = e.DefaultEntryHeight
        self.Indicator.Text = "▼"
    else
        self.Height = e.DefaultEntryHeight * 6
        self.Indicator.Text = "▲"
    end
    self.GuiObject:TweenSize(UDim2.new(1, 0, 0, self.Height), Enum.EasingDirection.InOut, e.AnimationEasingStyle, e.AnimationDuration, true)
    self.Parent:ReorderGui()
    self.Toggled = not self.Toggled
end

function z:SetValue(I)
    self.Button.Text = string.format("%s [%s]", self.Title, tostring(I or "Empty"))
    self.Value = I
end

function z:GetValue()
    return self.Value
end

function i:CreateSelector(I, J, K, L)
    local M = z:New(I, J, K, L)
    self:AddEntry(M)
    return M
end

-- Switch Class
local A = {}
A.__index = A
setmetatable(A, d)

function A:New(I, J, K, L, M)
    local N = setmetatable(d:New(I, J, K), A)
    N.Callback = L
    N.Value = M or false
    N.GuiObject = Instance.new("Frame")
    N.Label = Instance.new("TextLabel", N.GuiObject)
    N.Button = Instance.new("TextButton", N.GuiObject)

    N.Button.MouseButton1Click:Connect(function()
        N:SetValue(not N.Value)
        N.Callback(N.Value)
    end)

    return N
end

function A:SetValue(I)
    self.Value = I
    self.Button.BackgroundColor3 = self.Value and e.AccentColor or e.SecondaryColor
end

function A:UpdateGui()
    self.GuiObject.Size = self.Size
    self.GuiObject.BackgroundTransparency = 1
    self.GuiObject.Position = self.Position
    self.Label.Text = self.Title
    self.Label.TextSize = e.TextSize
    self.Label.Font = e.Font
    self.Label.BackgroundTransparency = 1
    self.Label.Size = UDim2.new(0.8, 0, 1, 0)
    self.Label.TextColor3 = e.TextColor
    self.Button.Size = UDim2.new(0, 20, 0, 20)
    self.Button.BorderSizePixel = 2
    self.Button.BorderColor3 = e.SecondaryColor
    self.Button.Position = UDim2.new(0.9, -10, 0.5, -10)
    self.Button.Text = ""
    self:SetValue(self.Value)
end

-- Switch Entry Class
local C = {}
C.__index = C
setmetatable(C, h)

function C:New(I, J, K)
    local L = setmetatable(h:New(), C)
    L.Switch = A:New(UDim2.new(1, -10, 1, -10), UDim2.new(0, 5, 0, 5), I, J, K)
    L:AddChild(L.Switch)
    return L
end

function C:SetValue(I)
    self.Switch:SetValue(I)
end

function C:GetValue()
    return self.Switch.Value
end

function i:CreateSwitch(I, J, K)
    local L = C:New(I, J, K)
    self:AddEntry(L)
    return L
end

-- Text Label Class
local D = {}
D.__index = D
setmetatable(D, d)

function D:New(I, J, K)
    local L = setmetatable(d:New(I, J, K), D)
    L.GuiObject = Instance.new("TextLabel")
    return L
end

function D:UpdateGui()
    self.GuiObject.BorderSizePixel = 0
    self.GuiObject.BackgroundTransparency = 1
