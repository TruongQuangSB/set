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

import java.util.List
import java.util.Map
import org.eclipse.set.toolboxmodel.Geodaten.ENUMTOPAnschluss
import org.eclipse.set.toolboxmodel.Geodaten.TOP_Knoten

import static extension org.eclipse.set.ppmodel.extensions.TopKanteExtensions.*
import static extension org.eclipse.set.utils.math.IntegerExtensions.*

/**
 * Position extension for TOPKante
 * @author Truong
 */
class TOPKantePositionExtensions {

	/**
	 * Find TOP_Kante length through cycle path
	 * @param topEdges list of TOPKanteMetaData
	 */
	def static void defineTOPKanteLength(List<TOPKanteMetaData> topEdges) {
		topEdges.forEach [
			val cyclePath = TOPKanteConnectPaths.cyclePath
			if (cyclePath.empty) {
				length = 1
				return
			}
			cyclePath.forEach [
				it.setTopEdgeDirection.isMatchTopEdgeLength
			]
		]
	}

	private def static boolean isMatchTopEdgeLength(
		List<Pair<TOPKanteMetaData, Boolean>> path) {
		val forwardEdge = path.filter[value].map[key].toList
		val backwardEdge = path.filter[!value].map[key].toList
		var forwardLength = forwardEdge.map[length].reduce [ p1, p2 |
			p1 + p2
		]
		var backwardLength = backwardEdge.map[length].reduce [ p1, p2 |
			p1 + p2
		]
		while (backwardLength !== forwardLength) {
			val different = Math.abs(forwardLength - backwardLength)
			if (forwardLength > backwardLength) {
				backwardEdge.setTOPEdgeLength(different)
				backwardLength = backwardEdge.map[length].reduce [ p1, p2 |
					p1 + p2
				]
			} else {
				forwardEdge.setTOPEdgeLength(different)
				forwardLength = forwardEdge.map[length].reduce [ p1, p2 |
					p1 + p2
				]
			}
		}
		path.forEach [
			if (!key.alreadyRegistedLenght) {
				key.length = 1
			}
		]
		return true
	}

	private def static void setTOPEdgeLength(List<TOPKanteMetaData> edges,
		int different) {
		val notRegisterLength = edges.filter [
			!alreadyRegistedLenght
		].toList
		val tmpEdges = (notRegisterLength.empty ? edges : notRegisterLength)
		val matchEdge = tmpEdges.findFirst [
			setTopEdgeLength(length + different)
		]

		if (matchEdge !== null) {
			return
		}

		val clone = newLinkedList
		clone.addAll(edges)
		var splitCount = 2
		val matchList = newArrayList
		while (matchList.empty) {
			if (splitCount > different) {
				return
			}
			val valueList = different.findSumCombination(splitCount)

			for (var i = 0; i < valueList.size; i++) {
				val testMap = newHashMap
				for (var j = 0; j < splitCount; j++) {
					val value = valueList.get(i).get(j)
					val match = clone.filter[!testMap.keySet.contains(it)].
						findFirst[setTopEdgeLength(length + value)]
					if (match !== null) {
						testMap.put(match, value)
					}
				}
				if (testMap.size === splitCount) {
					matchList.add(testMap)
				}
			}
			splitCount++
		}
	}

	private def static boolean setTopEdgeLength(TOPKanteMetaData md,
		int length) {
		val cyclePath = md.TOPKanteConnectPaths.cyclePath
		val paths = cyclePath.filter [ path |
			path.filter[it !== md].forall[alreadyRegistedLenght]
		].toList
		if (paths.empty) {
			md.length = length
			return true
		}

		val tmp = md.length
		md.length = length
		val pathWithDirection = paths.map [ path |
			path.setTopEdgeDirection
		].toList
		val match = pathWithDirection.forall [
			isMatchTopEdgeLength
		]
		if (!match) {
			md.length = tmp
		}
		return match
	}

	private def static List<Pair<TOPKanteMetaData, Boolean>> setTopEdgeDirection(
		List<TOPKanteMetaData> path) {
		val result = newLinkedList
		var isForward = true
		var current = path.get(0)
		result.add(new Pair(current, isForward))
		for (var i = 1; i < path.size - 1; i++) {
			val next = path.get(i)
			val connectionNode = current.topEdge.connectionTo(next.topEdge)
			val isSameDirection = connectionNode.isSameDirection(current, next)
			if (isSameDirection) {
				result.add(new Pair(next, isForward))
			} else {
				result.add(new Pair(next, !isForward))
				isForward = !isForward
			}
			current = next
		}
		return result
	}

	static Map<TOP_Knoten, Double> topNodeHorizontalCoor

	/**
	 * Find TOP_Knoten horizontal coordinate throud TOP_Kante length
	 * @param md the start TOP_Kanten
	 */
	def static Map<TOP_Knoten, Double> getTOPNodeHorizontalCoor(
		TOPKanteMetaData md) {
		topNodeHorizontalCoor = newHashMap
		md.transformTOPNodePosition(md.topNodeA, 0, true)
		return topNodeHorizontalCoor
	}

	private def static void transformTOPNodePosition(TOPKanteMetaData md,
		TOP_Knoten topNode, double posX, boolean isForward) {
		if (topNodeHorizontalCoor.containsKey(topNode)) {
			return
		}
		topNodeHorizontalCoor.put(topNode, posX)
		md.getIntersectEdgeAt(topNode).forEach [
			md.transformTOPNodePosition(it, topNode, posX, isForward)
		]
	}

	private def static void transformTOPNodePosition(TOPKanteMetaData md,
		TOPKanteMetaData sideIntersect, TOP_Knoten topNode, double posX,
		boolean isForward) {
		val nextNode = sideIntersect.getNextTopNode(topNode)
		if (topNodeHorizontalCoor.containsKey(nextNode.identitaet.wert)) {
			return
		}
		val isSameDirection = topNode.isSameDirection(md, sideIntersect)
		val topEdgeLength = sideIntersect.length
		val forward = isSameDirection ? isForward : !isForward
		// By default TOP_Kante will multiply with factor 10
		val nextPosX = posX + (forward ? 10 : -10) * topEdgeLength
		sideIntersect.transformTOPNodePosition(nextNode, nextPosX, forward)
	}

	/**
	 * Check if at the TOP_Knoten two TOP_Kante haven same direction or not
	 * @param topNode the TOP_Knoten
	 * @param mdA the first TOP_Kante
	 * @param mdB the second TOP_Kante
	 */
	def static boolean isSameDirection(TOP_Knoten topNode, TOPKanteMetaData mdA,
		TOPKanteMetaData mdB) {
		if (mdA.topEdge.connectionTo(mdB.topEdge) !== topNode) {
			throw new IllegalArgumentException('''TOP_Kante: «mdA.topEdge.identitaet.wert» and TOP_Kante: «mdB.topEdge.identitaet.wert» aren't connect at TOP_Knoten: «topNode.identitaet.wert»''')
		}
		return mdA.getTopConnectorAt(topNode) ===
			ENUMTOPAnschluss.ENUMTOP_ANSCHLUSS_SPITZE ||
			mdB.getTopConnectorAt(topNode) ===
				ENUMTOPAnschluss.ENUMTOP_ANSCHLUSS_SPITZE
	}
}
