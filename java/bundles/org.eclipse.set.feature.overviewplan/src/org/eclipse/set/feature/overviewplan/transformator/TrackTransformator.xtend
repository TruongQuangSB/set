/**
 * Copyright (c) 2023 DB Netz AG and others.
 * 
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v2.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v20.html
 */
package org.eclipse.set.feature.overviewplan.transformator

import java.util.Map
import org.eclipse.set.feature.overviewplan.track.OverviewplanTrack
import org.eclipse.set.feature.overviewplan.track.TOPKanteMetaData
import org.eclipse.set.feature.overviewplan.track.TrackService
import org.eclipse.set.feature.siteplan.transform.BaseTransformator
import org.eclipse.set.feature.siteplan.transform.Transformator
import org.eclipse.set.model.siteplan.Position
import org.eclipse.set.model.siteplan.SiteplanFactory
import org.eclipse.set.model.siteplan.Track
import org.eclipse.set.toolboxmodel.Geodaten.TOP_Kante
import org.osgi.service.component.annotations.Component
import org.osgi.service.component.annotations.Reference
import org.eclipse.set.feature.siteplan.SiteplanConstants

@Component(service=Transformator)
class TrackTransformator extends BaseTransformator<TOP_Kante> {

	@Reference
	TrackService trackService
	static Map<OverviewplanTrack, Track> mdToTrack = newHashMap

	override transform(TOP_Kante topKante) {
		if (state.tracks.exists[sections.exists[guid === topKante.identitaet.wert]]) {
			return
		}
		
		val md = trackService.getTOPKanteMetaData(topKante)
		md.transformTrack
		
		state.tracks.flatMap[sections].indexed.forEach[
			var color = SiteplanConstants.TOP_KANTEN_COLOR.get(value.guid)
			if (color === null) {
				color = '''hsl(«key * 137.5», 100%, 65%)'''
			}
			value.color = color
		]
	}

	private def void transformTrack(TOPKanteMetaData md) {
		val mdTrack = trackService.tracksCache.findFirst[topEdges.contains(md)]
		if (mdTrack === null) {
			throw new IllegalArgumentException('''Es gibt keine Track enthält TOP_Kante: «md.topEdge.identitaet.wert»''')
		}
		if (mdToTrack.containsKey(mdTrack)) {
			return
		}
		val track = SiteplanFactory.eINSTANCE.createTrack
		track.guid = '''«state.tracks.size + 1»'''
		state.tracks.add(track)
		mdToTrack.put(mdTrack, track)
		mdTrack.topEdges.forEach[createTrackSection(track, mdTrack.lvl)]
	}

	private def void createTrackSection(TOPKanteMetaData md, Track track,
		int posY) {
		val section = SiteplanFactory.eINSTANCE.createTrackSection
		section.guid = md.topEdge.identitaet.wert
		track.sections.add(section)
		#[md.topNodeA, md.topNodeB].forEach [
			val segment = SiteplanFactory.eINSTANCE.createTrackSegment
			segment.guid = identitaet.wert
			val nodePosX = trackService.getTOPKnotenHorizontalCoor(it)
			if (nodePosX === null) {
				throw new IllegalArgumentException('''Horizontal Koordinate von TOP_Knoten: «identitaet.wert» kann nicht finden''')
			}
			val position = createPosition(nodePosX, posY)
			if (md.getContinuousEdgeAt(it) === null &&
				!md.getIntersectEdgeAt(it).empty) {
				val connectTrack = md.getIntersectEdgeAt(it).map [ intersect |
					trackService.tracksCache.findFirst [
						topEdges.contains(intersect)
					]
				].toSet
				if (connectTrack.size > 1) {
					throw new IllegalArgumentException('''Bei TOP_Knoten: «identitaet.wert» existiert drei gleis''')
				}
				position.y = connectTrack.get(0).lvl
				val factor = !md.changeLeftRightNode.get(it) ? 1 : -1
				segment.positions.add(createPosition(nodePosX + factor * Math.abs(position.y - posY), posY))
			}

			segment.positions.add(position)
			section.segments.add(segment)
		]
	}

	private def Position createPosition(double x, double y) {
		val position = SiteplanFactory.eINSTANCE.createPosition
		position.x = x
		position.y = y
		return position
	}
}
