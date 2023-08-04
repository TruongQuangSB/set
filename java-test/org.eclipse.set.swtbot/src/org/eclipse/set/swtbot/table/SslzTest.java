/**
 * Copyright (c) 2023 DB Netz AG and others.
 * 
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v2.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v20.html
 */
package org.eclipse.set.swtbot.table;

/**
 * Sslz test
 */
public class SslzTest extends AbstractTableTest {

	@Override
	protected String getShortcut() {
		return "sslz";
	}

	@Override
	protected String getTableName() {
		return "Sslz (Zugstraßentabelle)";
	}
}
