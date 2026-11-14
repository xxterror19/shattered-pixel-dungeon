package com.shatteredpixel.shatteredpixeldungeon.actors.hero;

import com.shatteredpixel.shatteredpixeldungeon.Dungeon;
import com.shatteredpixel.shatteredpixeldungeon.effects.Speck;
import com.shatteredpixel.shatteredpixeldungeon.items.wands.WandOfPlasma;
import com.shatteredpixel.shatteredpixeldungeon.items.weapon.melee.MagesStaff;
import com.shatteredpixel.shatteredpixeldungeon.utils.GLog;

//Al elegir subclase, Kael, Nyx y Orin se transforman y su arma pasa a ser un baston de plasma
public class FormTransformation {

	public static void apply(Hero hero, HeroSubClass way) {
		if (way != HeroSubClass.FORMA_SOLAR && way != HeroSubClass.COLOSO) return;

		if (way == HeroSubClass.COLOSO) {
			//Coloso: mucho mas vida y fuerza
			hero.HTBoost += 100;
			hero.STR += 5;
			GLog.p("¡Te transformas en Coloso, el gran mono!");
		} else {
			hero.HTBoost += 50;
			GLog.p("¡Te transformas en Forma Solar!");
		}
		hero.updateHT(true);

		//el arma pasa a ser un baston con una varita de plasma
		MagesStaff staff = new MagesStaff(new WandOfPlasma());
		staff.identify();
		staff.upgrade(3);
		if (hero.belongings.weapon != null) {
			hero.belongings.weapon.doUnequip(hero, true, false);
		}
		hero.belongings.weapon = staff;
		staff.activate(hero);
		Dungeon.quickslot.setSlot(0, staff);

		hero.sprite.emitter().burst(Speck.factory(Speck.STAR), 15);
	}
}
