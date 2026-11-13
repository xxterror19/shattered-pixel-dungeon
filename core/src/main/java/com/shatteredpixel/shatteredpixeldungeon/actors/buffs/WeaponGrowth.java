package com.shatteredpixel.shatteredpixeldungeon.actors.buffs;

import com.shatteredpixel.shatteredpixeldungeon.actors.hero.Hero;
import com.shatteredpixel.shatteredpixeldungeon.items.KindOfWeapon;
import com.shatteredpixel.shatteredpixeldungeon.items.Item;
import com.shatteredpixel.shatteredpixeldungeon.utils.GLog;
import com.watabou.utils.Bundle;

//The equipped weapon gains +1 upgrade every INTERVAL turns
public class WeaponGrowth extends Buff {

	public static final int INTERVAL = 500;

	private int left = INTERVAL;

	{
		revivePersists = true;
	}

	@Override
	public boolean act() {
		if (--left <= 0) {
			left = INTERVAL;
			KindOfWeapon weapon = ((Hero) target).belongings.weapon;
			if (weapon != null) {
				weapon.upgrade();
				Item.updateQuickslot();
				GLog.p("Tu arma mejora: " + weapon.name());
			}
		}
		spend(TICK);
		return true;
	}

	private static final String LEFT = "left";

	@Override
	public void storeInBundle(Bundle bundle) {
		super.storeInBundle(bundle);
		bundle.put(LEFT, left);
	}

	@Override
	public void restoreFromBundle(Bundle bundle) {
		super.restoreFromBundle(bundle);
		left = bundle.getInt(LEFT);
	}
}
