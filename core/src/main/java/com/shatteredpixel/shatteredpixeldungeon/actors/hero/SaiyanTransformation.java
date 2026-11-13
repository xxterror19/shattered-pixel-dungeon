package com.shatteredpixel.shatteredpixeldungeon.actors.hero;

import com.shatteredpixel.shatteredpixeldungeon.Dungeon;
import com.shatteredpixel.shatteredpixeldungeon.effects.Speck;
import com.shatteredpixel.shatteredpixeldungeon.items.wands.WandOfPlasma;
import com.shatteredpixel.shatteredpixeldungeon.items.weapon.melee.MagesStaff;
import com.shatteredpixel.shatteredpixeldungeon.utils.GLog;

//Al elegir subclase, Goku, Vegeta y Gohan se transforman y su arma pasa a ser un baston de plasma
public class SaiyanTransformation {

	public static void apply(Hero hero, HeroSubClass way) {
		if (way != HeroSubClass.SUPER_SAIYAJIN && way != HeroSubClass.OOZARU) return;

		if (way == HeroSubClass.OOZARU) {
			//Oozaru: mucho mas vida y fuerza
			hero.HTBoost += 100;
			hero.STR += 5;
			GLog.p("¡Te transformas en Oozaru, el gran mono!");
		} else {
			hero.HTBoost += 50;
			GLog.p("¡Te transformas en Super Saiyajin!");
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
