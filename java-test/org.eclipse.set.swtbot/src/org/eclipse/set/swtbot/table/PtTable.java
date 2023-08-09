/**
 * Copyright (c) 2023 Scheidt & Bachmann System Technik GmbH.
 * All rights reserved.
 */
package org.eclipse.set.swtbot.table;

import java.util.List;

/**
 * @author truong
 * @param shortcut
 *            table shortcut
 * @param tableName
 *            the table name
 * @param fixedColumns
 *            index of fixed column
 *
 */
public record PtTable(String shortcut, String tableName,
		List<Integer> fixedColumns) {
	/**
	 * List table to test
	 */
	@SuppressWarnings("boxing")
	public static List<PtTable> tablesToTest = List.of(
			new PtTable("ssbb", "Ssbb (Bedieneinrichtungstabelle BÜ)",
					List.of(0)),
			new PtTable("ssit", "Ssit (Bedieneinrichtungstabelle Stw)",
					List.of(0)),
			new PtTable("sska", "Sska (Elementansteuertabelle)", List.of(0)),
			new PtTable("sskf", "Sskf (Freimeldetabelle)", List.of(0)),
			new PtTable("sskg", "Sskg (Gleisschaltmitteltabelle)", List.of(0)),
			new PtTable("ssko", "Ssko (Schlosstabelle)", List.of(0)),
			new PtTable("ssks", "Ssks (Signaltabelle)", List.of(0)),
			new PtTable("sskt",
					"Sskt (Tabelle der Technik- und Bedienstandorte)",
					List.of(0)),
			new PtTable("sskw", "Sskw (Weichentabelle)", List.of(0)),
			new PtTable("ssla",
					"Ssla (Tabelle der aneinandergereihten Fahrstraßen)",
					List.of(0)),
			new PtTable("sslb", "Sslb (Streckenblocktabelle)", List.of(0)),
			new PtTable("ssld", "Ssld (Durchrutschweg- und Gefahrpunkttabelle)",
					List.of(0, 1, 2)),
			new PtTable("sslf", "Sslf (Flankenschutztabelle)", List.of(0, 1)),
			new PtTable("ssli", "Ssli (Inselgleistabelle)", List.of(0)),
			new PtTable("ssln", "Ssln (Nahbedientabelle)", List.of(0)),
			new PtTable("sslr", "Sslr (Rangierstraßentabelle)", List.of(0)),
			new PtTable("sslw", "Sslw (Zwieschutzweichentabelle)", List.of(0)),
			new PtTable("sslz", "Sslz (Zugstraßentabelle)", List.of(0)),
			new PtTable("ssvu", "Ssvu (Übertragungswegtabelle)",
					List.of(0, 1)));
}
