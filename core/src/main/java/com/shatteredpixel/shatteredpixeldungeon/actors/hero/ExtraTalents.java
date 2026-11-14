package com.shatteredpixel.shatteredpixeldungeon.actors.hero;

import java.util.Arrays;
import java.util.EnumMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

//Talentos propios de Kael, Nyx y Orin: cada talento es un bonus simple por punto
public class ExtraTalents {

	public enum Kind { DMG, LOWDMG, REDUCE, KILLHEAL_PCT, KILLHEAL_FLAT, XP, GOLD, MAXHP, ACC, EVA, SPEED }

	private static class Effect {
		final Kind kind; final float perPoint;
		Effect(Kind kind, float perPoint){ this.kind = kind; this.perPoint = perPoint; }
	}

	private static final LinkedHashMap<Talent, Effect> EFFECTS = new LinkedHashMap<>();
	private static final EnumMap<HeroClass, Talent[][]> CLASS = new EnumMap<>(HeroClass.class);
	private static final EnumMap<HeroSubClass, Talent[]> SUB = new EnumMap<>(HeroSubClass.class);

	static {
		EFFECTS.put(Talent.TEMPLE_SOLAR, new Effect(Kind.MAXHP, 10.0f));
		EFFECTS.put(Talent.ACERO_BRILLANTE, new Effect(Kind.REDUCE, 0.04f));
		EFFECTS.put(Talent.GOLPE_RADIANTE, new Effect(Kind.DMG, 0.05f));
		EFFECTS.put(Talent.BRASAS_VIVAS, new Effect(Kind.LOWDMG, 0.1f));
		EFFECTS.put(Talent.DISCIPLINA_DE_HIERRO, new Effect(Kind.ACC, 0.08f));
		EFFECTS.put(Talent.BOTIN_DORADO, new Effect(Kind.GOLD, 0.15f));
		EFFECTS.put(Talent.MARCHA_FIRME, new Effect(Kind.SPEED, 0.05f));
		EFFECTS.put(Talent.PULSO_DE_COMBATE, new Effect(Kind.KILLHEAL_FLAT, 1.0f));
		EFFECTS.put(Talent.GUARDIA_DORADA, new Effect(Kind.EVA, 0.08f));
		EFFECTS.put(Talent.CORAZON_DE_LEON, new Effect(Kind.MAXHP, 15.0f));
		EFFECTS.put(Talent.ESPADA_ARDIENTE, new Effect(Kind.DMG, 0.08f));
		EFFECTS.put(Talent.CORONA_SOLAR, new Effect(Kind.DMG, 0.1f));
		EFFECTS.put(Talent.FUEGO_INTERIOR, new Effect(Kind.LOWDMG, 0.15f));
		EFFECTS.put(Talent.ESCUDO_DE_LUZ, new Effect(Kind.REDUCE, 0.05f));
		EFFECTS.put(Talent.PIEL_DE_ROCA, new Effect(Kind.REDUCE, 0.05f));
		EFFECTS.put(Talent.PISOTON, new Effect(Kind.DMG, 0.1f));
		EFFECTS.put(Talent.VIGOR_COLOSAL, new Effect(Kind.MAXHP, 20.0f));
		EFFECTS.put(Talent.PASO_SOMBRIO, new Effect(Kind.SPEED, 0.05f));
		EFFECTS.put(Talent.OJO_NOCTURNO, new Effect(Kind.ACC, 0.08f));
		EFFECTS.put(Talent.MANTO_DE_SOMBRA, new Effect(Kind.EVA, 0.08f));
		EFFECTS.put(Talent.FILO_SEDIENTO, new Effect(Kind.KILLHEAL_FLAT, 1.0f));
		EFFECTS.put(Talent.DAGA_OCULTA, new Effect(Kind.DMG, 0.05f));
		EFFECTS.put(Talent.CAZADORA, new Effect(Kind.XP, 0.1f));
		EFFECTS.put(Talent.PULSO_LUNAR, new Effect(Kind.MAXHP, 8.0f));
		EFFECTS.put(Talent.VELO_ESPECTRAL, new Effect(Kind.REDUCE, 0.04f));
		EFFECTS.put(Talent.SAQUEO, new Effect(Kind.GOLD, 0.15f));
		EFFECTS.put(Talent.SENTIDOS_AFILADOS, new Effect(Kind.ACC, 0.1f));
		EFFECTS.put(Talent.ASESINATO_FANTASMA, new Effect(Kind.DMG, 0.08f));
		EFFECTS.put(Talent.ECLIPSE, new Effect(Kind.DMG, 0.1f));
		EFFECTS.put(Talent.CACERIA, new Effect(Kind.KILLHEAL_PCT, 0.02f));
		EFFECTS.put(Talent.DANZA_LETAL, new Effect(Kind.SPEED, 0.08f));
		EFFECTS.put(Talent.FORMA_ETEREA, new Effect(Kind.EVA, 0.1f));
		EFFECTS.put(Talent.TACTO_GELIDO, new Effect(Kind.REDUCE, 0.05f));
		EFFECTS.put(Talent.ALMA_ROBADA, new Effect(Kind.KILLHEAL_PCT, 0.03f));
		EFFECTS.put(Talent.MENTE_LUCIDA, new Effect(Kind.XP, 0.1f));
		EFFECTS.put(Talent.CHISPA, new Effect(Kind.DMG, 0.05f));
		EFFECTS.put(Talent.BARRERA_ESTATICA, new Effect(Kind.REDUCE, 0.04f));
		EFFECTS.put(Talent.RESERVA_ARCANA, new Effect(Kind.MAXHP, 8.0f));
		EFFECTS.put(Talent.PUNTERIA_ARCANA, new Effect(Kind.ACC, 0.08f));
		EFFECTS.put(Talent.PASOS_DE_VIENTO, new Effect(Kind.SPEED, 0.05f));
		EFFECTS.put(Talent.FORTUNA_DEL_MAGO, new Effect(Kind.GOLD, 0.15f));
		EFFECTS.put(Talent.AURA_DE_TORMENTA, new Effect(Kind.EVA, 0.08f));
		EFFECTS.put(Talent.ESTUDIO_PROFUNDO, new Effect(Kind.XP, 0.1f));
		EFFECTS.put(Talent.MAESTRIA_ELEMENTAL, new Effect(Kind.DMG, 0.08f));
		EFFECTS.put(Talent.MENTE_BLINDADA, new Effect(Kind.REDUCE, 0.05f));
		EFFECTS.put(Talent.TRUENO, new Effect(Kind.DMG, 0.1f));
		EFFECTS.put(Talent.SOBRECARGA, new Effect(Kind.LOWDMG, 0.15f));
		EFFECTS.put(Talent.RELAMPAGO_VITAL, new Effect(Kind.KILLHEAL_PCT, 0.02f));
		EFFECTS.put(Talent.ESCUDO_ARCANO, new Effect(Kind.REDUCE, 0.05f));
		EFFECTS.put(Talent.MENTE_MAESTRA, new Effect(Kind.XP, 0.15f));
		EFFECTS.put(Talent.TORRE_DE_MANA, new Effect(Kind.MAXHP, 20.0f));
		CLASS.put(HeroClass.KAEL, new Talent[][]{{TEMPLE_SOLAR, ACERO_BRILLANTE, GOLPE_RADIANTE, BRASAS_VIVAS}, {DISCIPLINA_DE_HIERRO, BOTIN_DORADO, MARCHA_FIRME, PULSO_DE_COMBATE, GUARDIA_DORADA}, {CORAZON_DE_LEON, ESPADA_ARDIENTE}});
		CLASS.put(HeroClass.NYX, new Talent[][]{{PASO_SOMBRIO, OJO_NOCTURNO, MANTO_DE_SOMBRA, FILO_SEDIENTO}, {DAGA_OCULTA, CAZADORA, PULSO_LUNAR, VELO_ESPECTRAL, SAQUEO}, {SENTIDOS_AFILADOS, ASESINATO_FANTASMA}});
		CLASS.put(HeroClass.ORIN, new Talent[][]{{MENTE_LUCIDA, CHISPA, BARRERA_ESTATICA, RESERVA_ARCANA}, {PUNTERIA_ARCANA, PASOS_DE_VIENTO, FORTUNA_DEL_MAGO, AURA_DE_TORMENTA, ESTUDIO_PROFUNDO}, {MAESTRIA_ELEMENTAL, MENTE_BLINDADA}});
		SUB.put(HeroSubClass.SOLAR, new Talent[]{CORONA_SOLAR, FUEGO_INTERIOR, ESCUDO_DE_LUZ});
		SUB.put(HeroSubClass.COLOSO, new Talent[]{PIEL_DE_ROCA, PISOTON, VIGOR_COLOSAL});
		SUB.put(HeroSubClass.SOMBRA, new Talent[]{ECLIPSE, CACERIA, DANZA_LETAL});
		SUB.put(HeroSubClass.ESPECTRO, new Talent[]{FORMA_ETEREA, TACTO_GELIDO, ALMA_ROBADA});
		SUB.put(HeroSubClass.TORMENTA, new Talent[]{TRUENO, SOBRECARGA, RELAMPAGO_VITAL});
		SUB.put(HeroSubClass.ARCANO, new Talent[]{ESCUDO_ARCANO, MENTE_MAESTRA, TORRE_DE_MANA});
	}

	public static boolean isExtra(HeroClass cls){ return CLASS.containsKey(cls); }

	public static List<Talent> classTalents(HeroClass cls, int tier){ return Arrays.asList(CLASS.get(cls)[tier]); }

	public static List<Talent> subclassTalents(HeroSubClass sub){ return Arrays.asList(SUB.get(sub)); }

	public static boolean has(Talent t){ return EFFECTS.containsKey(t); }

	//suma de los bonus de ese tipo segun los puntos gastados (0 para los heroes originales)
	public static float bonus(Hero hero, Kind kind){
		if (hero == null || !isExtra(hero.heroClass)) return 0f;
		float sum = 0f;
		for (Map.Entry<Talent, Effect> e : EFFECTS.entrySet()){
			if (e.getValue().kind == kind){
				int p = hero.pointsInTalent(e.getKey());
				if (p > 0) sum += p * e.getValue().perPoint;
			}
		}
		return sum;
	}
}
