package com.shatteredpixel.shatteredpixeldungeon.actors.hero;

import com.shatteredpixel.shatteredpixeldungeon.Dungeon;
import com.shatteredpixel.shatteredpixeldungeon.effects.Speck;
import com.shatteredpixel.shatteredpixeldungeon.items.wands.WandOfPlasma;
import com.shatteredpixel.shatteredpixeldungeon.items.weapon.melee.MagesStaff;
import com.shatteredpixel.shatteredpixeldungeon.utils.GLog;

//Al elegir subclase, Kael, Nyx y Orin se transforman y su arma pasa a ser un baston de plasma
public class FormTransformation {

	//{vida maxima, fuerza, multiplicador de dano, multiplicador de dano recibido}
	private static float[] stats(HeroSubClass way){
		switch (way){
			case SOLAR: return new float[]{50, 0, 1.3f, 1.0f};
			case COLOSO: return new float[]{100, 5, 1.2f, 0.85f};
			case SOMBRA: return new float[]{30, 0, 1.4f, 1.0f};
			case ESPECTRO: return new float[]{60, 0, 1.1f, 0.75f};
			case TORMENTA: return new float[]{40, 0, 1.35f, 1.0f};
			case ARCANO: return new float[]{80, 3, 1.15f, 0.8f};
			default: return null;
		}
	}

	public static float dmgMult(HeroSubClass way){
		float[] s = stats(way); return s == null ? 1f : s[2];
	}

	public static float takenMult(HeroSubClass way){
		float[] s = stats(way); return s == null ? 1f : s[3];
	}

	public static void apply(Hero hero, HeroSubClass way) {
		float[] s = stats(way);
		if (s == null) return;

		hero.HTBoost += (int)s[0];
		hero.STR += (int)s[1];
		hero.updateHT(true);
		GLog.p("¡Te transformas: " + way.title() + "!");

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
