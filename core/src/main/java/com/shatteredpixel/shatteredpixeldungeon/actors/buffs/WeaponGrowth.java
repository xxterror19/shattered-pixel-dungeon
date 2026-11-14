package com.shatteredpixel.shatteredpixeldungeon.actors.buffs;

import com.shatteredpixel.shatteredpixeldungeon.actors.hero.Hero;
import com.shatteredpixel.shatteredpixeldungeon.actors.hero.Belongings;
import com.shatteredpixel.shatteredpixeldungeon.items.Item;
import com.shatteredpixel.shatteredpixeldungeon.utils.GLog;
import com.watabou.utils.Bundle;

//Todo el equipo puesto (arma, armadura, anillo, artefacto, misc) gana +1 de mejora cada INTERVAL turnos
public class WeaponGrowth extends Buff {

	public static final int INTERVAL = 100;

	private int left = INTERVAL;

	{
		revivePersists = true;
	}

	@Override
	public boolean act() {
		if (--left <= 0) {
			left = INTERVAL;
			Belongings b = ((Hero) target).belongings;
			boolean any = false;
			for (Item i : new Item[]{b.weapon, b.armor, b.ring, b.artifact, b.misc}) {
				if (i != null && i.isUpgradable()) {
					i.upgrade();
					any = true;
				}
			}
			if (any) {
				Item.updateQuickslot();
				GLog.p("Tu equipo mejora");
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
