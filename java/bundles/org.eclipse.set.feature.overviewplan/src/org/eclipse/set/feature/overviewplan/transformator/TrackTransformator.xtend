/**
 * Copyright (c) 2023 DB Netz AG and others.
 * 
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v2.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v20.html
 */
package org.eclipse.set.feature.overviewplan.transformator

import org.eclipse.set.feature.overviewplan.service.TOPKanteMetaData
import org.eclipse.set.feature.overviewplan.service.TrackService
import org.eclipse.set.feature.siteplan.transform.BaseTransformator
import org.eclipse.set.feature.siteplan.transform.Transformator
import org.eclipse.set.model.siteplan.SiteplanFactory
import org.eclipse.set.model.siteplan.Track
import org.eclipse.set.toolboxmodel.Geodaten.TOP_Kante
import org.eclipse.set.toolboxmodel.Geodaten.TOP_Knoten
import org.osgi.service.component.annotations.Component
import org.osgi.service.component.annotations.Reference
import org.eclipse.set.model.siteplan.TrackSegment
import org.eclipse.set.model.siteplan.TrackSection
import org.eclipse.set.model.siteplan.Position
import org.eclipse.set.feature.overviewplan.service.OverviewplanTrack
import java.util.Map
import org.eclipse.set.toolboxmodel.Geodaten.ENUMTOPAnschluss
import java.util.List

@Component(service=Transformator)
class TrackTransformator extends BaseTransformator<TOP_Kante> {

	@Reference
	TrackService trackService
	Map<OverviewplanTrack, Track> mdToTrack = newHashMap
	Map<String, Double> topNodeHorizontalCoor = newHashMap

	override transform(TOP_Kante topKante) {
		if (topKante.alreadyTransform) {
			return
		}
		val md = trackService.getTOPKanteMetaData(topKante)
		val metadataTrack = trackService.tracksCache.findFirst [
			topEdges.contains(md)
		]
		
		md.transformTrack(null, null, true)
		println("TEST")
	}

	private def void transformTrack(TOPKanteMetaData md, TOP_Knoten topNode,
		Position pos, boolean isForward) {
		val mdTrack = trackService.tracksCache.findFirst[topEdges.contains(md)]
		if (mdTrack === null) {
			throw new IllegalArgumentException('''Es gibt keine Track enthält TOP_Kante: «md.topEdge.identitaet.wert»''')
		}

		var track = mdToTrack.get(mdTrack)
		if (track === null) {
			track = SiteplanFactory.eINSTANCE.createTrack
			track.guid = '''«state.tracks.size + 1»'''
			mdToTrack.put(mdTrack, track)
			state.tracks.add(track)
		}

		if (topNode === null) {
			val posA = createPosition(0, mdTrack.lvl)
			val posB = createPosition(-1, mdTrack.lvl)
			topNodeHorizontalCoor.put(md.topNodeA.identitaet.wert, 0.0)
			topNodeHorizontalCoor.put(md.topNodeB.identitaet.wert, -1.0)
			md.transformSection(track, md.topNodeA, posA, true)
			md.transformSection(track, md.topNodeB, posB, false)
			return
		}

		val section = track.sections.findFirst [
			guid === md.topEdge.identitaet.wert
		]
		if (section?.segments?.findFirst[guid === topNode.identitaet.wert] !==
			null) {
			return
		}
//
//		val nodeA = topNode
//		md.transformSection(track, nodeA, createPosition(pos.x, mdTrack.lvl),
//			!isForward)
		val nodeB = md.getNextTopNode(topNode)
		if (section?.segments?.findFirst[guid === nodeB.identitaet.wert] !==
			null) {
			return
		}
		md.transformSection(track, nodeB,
			createPosition(pos.x + (isForward ? 1 : -1), mdTrack.lvl),
			isForward)
	}

	private def void transformSection(TOPKanteMetaData md, Track track,
		TOP_Knoten topNode, Position pos, boolean isForward) {
		var section = track.sections.findFirst [
			guid === md.topEdge.identitaet.wert
		]
		if (section === null) {
			section = SiteplanFactory.eINSTANCE.createTrackSection
			section.guid = md.topEdge.identitaet.wert
			track.sections.add(section)
		}

		if (section.segments.exists[guid === topNode.identitaet.wert]) {
			return
		}
		val segment = SiteplanFactory.eINSTANCE.createTrackSegment
		segment.guid = topNode.identitaet.wert
		if (topNodeHorizontalCoor.containsKey(topNode.identitaet.wert)) {
			segment.positions.add(createPosition(topNodeHorizontalCoor.get(topNode.identitaet.wert), pos.y))
		} else {
			segment.positions.add(pos)
			topNodeHorizontalCoor.put(topNode.identitaet.wert, pos.x)	
		}		
		section.segments.add(segment)

		val leftSide = md.getLeftEdgeAt(topNode)
		leftSide?.forEach [ leftIntersect |
			if (topNode.isSameDirection(md, leftIntersect)) {
				leftIntersect.transformTrack(topNode, pos, isForward)
			}
//			leftIntersect.transformTrack(topNode, pos,
//				topNode.isSameDirection(md,
//					leftIntersect) ? isForward : !isForward)
		]

		val rightSide = md.getRightEdgeAt(topNode)
		rightSide?.forEach [ rightIntersect |
			if (topNode.isSameDirection(md, rightIntersect)) {
				rightIntersect.transformTrack(topNode, pos, isForward)
			}
//			rightIntersect.transformTrack(topNode, pos,
//				topNode.isSameDirection(md,
//					rightIntersect) ? isForward : !isForward)
		]
		val continuous = md.getContinuousEdgeAt(topNode)
		if (continuous === null || track.sections.exists [
			guid === continuous.topEdge.identitaet.wert
		]) {
			return
		}

		continuous.transformSection(track, continuous.getNextTopNode(topNode),
			createPosition(pos.x + (isForward ? 1 : -1), pos.y), isForward)
	}

	private def boolean isSameDirection(TOP_Knoten topNode,
		TOPKanteMetaData mdA, TOPKanteMetaData mdB) {
		return mdA.getTopConnectorAt(topNode) ===
			ENUMTOPAnschluss.ENUMTOP_ANSCHLUSS_SPITZE ||
			mdB.getTopConnectorAt(topNode) ===
				ENUMTOPAnschluss.ENUMTOP_ANSCHLUSS_SPITZE
	}

	private def boolean alreadyTransform(TOP_Kante edge) {
		return state.tracks.flatMap[sections].exists [
			guid === edge.identitaet.wert
		]
	}

	private def void transformTrack(OverviewplanTrack track, TOP_Knoten node,
		Position pos, boolean isForward) {
		val index = track.topNodes.indexOf(node)

		track.topNodes.forEach [
			val segment = SiteplanFactory.eINSTANCE.createTrackSegment
			segment.guid = node.identitaet.wert
			segment.positions.add(createPosition(index, track.lvl))
		]

	}

	private def TrackSection createTrackSection(Track track,
		TOPKanteMetaData md) {
		val section = SiteplanFactory.eINSTANCE.createTrackSection
		section.guid = md.topEdge.identitaet.wert
		track.sections.add(section)
		return section
	}

	private def TrackSegment createTrackSegment(TOP_Knoten node, double x,
		double y) {
		val segment = SiteplanFactory.eINSTANCE.createTrackSegment
		segment.guid = node.identitaet.wert
		val position = createPosition(x, y)
		segment.positions.add(position)
		return segment
	}

	private def Position createPosition(double x, double y) {
		val position = SiteplanFactory.eINSTANCE.createPosition
		position.x = x
		position.y = y
		return position
	}
}
