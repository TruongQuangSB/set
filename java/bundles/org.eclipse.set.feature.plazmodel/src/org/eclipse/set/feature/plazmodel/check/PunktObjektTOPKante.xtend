/**
 * Copyright (c) 2022 DB Netz AG and others.
 * 
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v2.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v20.html
 */
package org.eclipse.set.feature.plazmodel.check

import java.util.List
import java.util.Map
import org.eclipse.set.model.plazmodel.PlazError
import org.eclipse.set.model.plazmodel.PlazFactory
import org.eclipse.set.ppmodel.extensions.container.MultiContainer_AttributeGroup
import org.eclipse.set.model.planpro.Basisobjekte.Punkt_Objekt_TOP_Kante_AttributeGroup
import org.osgi.service.component.annotations.Component

import static extension org.eclipse.set.ppmodel.extensions.PunktObjektTopKanteExtensions.*

/**
 * Validates that GUID references point to object which exists
 * 
 * @author Stuecker
 */
@Component
class PunktObjektTOPKante extends AbstractPlazContainerCheck implements PlazCheck {
	override List<PlazError> run(MultiContainer_AttributeGroup container) {
		return container.allContents.filter(
			Punkt_Objekt_TOP_Kante_AttributeGroup).map [
			val distance = it.abstand?.wert
			val topLength = it.topKante?.TOPKanteAllg?.TOPLaenge?.wert
			if (distance === null || topLength === null)
				return null;
			val generalErroMsg = transformErrorMsg(Map.of("Distance", distance.toString))
			if (distance.doubleValue < 0) {
				val err = PlazFactory.eINSTANCE.createPlazError
				err.message = '''«generalErroMsg» Der Punktobjektabstand darf nicht negativ sein.'''
				err.type = checkType
				err.object = it.abstand
				return err
			} else if (distance > topLength) {
				val err = PlazFactory.eINSTANCE.createPlazError
				err.message = '''«generalErroMsg» Länge TOP-Kante: «topLength».'''
				err.type = checkType
				err.object = it.abstand
				return err
			}
			return null
		].filterNull.toList
	}
	
	override checkType() {
		return "Punktobjektabstand"
	}
	
	override getDescription() {
		return "Der Punktobjektabstand aller LST-Objekte ist gültig."
	}
	
	override getGeneralErrMsg() {
		return "Ungültiger Punktobjektabstand für LST-Objekt Abstand: {Distance}."
	}
}
