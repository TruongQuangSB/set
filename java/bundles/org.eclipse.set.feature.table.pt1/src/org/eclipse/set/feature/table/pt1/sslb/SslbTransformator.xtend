/**
 * Copyright (c) 2017 DB Netz AG and others.
 * 
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v2.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v20.html
 */
package org.eclipse.set.feature.table.pt1.sslb

import org.eclipse.set.basis.Pair
import org.eclipse.set.core.services.enumtranslation.EnumTranslationService
import org.eclipse.set.feature.table.pt1.AbstractPlanPro2TableModelTransformator
import org.eclipse.set.model.tablemodel.Table
import org.eclipse.set.model.tablemodel.TableRow
import org.eclipse.set.model.tablemodel.format.TextAlignment
import org.eclipse.set.ppmodel.extensions.container.MultiContainer_AttributeGroup
import org.eclipse.set.ppmodel.extensions.utils.Case
import org.eclipse.set.toolboxmodel.Block.Block_Element
import org.eclipse.set.toolboxmodel.Geodaten.ENUMOertlichkeitArt
import org.eclipse.set.utils.table.TMFactory

import static extension org.eclipse.set.model.tablemodel.extensions.TableExtensions.*
import static extension org.eclipse.set.ppmodel.extensions.BasisAttributExtensions.*
import static extension org.eclipse.set.ppmodel.extensions.BedienAnrueckabschnittExtensions.*
import static extension org.eclipse.set.ppmodel.extensions.BedienAnzeigeElementExtensions.*
import static extension org.eclipse.set.ppmodel.extensions.BereichObjektExtensions.*
import static extension org.eclipse.set.ppmodel.extensions.BlockAnlageExtensions.*
import static extension org.eclipse.set.ppmodel.extensions.BlockElementExtensions.*
import static extension org.eclipse.set.ppmodel.extensions.BlockStreckeExtensions.*
import static org.eclipse.set.feature.table.pt1.sslb.SslbColumns.*
import java.util.Set
import org.eclipse.set.model.tablemodel.ColumnDescriptor

/**
 * Table transformation for a Inselgleistabelle (Sslb).
 * 
 * @author Rumpf
 */
class SslbTransformator extends AbstractPlanPro2TableModelTransformator {

	var TMFactory factory = null

	new(Set<ColumnDescriptor> cols,
		EnumTranslationService enumTranslationService) {
		super(cols, enumTranslationService)
	}

	override transformTableContent(MultiContainer_AttributeGroup container,
		TMFactory factory) {
		this.factory = factory
		return container.transform
	}

	private def Table create factory.table transform(
		MultiContainer_AttributeGroup container) {
		container.blockElement.forEach [ it |
			if (Thread.currentThread.interrupted) {
				return
			}
			it.transform
		]
		return
	}

