/**
 * Copyright (c) 2023 Scheidt & Bachmann System Technik GmbH.
 * All rights reserved.
 */
package org.eclipse.set.swtbot.table;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;

import java.io.IOException;
import java.util.LinkedList;
import java.util.List;

import org.apache.commons.csv.CSVRecord;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.MethodSource;

/**
 * Compare table data with csv reference
 * 
 * @author truong
 *
 */
class TableDataTest extends AbstractTableTest {

	List<CSVRecord> referenceData = new LinkedList<>();

	private void thenPtTableDataEqualReferenceCSV() {
		for (int rowIndex = 0; rowIndex < nattableBot.rowCount(); rowIndex++) {
			for (int columnIndex = 0; columnIndex < nattableBot
					.columnCount(); columnIndex++) {
				// Skip first cell
				if (rowIndex == 0 && columnIndex == 0) {
					continue;
				}
				final String cellValue = nattableBot
						.getCellDataValueByPosition(rowIndex, columnIndex)
						.replaceAll("[\\n\\r]", "");
				final String referenceValue = referenceData.get(rowIndex)
						.get(columnIndex).replaceAll("[\\n\\r]", "");

				assertEquals(referenceValue, cellValue);
			}
		}
	}

	private void whenExistReferenceCSV() {
		assertNotNull(referenceData);
		assertFalse(referenceData.isEmpty());
	}

	private void whenNattableBotNotNull() {
		assertNotNull(nattableBot);
	}

	void givenReferenceCSV(final PtTable table) throws IOException {
		referenceData = loadReferenceFile(table.shortcut());

	}

	/**
	 * Compare table data with reference file
	 * 
	 * @throws Exception
	 */
	@ParameterizedTest
	@MethodSource("providesPtTable")
	void testTableData(final PtTable table) throws Exception {
		givenNattableBot(table);
		whenNattableBotNotNull();
		givenReferenceCSV(table);
		whenExistReferenceCSV();
		thenPtTableDataEqualReferenceCSV();
	}
}
