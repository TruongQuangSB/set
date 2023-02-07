/**
 * Copyright (c) 2016 DB Netz AG and others.
 * 
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v2.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v20.html
 */
package org.eclipse.set.feature.table.pt1.ssko;

import org.eclipse.set.core.services.enumtranslation.EnumTranslationService
import org.eclipse.set.feature.table.pt1.AbstractPlanPro2TableModelTransformator
import org.eclipse.set.model.tablemodel.Table
import org.eclipse.set.model.tablemodel.format.TextAlignment
import org.eclipse.set.ppmodel.extensions.container.MultiContainer_AttributeGroup
import org.eclipse.set.ppmodel.extensions.utils.Case
import org.eclipse.set.toolboxmodel.Fahrstrasse.Fstr_Zug_Rangier
import org.eclipse.set.toolboxmodel.Schluesselabhaengigkeiten.Schloss
import org.eclipse.set.toolboxmodel.Schluesselabhaengigkeiten.Schluesselsperre
import org.eclipse.set.utils.table.TMFactory

import static extension org.eclipse.set.model.tablemodel.extensions.TableExtensions.*
import static extension org.eclipse.set.ppmodel.extensions.BasisAttributExtensions.*
import static extension org.eclipse.set.ppmodel.extensions.FahrwegExtensions.*
import static extension org.eclipse.set.ppmodel.extensions.FstrAbhaengigkeitExtensions.*
import static extension org.eclipse.set.ppmodel.extensions.FstrZugRangierExtensions.*
import static extension org.eclipse.set.ppmodel.extensions.SchlossExtensions.*
import static extension org.eclipse.set.ppmodel.extensions.SchlosskombinationExtensions.*
import static extension org.eclipse.set.ppmodel.extensions.SchluesselsperreExtensions.*
import static extension org.eclipse.set.ppmodel.extensions.UnterbringungExtensions.*
import static extension org.eclipse.set.ppmodel.extensions.WKrGspElementExtensions.*

/**
 * Table transformation for a Schlosstabelle Entwurf (Ssko).
 * 
 * @author Rumpf
 */
class SskoTransformator extends AbstractPlanPro2TableModelTransformator {

	SskoColumns cols;

	new(SskoColumns columns, EnumTranslationService enumTranslationService) {
		super(enumTranslationService)
		this.cols = columns;
	}

