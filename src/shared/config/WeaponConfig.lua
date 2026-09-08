-- Weapon tuning (damage, swing speed, combo windows). Source of truth: docs/combat.md.
-- Confirm with Ye before changing any numbers here — see CLAUDE.md.
--
-- Damage values, combo windows, windups and cooldowns are taken straight from
-- docs/combat.md. Hitbox sizes, commitment windows and knockback are NOT in
-- that doc — they're marked (new) below and are first-pass guesses.

return {
	Sword = {
		DisplayName = "Sword",

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
