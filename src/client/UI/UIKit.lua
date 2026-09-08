-- Small shared helpers for building menu UI in code. Not a Knit controller
-- itself -- just a plain ModuleScript of functions -- because every one of
-- LoadingController/MenuController/CustomizeController/SettingsController
-- needs the same button, the same label style and the same slider, and
-- writing that styling code four times is how four screens stop looking
-- like they belong to the same game.

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UIConfig = require(ReplicatedStorage.Shared.config.UIConfig)

local UIKit = {}

function UIKit.corner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 6)
	c.Parent = parent
	return c
end

function UIKit.stroke(parent, color, thickness)
	local s = Instance.new("UIStroke")
	s.Color = color or UIConfig.Colors.PanelBorder
	s.Thickness = thickness or 1
	s.Parent = parent
	return s
end

function UIKit.label(parent, text, size, position, opts)
	opts = opts or {}
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Text = text
	l.Size = size
	l.Position = position
	l.AnchorPoint = opts.AnchorPoint or Vector2.new(0, 0)
	l.Font = opts.Font or UIConfig.Fonts.Body
	l.TextSize = opts.TextSize or 18
	l.TextColor3 = opts.Color or UIConfig.Colors.TextPrimary
	l.TextXAlignment = opts.XAlignment or Enum.TextXAlignment.Left
	l.TextYAlignment = opts.YAlignment or Enum.TextYAlignment.Center
	l.TextWrapped = opts.Wrapped or false
	l.Parent = parent
	return l
end

-- A styled button with hover/press feedback. Returns the TextButton;
-- `callback` fires on a completed click.
function UIKit.button(parent, text, size, position, callback, opts)
	opts = opts or {}
	local btn = Instance.new("TextButton")
	btn.Text = text
	btn.Size = size
	btn.Position = position
	btn.AnchorPoint = opts.AnchorPoint or Vector2.new(0, 0)
	btn.BackgroundColor3 = opts.Color or UIConfig.Colors.Panel
	btn.TextColor3 = opts.TextColor or UIConfig.Colors.TextPrimary
	btn.Font = opts.Font or UIConfig.Fonts.Bold
	btn.TextSize = opts.TextSize or 20
	btn.AutoButtonColor = false -- we drive the hover colour ourselves, below
	btn.Parent = parent
	UIKit.corner(btn, opts.CornerRadius or 6)
	UIKit.stroke(btn, opts.BorderColor or UIConfig.Colors.PanelBorder)

	local baseColor = btn.BackgroundColor3
	local hoverColor = opts.HoverColor or UIConfig.Colors.AccentDim

	btn.MouseEnter:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.12), { BackgroundColor3 = hoverColor }):Play()
	end)
	btn.MouseLeave:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.12), { BackgroundColor3 = baseColor }):Play()
	end)
	if callback then
		btn.MouseButton1Click:Connect(callback)
	end

	return btn
end

-- A background panel: rounded, bordered, filled with the standard panel
-- colour. Everything else gets parented into the returned Frame.
function UIKit.panel(parent, size, position, opts)
	opts = opts or {}
	local p = Instance.new("Frame")
	p.Size = size
	p.Position = position
	p.AnchorPoint = opts.AnchorPoint or Vector2.new(0, 0)
	p.BackgroundColor3 = opts.Color or UIConfig.Colors.Panel
	p.BackgroundTransparency = opts.Transparency or 0
	p.BorderSizePixel = 0
	p.Parent = parent
	UIKit.corner(p, opts.CornerRadius or 10)
	if not opts.NoBorder then
		UIKit.stroke(p, UIConfig.Colors.PanelBorder)
	end
	return p
end

-- A horizontal fill bar (used for the loading progress bar). Returns the
-- track and the fill separately so the caller can animate Size on the fill.
function UIKit.progressBar(parent, size, position, opts)
	opts = opts or {}
	local track = UIKit.panel(parent, size, position, {
		AnchorPoint = opts.AnchorPoint,
		Color = UIConfig.Colors.Background,
		CornerRadius = 4,
	})
	local fill = Instance.new("Frame")
	fill.Size = UDim2.new(0, 0, 1, 0)
	fill.BackgroundColor3 = opts.FillColor or UIConfig.Colors.Accent
	fill.BorderSizePixel = 0
	fill.Parent = track
	UIKit.corner(fill, 4)
	return track, fill
