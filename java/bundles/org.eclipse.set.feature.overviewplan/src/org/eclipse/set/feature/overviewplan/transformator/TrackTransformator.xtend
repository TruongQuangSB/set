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

@Component(service=Transformator)
class TrackTransformator extends BaseTransformator<TOP_Kante> {

	@Reference
	TrackService trackService
	Map<OverviewplanTrack, Track> mdToTrack = newHashMap
	Map<TOP_Knoten, Double> topNodeHorizontalCoor = newHashMap

	override transform(TOP_Kante topKante) {
		if (topKante.alreadyTransform) {
			return
		}
		val md = trackService.getTOPKanteMetaData(topKante)
		val metadataTrack = trackService.tracksCache.findFirst [
			topEdges.contains(md)
		]
		topNodeHorizontalCoor.put(md.topNodeA, 0.0)
		metadataTrack.transformTrack(md, md.topNodeA,
			createPosition(0, metadataTrack.lvl), true)
		println("TEST")
	}

	private def void transformTrack(OverviewplanTrack mdTrack,
		TOPKanteMetaData md, TOP_Knoten topNode, Position pos,
		boolean isForward) {
		var track = mdToTrack.get(mdTrack)
		if (track !== null) {
			return
		}

		track = SiteplanFactory.eINSTANCE.createTrack
		track.guid = '''«state.tracks.size + 1»'''
		mdToTrack.put(mdTrack, track)
		state.tracks.add(track)
		val section = SiteplanFactory.eINSTANCE.createTrackSection
		section.guid = md.topEdge.identitaet.wert

		val topNodeA = topNode
		val segmentA = SiteplanFactory.eINSTANCE.createTrackSegment
		segmentA.guid = topNodeA.identitaet.wert
		segmentA.positions.add(pos)
		md.transformSection(track, topNodeA, pos, isForward)
		val topNodeB = md.getNextTopNode(topNode)
		val segmentB = SiteplanFactory.eINSTANCE.createTrackSegment
		segmentB.guid = topNodeB.identitaet.wert
		segmentB.positions.add(createPosition(pos.x + (!isForward ? 1 : -1), pos.y))
		section.segments.add(segmentA)
		section.segments.add(segmentB)
		track.sections.add(section)

		md.transformSection(track, topNodeB, createPosition(pos.x + (!isForward ? 1 : -1), pos.y),
			!isForward)
	}

	private def void transformSection(TOPKanteMetaData md, Track track,
		TOP_Knoten topNode, Position pos, boolean isForward) {
		val leftSide = md.getLeftEdgeAt(topNode)
		leftSide?.forEach [ leftIntersect |
			val intersectTrack = trackService.tracksCache.findFirst [
				topEdges.contains(leftIntersect)
			]
			intersectTrack.transformTrack(leftIntersect, topNode,
				createPosition(pos.x, intersectTrack.lvl),
				topNode.isSameDirection(md,
					leftIntersect) ? isForward : !isForward)
		]

		val rightSide = md.getRightEdgeAt(topNode)
		rightSide?.forEach [ rightIntersect |
			val intersectTrack = trackService.tracksCache.findFirst [
				topEdges.contains(rightIntersect)
			]
			intersectTrack.transformTrack(rightIntersect, topNode,
				createPosition(pos.x, intersectTrack.lvl),
				topNode.isSameDirection(md,
					rightIntersect) ? isForward : !isForward)
		]
		val continuous = md.getContinuousEdgeAt(topNode)
		if (continuous === null) {
			return
		}
		val section = SiteplanFactory.eINSTANCE.createTrackSection
		section.guid = continuous.topEdge.identitaet.wert
		val segmentA = SiteplanFactory.eINSTANCE.createTrackSegment
		segmentA.guid = topNode.identitaet.wert
		segmentA.positions.add(pos)

		val topNodeB = continuous.getNextTopNode(topNode)
		val segmentB = SiteplanFactory.eINSTANCE.createTrackSegment
		segmentB.guid = topNodeB.identitaet.wert
		segmentB.positions.add(
			createPosition(pos.x + (isForward ? 1 : -1), pos.y))
		section.segments.add(segmentA)
		section.segments.add(segmentB)
		track.sections.add(section)

		continuous.transformSection(track, topNodeB,
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

	private def TrackSegment createTrackSegment(TrackSection section,
		TOP_Knoten node, double x, double y) {
		val segment = SiteplanFactory.eINSTANCE.createTrackSegment
		val position = createPosition(x, y)
		segment.positions.add(position)
		section.segments.add(segment)
		return segment
	}

	private def Position createPosition(double x, double y) {
		val position = SiteplanFactory.eINSTANCE.createPosition
		position.x = x
		position.y = y
		return position
	}
}
