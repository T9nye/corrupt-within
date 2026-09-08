-- Weapon tuning (damage, swing speed, combo windows). Source of truth: docs/combat.md.
-- Confirm with Ye before changing any numbers here — see CLAUDE.md.
--
-- Damage values, combo windows, windups and cooldowns are taken straight from
-- docs/combat.md. Hitbox sizes, commitment windows and knockback are NOT in
-- that doc — they're marked (new) below and are first-pass guesses.

return {
	-- Which weapon a fresh character is handed. Phase 5 will read this off the
	-- player's profile instead (docs/progression.md tracks per-weapon levels).
	DefaultWeapon = "Sword",

	Sword = {
		DisplayName = "Sword",

		-- (new) Grey-box blade geometry. Not from any doc -- combat.md is
		-- about timings, not models. Built from parts so there's no asset to
		-- keep in sync; replace with a real mesh whenever art happens.
		Model = {
			BladeSize = Vector3.new(0.22, 5, 0.85),
			GuardSize = Vector3.new(1.9, 0.32, 0.42),
			GripSize = Vector3.new(0.38, 1.5, 0.38),
			PommelSize = Vector3.new(0.55, 0.42, 0.55),
			BladeColor = Color3.fromRGB(178, 182, 191), -- pale steel
			EdgeColor = Color3.fromRGB(214, 218, 226),
			GuardColor = Color3.fromRGB(74, 68, 60), -- dark iron, matches the Haven's metal
			GripColor = Color3.fromRGB(70, 45, 25), -- wrapped leather
			-- How the grip sits in the hand. The 180-degree flip points the
			-- blade out through the fingers so it continues the line of the
			-- arm, rather than jutting out sideways. Tuned by eye in a
			-- playtest; nudge if the blade ever looks wrong in hand.
			HandOffset = CFrame.new(0, -0.2, 0) * CFrame.Angles(math.rad(180), 0, 0),
		},

		Light = {
			-- 3-hit chain. Index into these with the current combo step.
			Damage = { 10, 10, 14 },
			ComboWindow = 0.45, -- seconds to land the next hit before the chain resets
			-- (new) how long you're locked out of acting after each swing
			Commitment = { 0.30, 0.30, 0.45 },
			-- (new) box swept in front of the attacker, in studs
			HitboxSize = Vector3.new(6, 6, 7),
			HitboxForwardOffset = 3.5,
			-- (new) final hit only, per combat.md's "slight knockback"
			FinalHitKnockback = 18, -- studs/second
			KnockbackDuration = 0.12,
		},

		Heavy = {
			Damage = 28,
			Windup = 0.60, -- cancellable during this window only
			Commitment = 0.45, -- (new) recovery after the hit lands
			Cooldown = 1.2, -- (new)
			HitboxSize = Vector3.new(8, 6, 8), -- (new)
			HitboxForwardOffset = 4,
			LungeSpeed = 14, -- (new) "small forward lunge"
			LungeDuration = 0.15,
		},

		-- Not implemented — Phase 6+ per docs/build-order.md. Numbers parked
		-- here so combat.md's "all numbers live in WeaponConfig" holds true.
		Abilities = {
			Riposte = { ParryWindow = 0.25, CounterDamage = 35, Cooldown = 8 },
			CorruptSlash = { Damage = 40, Corruption = 6, Cooldown = 12 },
			Severance = { TotalDamage = 90, Hits = 3, Corruption = 10, Cooldown = 60 },
		},
	},
}
