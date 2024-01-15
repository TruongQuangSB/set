/**
 * Copyright (c) 2023 DB Netz AG and others.
 * 
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v2.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v20.html
 */
package org.eclipse.set.feature.overviewplan.service

import java.util.ArrayList
import java.util.List
import java.util.Map
import org.eclipse.set.core.services.Services
import org.eclipse.set.model.siteplan.Position
import org.eclipse.set.ppmodel.extensions.container.MultiContainer_AttributeGroup
import org.eclipse.set.toolboxmodel.Geodaten.TOP_Kante
import org.eclipse.set.toolboxmodel.Geodaten.TOP_Knoten
import org.eclipse.set.utils.ToolboxConfiguration
import org.osgi.service.component.annotations.Component
import org.slf4j.Logger
import org.slf4j.LoggerFactory

import static extension org.eclipse.set.ppmodel.extensions.TopKnotenExtensions.*

@Component
class TrackServiceImpl implements TrackService {

	static final Logger logger = LoggerFactory.getLogger(TrackServiceImpl)
	/**
	 * The id of the used cache for a caching map for mapping TOPKanteMetadata
	 */
	static final String METADATA_CACHE_ID = "toolbox.cache.overviewplan.trackservice.metadata";
	static Map<String, TOPKanteMetaData> metadataCache = newHashMap
	static List<OverviewplanTrack> tracksCache = newArrayList

	private def TOPKanteMetaData getCache(String guid) {
		if (!ToolboxConfiguration.developmentMode) {
			// Cache objects are of type List<TOPKanteMetaData>>
			val cache = Services.cacheService.getCache(METADATA_CACHE_ID)
			return cache.getIfPresent(guid) as TOPKanteMetaData
		}

		return metadataCache.getOrDefault(guid, null)
	}

	private def void setCache(String guid, TOPKanteMetaData metadata) {
		if (!ToolboxConfiguration.developmentMode) {
			// Cache objects are of type List<TOPKanteMetaData>>
			val cache = Services.cacheService.getCache(METADATA_CACHE_ID)
			cache.set(guid, metadata)
			return
		}
		metadataCache.put(guid, metadata)
	}

	override getTracksCache() {
		return tracksCache
	}

	override getTOPKanteMetaData(TOP_Kante topKante) {
		val key = topKante.identitaet.wert
		val value = key.getCache
		if (value !== null) {
			return value
		}

		val metadata = new TOPKanteMetaData(topKante, this)
		key.setCache(metadata)
		return metadata
	}

	override getTOPKanteMetaData(List<TOP_Kante> topKanten, String guid) {
		return topKanten.findFirst[identitaet.wert === guid]?.TOPKanteMetaData
	}

	override getTOPKanteMetaData(TOP_Knoten topKnoten) {
		val topKanten = topKnoten.topKanten
		return topKanten.map[TOPKanteMetaData]
	}

	override setupTrackNetz(MultiContainer_AttributeGroup container) {
		val md = container.TOPKante.get(0).TOPKanteMetaData
		md.defineTrack
		md.defineTrackLvl
		container.setupAnotherTrackNetz
	}

	private def boolean isMissingTOPKanteMetaData(
		MultiContainer_AttributeGroup container) {
		return container.TOPKante.exists[identitaet.wert.cache === null]
	}

	private def void setupAnotherTrackNetz(
		MultiContainer_AttributeGroup container) {
		if (!container.isMissingTOPKanteMetaData) {
			return
		}
		logger.warn("Es gibt mehr als einer Gleisnetz")
		val clone = tracksCache.clone
		tracksCache = new ArrayList
		val md = container.TOPKante.findFirst[identitaet.wert.cache === null].
			TOPKanteMetaData
		md.defineTrack
		if (tracksCache.size < clone.size) {
			tracksCache = new ArrayList
			tracksCache.addAll(clone)
			return
		}
		
		md.defineTrackLvl
	}

	private def OverviewplanTrack defineTrack(TOPKanteMetaData md) {
		var track = tracksCache.findFirst[topEdges.contains(md)]
		if (track !== null) {
			return track
		}

		track = new OverviewplanTrack(md)
		tracksCache.add(track)

		track.defineTrackSide(md, md.topNodeA)
		track.defineTrackSide(md, md.topNodeB)
		return track
	}

	private def void defineTrackSide(OverviewplanTrack track,
		TOPKanteMetaData md, TOP_Knoten topNode) {
		val isChangeLeftRight = md.getChangeLeftRightAt(topNode)
		md.getIntersectEdgeAt(topNode).forEach [ intersect |
			intersect.setChangeLeftRightAt(topNode, isChangeLeftRight)
		]
		val leftSide = md.getLeftEdgeAt(topNode)
		leftSide?.forEach [ leftIntersect |
			val leftTrack = leftIntersect.defineTrack
			leftTrack.rightTracks.put(topNode, track)
			track.leftTracks.put(topNode, leftTrack)
		]

		val rightSide = md.getRightEdgeAt(topNode)
		rightSide?.forEach [ rightIntersect |
			val rightTrack = rightIntersect.defineTrack
			rightTrack.leftTracks.put(topNode, track)
			track.rightTracks.put(topNode, rightTrack)
		]

		val continuous = md.getContinuousEdgeAt(topNode)
		if (continuous !== null) {
			track.defineTrackSide(continuous,
				continuous.getNextTopNode(topNode))
		}
	}

	private def void defineTrackLvl(TOPKanteMetaData md) {
		val track = tracksCache.findFirst[topEdges.contains(md)]
		track.lvl = 0
		val path = newLinkedList(track)
		track.defineTrackLvl(path, true)
		track.defineTrackLvl(path, false)
	}

	private def void defineTrackLvl(OverviewplanTrack source,
		List<OverviewplanTrack> path, boolean isLeftSide) {
		val sideTracks = isLeftSide ? source.leftTracks : source.rightTracks
		sideTracks.values.forEach [
			if (path.contains(it)) {
				return
			}
			if (isLeftSide && source.lvl + 1 > it.lvl) {
				it.lvl = source.lvl + 1;
			} else if (!isLeftSide && source.lvl - 1 < it.lvl) {
				it.lvl = source.lvl - 1;
			}
			val clone = newLinkedList
			clone.addAll(path)
			clone.add(it)

			it.defineTrackLvl(clone, isLeftSide)
			it.defineTrackLvl(clone, !isLeftSide)
		]

	}

	override getTOPKnotenPosition(TOP_Knoten topNode) {
		throw new UnsupportedOperationException(
			"TODO: auto-generated method stub")
	}

	override setTOPKnotenPosition(TOP_Knoten toNode, Position position) {
		throw new UnsupportedOperationException(
			"TODO: auto-generated method stub")
	}

}