	private def TableRow create factory.newTableRow(blockElement) transform(
		Block_Element blockElement) {

		val row = it
		// A: Sslb.Strecke.Nummer
		fill(
			cols.getColumn(Strecke_Nummer),
			blockElement,
			[
				blockElement?.blockStrecke?.strecke?.bezeichnung?.
					bezeichnungStrecke?.wert
			]
		)

		// B: Sslb.Strecke.Gleis
		fillIterable(
			cols.getColumn(Strecke_Gleis),
			blockElement,
			[
				blockElement.blockAnlagenStart.map [
					gleisBezeichnung?.bezeichnung?.bezGleisBezeichnung?.wert
				]
			],
			MIXED_STRING_COMPARATOR,
			[it]
		)

		// C: Sslb.Strecke.Betriebsfuehrung
		fill(
			cols.getColumn(Betriebsfuehrung),
			blockElement,
			[
				blockElement?.blockStrecke?.blockStreckeAllg?.betriebsfuehrung?.
					wert?.translate
			]
		)

		// D: Sslb.Grundsatzangaben.von.Betriebsstelle_Start
		fillConditional(
			cols.getColumn(Betriebsstelle_Start),
			blockElement,
			[!blockElement.blockAnlagenStart.isEmpty],
			[
				blockElement?.blockStrecke?.oertlichkeit?.bezeichnung?.
					oertlichkeitAbkuerzung?.wert
			]
		)

		// E: Sslb.Grundsatzangaben.von.Bauform_Start
		fillConditional(
			cols.getColumn(Bauform_Start),
			blockElement,
			[!blockElement.blockAnlagenStart.isEmpty],
			[blockElement?.blockElementAllg?.blockBauform?.wert?.translate]
		)

		// F: Sslb.Grundsatzangaben.nach.Betriebsstelle_Ziel
		fillConditional(
			cols.getColumn(Betriebsstelle_Ziel),
			blockElement,
			[!blockElement.blockAnlagenZiel.isEmpty],
			[
				blockElement?.blockStrecke?.oertlichkeit?.bezeichnung?.
					oertlichkeitAbkuerzung?.wert
			]
		)

		// G: Sslb.Grundsatzangaben.nach.Bauform_Ziel
		fillConditional(
			cols.getColumn(Bauform_Ziel),
			blockElement,
			[!blockElement.blockAnlagenZiel.isEmpty],
			[blockElement?.blockElementAllg?.blockBauform?.wert?.translate]
		)

		// H: Sslb.Grundsatzangaben.Blockschaltung
		fillIterable(
			cols.getColumn(Blockschaltung),
			blockElement,
			[
				blockElement.blockAnlagenStart.map [
					blockAnlageAllg?.schaltung?.wert?.translate
				]
			],
			null,
			[it]
		)

		// I: Sslb.Grundsatzangaben.Schutzuebertrager
		fillIterable(
			cols.getColumn(Schutzuebertrager),
			blockElement,
			[
				blockElement.blockAnlagenStart.map [
					blockAnlageAllg?.schutzuebertrager?.wert?.translate
				]
			],
			null,
			[it]
		)

		// J: Sslb.Erlaubnis.staendig
		fill(
			cols.getColumn(Erlaubnis_staendig),
			blockElement,
			[
				blockElement.blockElementErlaubnis?.erlaubnisStaendigVorhanden?.
					wert?.translate
			]
		)

		// K: Sslb.Erlaubnis.holen
		fillSwitch(
			cols.getColumn(Erlaubnis_holen),
			blockElement,
			new Case<Block_Element>(
				[
					blockElement?.blockElementErlaubnis?.autoErlaubnisholen?.
						wert == Boolean.TRUE
				],
				["auto"]
			),
			new Case<Block_Element>(
				[
					blockElement?.blockElementErlaubnis?.erlaubnisholen?.wert ==
						Boolean.TRUE
				],
				["manuell"]
			)
		)

		// L: Sslb.Erlaubnis.Ruecklauf_autom
		fill(
			cols.getColumn(Erlaubnis_Ruecklauf_autom),
			blockElement,
			[
				blockElement?.blockElementErlaubnis?.autoErlaubnisruecklauf?.
					wert?.translate
			]
		)

		// M: Sslb.Erlaubnis.Abgabespeicherung
		fill(
			cols.getColumn(Erlaubnis_Abgabespeicherung),
			blockElement,
			[
				blockElement?.blockElementErlaubnis?.
					erlaubnisabgabespeicherung?.wert?.translate
			]
		)

		// N: Sslb.Erlaubnis.Abh_D_Weg_Rf
		fillConditional(
			cols.getColumn(Erlaubnis_Abh_D_Weg_Rf),
			blockElement,
			[
				blockElement.signal !== null ||
					blockElement.fstrZugRangier !== null
			],
			["x"]
		)

		val gleisabschnittAnordnung = newLinkedList
		// O: Sslb.Blockmeldung.Anrueckabschnitt.Bezeichnung 
		fillIterable(
			cols.getColumn(Anrueckabschnitt_Bezeichnung),
			blockElement,
			[
				val gleisbezeichnungenStart = blockAnlagenStart.map [
					gleisBezeichnung
				].toList
				val gleisbezeichnungenZiel = blockAnlagenZiel.map [
					gleisBezeichnung
				].toList
				val gleisbezeichnungenList = newLinkedList
				gleisbezeichnungenList.addAll(gleisbezeichnungenStart)
				gleisbezeichnungenList.addAll(gleisbezeichnungenZiel)
				val gleisbezeichnungen = gleisbezeichnungenList.toSet
				val anrueckGleisAbschnittPairs = it.container.
					bedienAnrueckabschnitt.map [
						new Pair(it, gleisAbschnittPosition)
					].filter [
						val anrueckGleisAbschnittPair = it
						gleisbezeichnungen.exists [
							it.intersects(anrueckGleisAbschnittPair.second)
						]
					]
				gleisabschnittAnordnung.addAll(anrueckGleisAbschnittPairs.map [
					second
				])
				anrueckGleisAbschnittPairs.map[first].map [
					var gleisAbschnittDarstellen = gleisAbschnittDarstellen
					if (gleisAbschnittDarstellen !== null) {
						gleisAbschnittDarstellen?.bezeichnung?.
							bezeichnungTabelle?.wert ?: ""
					} else {
						bezeichnung?.bezBedAnrueckabschnitt?.wert ?: ""
					}
				]
			],
			MIXED_STRING_COMPARATOR,
			[it]
		)

		// P: Sslb.Blockmeldung.Anrueckabschnitt.Anordnung
		fillIterable(
			cols.getColumn(Anrueckabschnitt_Anordnung),
			blockElement,
			[
				gleisabschnittAnordnung.map [
					bezeichnung?.bezeichnungTabelle?.wert ?: ""
				]
			],
			MIXED_STRING_COMPARATOR,
			[it]
		)

		// Q: Sslb.Blockmeldung.Zugschluss
		fill(
			cols.getColumn(Blockmeldung_Zugschluss),
			blockElement,
			[
				blockElement?.bedienanzeigeElement?.bedienEinrichtungOertlich?.
					bezeichnung?.bedienEinrichtOertlBez?.wert
			]
		)

		// R: Sslb.Blockmeldung.Raeumungspruefung
		fill(
			cols.getColumn(Blockmeldung_Raeumungspruefung),
			blockElement,
			[blockElement?.raeumungspruefung]
		)

		// S: Sslb.Akustische_Meldung.Vorblock
		fill(
			cols.getColumn(Akustische_Meldung_Vorblock),
			blockElement,
			[blockElement?.blockElementAllg?.vorblockwecker?.wert?.translate]
		)

		// T: Sslb.Akustische_Meldung.Rueckblock
		fill(
			cols.getColumn(Akustische_Meldung_Rueckblock),
			blockElement,
			[blockElement?.blockElementAllg?.rueckblockwecker?.wert?.translate]
		)

		// U: Sslb.Awanst.Bez_Bed
		fillConditional(
			cols.getColumn(Awanst_Bez_Bed),
			blockElement,
			[
				blockElement.blockStrecke?.oertlichkeit?.bezeichnung?.
					oertlichkeitAbkuerzung !== null &&
					blockElement.blockStrecke?.oertlichkeit?.oertlichkeitAllg?.
						oertlichkeitArt?.wert ===
						ENUMOertlichkeitArt.ENUM_OERTLICHKEIT_ART_AWANST
			],
			[
				blockElement.blockStrecke?.oertlichkeit?.bezeichnung?.
					oertlichkeitAbkuerzung?.wert
			]
		)

		// V: Sslb.Bemerkung
		fill(
			cols.getColumn(Bemerkung),
			blockElement,
			[footnoteTransformation.transform(it, row)]
		)

		return
	}

	override void formatTableContent(Table table) {
		// D: Sslb.Grundsatzangaben.von.Betriebsst_Start
		table.setTextAlignment(3, TextAlignment.LEFT);

		// F: Sslb.Grundsatzangaben.nach.Betriebsst_Ziel
		table.setTextAlignment(5, TextAlignment.LEFT);

		// V: Sslb.Bemerkung
		table.setTextAlignment(21, TextAlignment.LEFT);
	}
}