	override transformTableContent(MultiContainer_AttributeGroup container,
		TMFactory factory) {
		for (Schloss schloss : container.schloss) {
			if (Thread.currentThread.interrupted) {
				return null
			}
			val instance = factory.newTableRow(schloss)

			// A: Ssko.Grundsatzangaben.Bezeichnung_Schloss
			fill(
				instance,
				cols.bezeichnung_schloss,
				schloss,
				[bezeichnung?.bezeichnungSchloss?.wert]
			);

			// B: Ssko.Grundsatzangaben.Schloss_an
			fillSwitch(
				instance,
				cols.schloss_an,
				schloss,
				new Case<Schloss>(
					[schlossBUE !== null],
					["BÜ"]
				),
				new Case<Schloss>(
					[schlossGsp !== null],
					["Gsp"]
				),
				new Case<Schloss>(
					[schlossSonderanlage !== null],
					["Sonder"]
				),
				new Case<Schloss>(
					[schlossSsp !== null],
					["Ssp"]
				),
				new Case<Schloss>(
					[schlossW !== null],
					["W"]
				)
			)

			// C: Ssko.Grundsatzangaben.Grundstellung_eingeschl
			fill(instance, cols.grundstellung_eingeschl, schloss, [
				schluesselInGrdstEingeschl?.wert?.translate
			])

			// D: Ssko.Schluessel.Bezeichnung
			fill(instance, cols.schluessel_bezeichnung, schloss, [
				schluesel?.bezeichnung?.bezeichnungSchluessel?.wert
			])

			// E: Ssko.Schluessel.Bartform
			fill(instance, cols.bartform, schloss, [
				schluesel?.schluesselAllg?.schluesselBartform?.wert?.translate
			])

			// F: Ssko.Schluessel.Gruppe
			fill(instance, cols.gruppe, schloss, [
				schluesel?.schluesselAllg?.schluesselGruppe?.wert?.translate
			])

			// G: Ssko.Fahrweg.Bezeichnung.Zug
			fillIterable(instance, cols.fahrwegZug, schloss, [
				schluesselsperre?.fstrZugRangier?.filter[fstrZug !== null]?.map[fstrName]?.toSet ?: #[]
			], null)

			// H: Ssko.Fahrweg.Bezeichnung.Rangier
			fillIterable(instance, cols.fahrwegRangier, schloss, [
				schluesselsperre?.fstrZugRangier?.filter[fstrRangier !== null]?.map[fstrName]?.toSet ?: #[]
			], null)
			
			// I: Ssko.W_Gsp_Bue.Verschl_Element.Bezeichnung
			fillSwitch(
				instance,
				cols.wgspbue_bezeichnung,
				schloss,
				new Case<Schloss>(
					[schlossBUE !== null],
					[bueAnlage?.bezeichnung?.bezeichnungTabelle?.wert]
				),
				new Case<Schloss>(
					[schlossGsp !== null],
					[gspElement?.bezeichnung?.bezeichnungTabelle?.wert]
				),
				new Case<Schloss>(
					[schlossW?.IDWKrElement !== null],
					[getWKrElement?.bezeichnung?.bezeichnungTabelle?.wert]
				)
			)

			// J: Ssko.W_Gsp_Bue.Verschl_Element.Lage
			fillSwitch(
				instance,
				cols.lage,
				schloss,
				new Case<Schloss>(
					[schlossBUE !== null],
					[schlossBUE.BUELage?.wert?.translate ?: ""]
				),
				new Case<Schloss>(
					[schlossGsp !== null],
					[schlossGsp.gspLage?.wert?.translate ?: ""]
				),
				new Case<Schloss>(
					[schlossW !== null],
					[schlossW.WLage?.wert?.translate ?: ""]
				)
			)

			// K: Ssko.W_Gsp_Bue.Verschl_Element.Komponente
			fillSwitch(
				instance,
				cols.komponente,
				schloss,
				new Case<Schloss>(
					[
						!WKrElement.WKrGspKomponenten.map[zungenpaar].
							filterNull.empty &&
							(schlossW?.verschlussHerzstueck === null ||
								!schlossW.verschlussHerzstueck.wert
							)
					],
					["Zunge"]
				),
				new Case<Schloss>(
					[
						!WKrElement.WKrGspKomponenten.map[zungenpaar].
							filterNull.empty &&
							(schlossW?.verschlussHerzstueck !== null &&
								schlossW.verschlussHerzstueck.wert
							)
					],
					["Zunge + Herzstück"]
				),
				new Case<Schloss>(
					[
						WKrElement.WKrGspKomponenten.map[zungenpaar].
							filterNull.empty &&
							(schlossW?.verschlussHerzstueck !== null &&
								schlossW.verschlussHerzstueck.wert
							)
					],
					["Herzstück"]
				)
			)

			// L: Ssko.W_Gsp_Bue.Schlossart
			fill(instance, cols.schlossart, schloss, [
				schloss?.schlossW?.schlossArt?.wert?.translate
			])

			// M: Ssko.Sk_Ssp.Bezeichnung
			fillSwitch(
				instance,
				cols.sk_ssp_bezeichnung,
				schloss,
				new Case<Schloss>(
					[schlossSk !== null],
					[schlossKombination?.bezeichnung?.bezeichnungSk?.wert]
				),
				new Case<Schloss>(
					[schlossSsp !== null],
					[schluesselsperre?.bezeichnung?.bezeichnungTabelle?.wert]
				)
			)

			// N: Ssko.Sk_Ssp.Hauptschloss
			fill(instance, cols.hauptschloss, schloss, [
				schloss?.schlossSk?.hauptschloss?.wert?.translate
			]);

			// O: Ssko.Sk_Ssp.Unterbringung.Art
			fillSwitch(
				instance,
				cols.unterbringung_art,
				schloss,
				new Case<Schloss>(
					[schlossSk !== null],
					[
						schlossKombination?.unterbringung?.unterbringungAllg?.
							unterbringungArt?.wert?.translate
					]
				),
				new Case<Schloss>(
					[schlossSsp !== null],
					[
						schluesselsperre?.unterbringung?.unterbringungAllg?.
							unterbringungArt?.wert?.translate
					]
				)
			)

			// P: Ssko.Sk_Ssp.Unterbringung.Ort
			fillSwitch(
				instance,
				cols.unterbringung_ort,
				schloss,
				new Case<Schloss>(
					[schlossSk !== null],
					[
						schlossKombination?.unterbringung?.
							standortBeschreibung?.wert
					]
				),
				new Case<Schloss>(
					[schlossSsp !== null],
					[
						schluesselsperre?.unterbringung?.
							standortBeschreibung?.wert
					]
				)
			)

			// Q: Ssko.Sk_Ssp.Unterbringung.Strecke
			fillSwitch(
				instance,
				cols.unterbringung_strecke,
				schloss,
				new Case<Schloss>(
					[schlossSk !== null],
					[
						schlossKombination?.unterbringung?.strecken?.map [
							bezeichnung?.bezeichnungStrecke.wert
						].getIterableFilling(null)
					]
				),
				new Case<Schloss>(
					[schlossSsp !== null],
					[
						schluesselsperre?.unterbringung?.strecken.map [
							bezeichnung?.bezeichnungStrecke?.wert
						].getIterableFilling(null)
					]
				)
			)

			// R: Ssko.Sk_Ssp.Unterbringung.km
			fillSwitch(
				instance,
				cols.unterbringung_km,
				schloss,
				new Case<Schloss>(
					[schlossSk !== null],
					[
						schlossKombination?.unterbringung?.punktObjektStrecke.
							map[streckeKm?.wert].getIterableFilling(null)
					]
				),
				new Case<Schloss>(
					[schlossSsp !== null],
					[
						schluesselsperre?.unterbringung?.punktObjektStrecke.map [
							streckeKm?.wert
						].getIterableFilling(null)
					]
				)
			)

			// S: Ssko.Sonderanlage
			fillSwitch(
				instance,
				cols.sonderanlage,
				schloss,
				new Case<Schloss>(
				[schloss?.schlossSonderanlage !== null], [
					schloss?.sonderanlage?.bezeichnung?.bezeichnungTabelle?.wert
				]),
				new Case<Schloss>(
				[schloss?.schlossSonderanlage?.beschreibungSonderanlage !== null], [
					schlossSonderanlage?.beschreibungSonderanlage?.wert
				])
			)

			// T: Ssko.Technisch_Berechtigter
			fillConditional(
				instance,
				cols.Technisch_Berechtigter,
				schloss,
				[technischBerechtigter?.wert !== null],
				[(technischBerechtigter.wert.translate)]
			)

			// U: Ssko.Bemerkung
			fill(
				instance,
				cols.basis_bemerkung,
				schloss,
				[footnoteTransformation.transform(it, instance)]
			)

		}

		return factory.table
	}

	private def Iterable<Fstr_Zug_Rangier> getFstrZugRangier(
		Schluesselsperre schluesselsperre) {
		val c = schluesselsperre.container
		return c.fstrAbhaengigkeit.filter [
			fstrAbhaengigkeitSsp?.IDSchluesselsperre === schluesselsperre
		].flatMap [
			val fahrweg = it.fstrFahrweg
			c.fstrZugRangier.filter[IDFstrFahrweg === fahrweg]
		].toSet
	}

	private def String fstrName(
		Fstr_Zug_Rangier fstrZugRangier
	) {
		val fstrFahrweg = fstrZugRangier?.fstrFahrweg
		return '''«fstrFahrweg?.start?.bezeichnung?.bezeichnungTabelle?.wert»/«fstrFahrweg?.zielSignal?.bezeichnung?.bezeichnungTabelle?.wert»'''
	}

	override void formatTableContent(Table table) {
		// A: Grundsatzangaben.Bezeichnung_Schloss
		table.setTextAlignment(0, TextAlignment.LEFT);

		// P: Sk_Ssp.Unterbringung.km
		table.setTextAlignment(15, TextAlignment.RIGHT);

		// S: Bemerkung
		table.setTextAlignment(18, TextAlignment.LEFT);
	}
}