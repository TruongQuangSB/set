/**
 * Copyright (c) 2022 DB Netz AG and others.
 * 
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v2.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v20.html
 */
package org.eclipse.set.feature.siteplan.transform

import org.eclipse.set.feature.siteplan.positionservice.PositionService
import org.eclipse.set.model.planpro.Weichen_und_Gleissperren.ENUMGleisAbschlussArt
import org.eclipse.set.model.planpro.Weichen_und_Gleissperren.Gleis_Abschluss
import org.eclipse.set.model.siteplan.SiteplanFactory
import org.eclipse.set.model.siteplan.SiteplanPackage
import org.eclipse.set.model.siteplan.TrackCloseType
import org.osgi.service.component.annotations.Component
import org.osgi.service.component.annotations.Reference
import org.eclipse.set.core.services.geometry.PointObjectPositionService

/**
 * Transform PlanPro trackclosures to Siteplan trackclosures
 * 
 * @author Truong
 */
@Component(service=Transformator)
class TrackCloseTransformator extends BaseTransformator<Gleis_Abschluss> {
	@Reference
	PointObjectPositionService pointObjectPositionService

	@Reference
	PositionService positionService

	override transform(Gleis_Abschluss trackClose) {
		val result = SiteplanFactory.eINSTANCE.createTrackClose
		result.guid = trackClose.identitaet.wert
		result.trackCloseType = transformType(
			trackClose.gleisAbschlussArt?.wert)
		result.position = positionService.transformPosition(
			pointObjectPositionService.getCoordinate(trackClose)
		)
		result.addSiteplanElement(
			SiteplanPackage.eINSTANCE.siteplanState_TrackClosures)
	}

	private def TrackCloseType transformType(ENUMGleisAbschlussArt type) {
		switch (type) {
			case ENUM_GLEIS_ABSCHLUSS_ART_BREMSPRELLBOCK:
				return TrackCloseType.FRICTION_BUFFER_STOP
			case ENUM_GLEIS_ABSCHLUSS_ART_FESTPRELLBOCK:
				return TrackCloseType.FIXED_BUFFER_STOP
			case ENUM_GLEIS_ABSCHLUSS_ART_KOPFRAMPE:
				return TrackCloseType.HEAD_RAMP
			case ENUM_GLEIS_ABSCHLUSS_ART_SCHWELLENKREUZ:
				return TrackCloseType.THRESHOLD_CROSS
			case ENUM_GLEIS_ABSCHLUSS_ART_DREHSCHEIBE:
				return TrackCloseType.TURN_TABLE
			case ENUM_GLEIS_ABSCHLUSS_ART_SCHIEBEBUEHNE:
				return TrackCloseType.SLIDING_STAGE
			case ENUM_GLEIS_ABSCHLUSS_ART_FAEHRANLEGER:
				return TrackCloseType.FERRY_DOCK
			case ENUM_GLEIS_ABSCHLUSS_ART_INFRASTRUKTURGRENZE:
				return TrackCloseType.INFRASTRUCTURE_BORDER
			case ENUM_GLEIS_ABSCHLUSS_ART_SONSTIGE:
				return TrackCloseType.OTHER
			default:
				return null
		}
	}

}
