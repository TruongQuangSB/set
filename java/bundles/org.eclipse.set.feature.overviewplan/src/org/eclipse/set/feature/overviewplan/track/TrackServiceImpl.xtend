/**
 * Copyright (c) {year} DB InfraGO AG and others
 * 
 * This program and the accompanying materials are made available under the 
 * terms of the Eclipse Public License 2.0 which is available at
 * https://www.eclipse.org/legal/epl-2.0.
 * 
 * SPDX-License-Identifier: EPL-2.0  
 */
package org.eclipse.set.feature.overviewplan.track

import com.google.common.collect.Range
import java.util.ArrayList
import java.util.Collections
import java.util.List
import java.util.Map
import java.util.Set
import org.eclipse.set.core.services.Services
import org.eclipse.set.ppmodel.extensions.container.MultiContainer_AttributeGroup
import org.eclipse.set.toolboxmodel.Geodaten.TOP_Kante
import org.eclipse.set.toolboxmodel.Geodaten.TOP_Knoten
import org.eclipse.set.utils.ToolboxConfiguration
import org.osgi.service.component.annotations.Component
import org.slf4j.Logger
import org.slf4j.LoggerFactory

import static extension org.eclipse.set.feature.overviewplan.track.TOPKantePositionExtensions.*
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
	static Map<TOP_Knoten, Double> topNodeHorizontalCoor = newHashMap

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

	override getTOPKanteMetaData(String guid) {
		val value = guid.cache
		if (value !== null) {
			return value
		}
		return null
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
		val firstTrack = md.defineTrack(0)
		firstTrack.fixedLvl = true
		if (container.TOPKante.exists[identitaet.wert.cache === null]) {
			container.setupAnotherTrackNetz
		}
		val topEdges = container.TOPKante.map[identitaet.wert.cache].filterNull.
			toList
		topEdges.defineConnectPath
		topEdges.defineTOPKanteLength
		topNodeHorizontalCoor = topEdges.get(0).TOPNodeHorizontalCoor
		topNodeHorizontalCoor.defineTrackLvl
	}

	private def defineConnectPath(List<TOPKanteMetaData> topEdges) {
		val notEndEdges = topEdges.filter [
			return !getIntersectEdgeAt(topNodeA).empty &&
				!getIntersectEdgeAt(topNodeB).empty
		].toList
		notEndEdges.forEach [ md, index |
			val connectPath = md.TOPKanteConnectPaths
			connectPath.setupPaths(md.topNodeA)
			connectPath.setupPaths(md.topNodeB)
			println('''«index»: «md.topEdge.identitaet.wert»''')
		]
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
		md.defineTrack(0)
		if (tracksCache.size < clone.size) {
			tracksCache = new ArrayList
			tracksCache.addAll(clone)
			return
		}
	}

	private def OverviewplanTrack defineTrack(TOPKanteMetaData md, int lvl) {
		var track = tracksCache.findFirst[topEdges.contains(md)]

		if (track !== null) {
			return track
		}

		track = new OverviewplanTrack(md)
		track.lvl = lvl
		tracksCache.add(track)

		track.defineTrackSide(md, md.topNodeA)
		track.defineTrackSide(md, md.topNodeB)
		return track
	}

	/**
	 * Find out all connect track lie on left or right side of the track
	 */
	private def void defineTrackSide(OverviewplanTrack track,
		TOPKanteMetaData md, TOP_Knoten topNode) {
		val isChangeLeftRight = md.getChangeLeftRightAt(topNode)
		md.getIntersectEdgeAt(topNode).forEach [ intersect |
			intersect.setChangeLeftRightAt(topNode, isChangeLeftRight)
		]
		val leftSide = md.getLeftEdgeAt(topNode)
		leftSide?.forEach [ leftIntersect |
			val leftTrack = leftIntersect.defineTrack(track.lvl + 1)
			if (track.lvl + 1 > leftTrack.lvl) {
				leftTrack.lvl = track.lvl + 1
			}
			leftTrack.rightTracks.put(topNode, track)
			track.leftTracks.put(topNode, leftTrack)
		]

		val rightSide = md.getRightEdgeAt(topNode)
		rightSide?.forEach [ rightIntersect |
			val rightTrack = rightIntersect.defineTrack(track.lvl - 1)
			if (track.lvl - 1 < rightTrack.lvl) {
				rightTrack.lvl = track.lvl - 1
			}

			rightTrack.leftTracks.put(topNode, track)
			track.rightTracks.put(topNode, rightTrack)
		]

		val continuous = md.getContinuousEdgeAt(topNode)
		if (continuous !== null) {
			track.defineTrackSide(continuous,
				continuous.getNextTopNode(topNode))
		}
	}

	private def void defineTrackLvl(
		Map<TOP_Knoten, Double> topNodeHorizontalCoor) {
		val tracksPositionRange = tracksCache.map [
			val nodePositions = topNodes.map [ node |
				topNodeHorizontalCoor.get(node)
			]
			return new Pair(it,
				Range.closed(nodePositions.min, nodePositions.max))
		]
		tracksPositionRange.forEach [ current |
			if (current.key.fixedLvl) {
				return
			}
			current.defineTrackLvl(tracksPositionRange.filter [
				it.key !== current.key && it.key.lvl * current.key.lvl >= 0
			].toList)
		]
	}

	/**
	 * Define track level throud find and fix collistion between tracks
	 */
	private def void defineTrackLvl(
		Pair<OverviewplanTrack, Range<Double>> current,
		List<Pair<OverviewplanTrack, Range<Double>>> compareTracks) {

		val tmpLvl = current.key.lvl
		val collisionsTracks = compareTracks.map [
			new Pair(it, current.detectCollision(it))
		].filter[value !== CollisionType.NONE].toList

		collisionsTracks.forEach [
			val collisionTrack = key
			val collisionType = value
			if (current.key.lvl !== tmpLvl) {
				return
			}
			val difference = Math.abs(collisionTrack.key.lvl -
				current.key.lvl) + 1
			switch (collisionType) {
				case LEFT: {
					if (!collisionTrack.key.changeTrackLvl(difference, true)) {
						current.key.changeTrackLvl(difference, false)
					}
				}
				case RIGHT: {
					if (!collisionTrack.key.changeTrackLvl(difference, false)) {
						current.key.changeTrackLvl(difference, true)
					}
				}
				case INSIDE: {
					if (current.value.encloses(collisionTrack.value)) {
						if (!current.key.changeTrackLvl(difference, true)) {
							collisionTrack.key.changeTrackLvl(difference, false)
						}
					} else {
						if (!collisionTrack.key.changeTrackLvl(difference,
							true)) {
							current.key.changeTrackLvl(difference, false)
						}
					}
				}
				case CONTAINS: {
					val emptySideTrack = #[current.key, collisionTrack.key].
						findFirst [
							current.key.lvl > 0
								? leftTracks.empty
								: rightTracks.empty
						]
					if (emptySideTrack !== null) {
						if (current.key === emptySideTrack &&
							!current.key.changeTrackLvl(difference, true)) {
							collisionTrack.key.changeTrackLvl(difference, true)
						}
					}
					if (!collisionTrack.key.changeTrackLvl(difference, true)) {
						current.key.changeTrackLvl(difference, true)
					}
				}
				default:
					return
			}
		]

		if (current.key.lvl !== tmpLvl) {
			current.defineTrackLvl(compareTracks)
		}
	}

	private def boolean changeTrackLvl(OverviewplanTrack track, int value,
		boolean isIncrease) {
		if (track.fixedLvl) {
			return false
		}
		track.lvl += value * (isIncrease ? 1 : -1)
		val nextSideTracks = isIncrease ? track.leftTracks : track.rightTracks
		if (!nextSideTracks.values.forall [
			isIncrease ? lvl > track.lvl : lvl < track.lvl
		]) {
			val sideTracks = track.getSideTracks(isIncrease)
			sideTracks.forEach[lvl += value * (isIncrease ? 1 : -1)]
		}
		return true
	}

	/**
	 * Check if two track are collision
	 */
	private def CollisionType detectCollision(
		Pair<OverviewplanTrack, Range<Double>> source,
		Pair<OverviewplanTrack, Range<Double>> target) {
		val leftTracks = source.key.getSideTracks(true)
		val rightTracks = source.key.getSideTracks(false)

		if (leftTracks.contains(target.key) &&
			target.key.lvl <= source.key.lvl) {
			return CollisionType.LEFT
		}

		if ((rightTracks.contains(target.key) &&
			target.key.lvl >= source.key.lvl)) {
			return CollisionType.RIGHT
		}
		val sourceRange = source.value
		val targetRange = target.value
		if (source.key.lvl * target.key.lvl < 0) {
			return CollisionType.NONE
		}

		val isTargetLvlGreater = Math.abs(source.key.lvl) <=
			Math.abs(target.key.lvl)
		if (sourceRange.encloses(targetRange) && (source.key.lvl > 0
			? !leftTracks.contains(target.key)
			: !rightTracks.contains(target.key)) && isTargetLvlGreater) {
			return CollisionType.INSIDE
		}

		if (targetRange.encloses(sourceRange) &&
			(source.key.lvl > 0 ? !rightTracks.contains(
				target.key) : !leftTracks.contains(target.key)) &&
			!isTargetLvlGreater) {
			return CollisionType.INSIDE
		}

		if ((sourceRange.contains(targetRange.lowerEndpoint) ||
			sourceRange.contains(targetRange.upperEndpoint)) &&
			source.key.lvl == target.key.lvl) {
			return CollisionType.CONTAINS
		}
		return CollisionType.NONE
	}

	private enum CollisionType {
		// When track A is left track of track B and A.lvl < B.lvl
		LEFT,
		// When track A is right track of track B and A.lvl > B.lvl
		RIGHT,
		// When start and end of track A lie inside track B and A.lvl > B.lvl
		INSIDE,
		// When start or end of track A lie instide track B and A.lvl = B.lvl
		CONTAINS,
		NONE
	}

	/**
	 * Get all tracks lie on left or right side of a track
	 */
	private def Set<OverviewplanTrack> getSideTracks(OverviewplanTrack mdTrack,
		boolean isLeftSide) {
		val sideTrack = isLeftSide ? mdTrack.leftTracks : mdTrack.rightTracks
		if (sideTrack.values.empty) {
			return Collections.emptySet
		}
		val result = newHashSet
		result.addAll(sideTrack.values)
		sideTrack.values.forEach[result.addAll(getSideTracks(isLeftSide))]
		return result
	}

	override getTrack(TOPKanteMetaData md) {
		return tracksCache.findFirst[topEdges.contains(md)]
	}

	override clean() {
		metadataCache = newHashMap
		tracksCache = newArrayList
	}

	override getTOPKnotenHorizontalCoor(TOP_Knoten node) {
		return topNodeHorizontalCoor.getOrDefault(node, null)
	}

}