end

-- A draggable slider. `onChanged(value)` fires continuously while dragging
-- and once more on release. Value is clamped to [min, max].
--
-- How the drag works: a slider is really just "how far across this track
-- did you click or drag", expressed as a fraction from 0 to 1. We read the
-- mouse's X position, subtract the track's own X position, and divide by
-- the track's width -- that fraction times (max - min), plus min, is the
-- value. UserInputService.InputChanged fires continuously while a finger
-- or mouse button is held down and moving, which is what makes this feel
-- like a drag instead of only reacting to the initial click.
function UIKit.slider(parent, label, size, position, min, max, initial, onChanged)
	local container = Instance.new("Frame")
	container.Size = size
	container.Position = position
	container.BackgroundTransparency = 1
	container.Parent = parent

	UIKit.label(container, label, UDim2.new(0.55, 0, 1, 0), UDim2.new(0, 0, 0, 0), {
		YAlignment = Enum.TextYAlignment.Center,
	})

	local valueLabel = UIKit.label(container, "", UDim2.new(0.15, 0, 1, 0), UDim2.new(0.85, 0, 0, 0), {
		XAlignment = Enum.TextXAlignment.Right,
		Color = UIConfig.Colors.TextSecondary,
		TextSize = 15,
	})

	local track, fill = UIKit.progressBar(
		container,
		UDim2.new(0.42, 0, 0, 8),
		UDim2.new(0.58, 0, 0.5, 0),
		{ AnchorPoint = Vector2.new(0, 0.5) }
	)

	local handle = Instance.new("Frame")
	handle.Size = UDim2.new(0, 14, 0, 14)
	handle.AnchorPoint = Vector2.new(0.5, 0.5)
	handle.BackgroundColor3 = UIConfig.Colors.Accent
	handle.BorderSizePixel = 0
	handle.ZIndex = 2
	handle.Parent = track
	UIKit.corner(handle, 7)

	local dragging = false
	local currentValue = initial

	local function setFromFraction(fraction)
		fraction = math.clamp(fraction, 0, 1)
		currentValue = min + (max - min) * fraction
		fill.Size = UDim2.new(fraction, 0, 1, 0)
		handle.Position = UDim2.new(fraction, 0, 0.5, 0)
		local decimals = (max - min) <= 3 and 2 or 0
		valueLabel.Text = string.format("%." .. decimals .. "f", currentValue)
		if onChanged then
			onChanged(currentValue)
		end
	end

	local function fractionFor(value)
		return (value - min) / (max - min)
	end
	setFromFraction(fractionFor(initial))

	local function beginDrag(input)
		dragging = true
		local fraction = (input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X
		setFromFraction(fraction)
	end

	track.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			beginDrag(input)
		end
	end)
	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local fraction = (input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X
			setFromFraction(fraction)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)

	return {
		Set = function(value)
			setFromFraction(fractionFor(value))
		end,
		Get = function()
			return currentValue
		end,
	}
end

-- Fades a Frame/ScreenGui's descendant GuiObjects in or out together by
-- tweening a single ScreenGui-level or Frame-level transparency isn't
-- possible on ScreenGui directly, so this walks the tree. Used for the
-- whole-menu fade on PLAY.
function UIKit.fade(root, targetTransparency, duration, callback)
	local tweens = {}
	for _, obj in ipairs(root:GetDescendants()) do
		if obj:IsA("Frame") or obj:IsA("TextButton") then
			table.insert(tweens, TweenService:Create(obj, TweenInfo.new(duration), { BackgroundTransparency = targetTransparency }))
		elseif obj:IsA("TextLabel") or obj:IsA("TextButton") then
			table.insert(tweens, TweenService:Create(obj, TweenInfo.new(duration), { TextTransparency = targetTransparency }))
		elseif obj:IsA("ImageLabel") then
			table.insert(tweens, TweenService:Create(obj, TweenInfo.new(duration), { ImageTransparency = targetTransparency }))
		end
	end
	for _, t in ipairs(tweens) do
		t:Play()
	end
	if callback then
		task.delay(duration, callback)
	end
end

return UIKit
