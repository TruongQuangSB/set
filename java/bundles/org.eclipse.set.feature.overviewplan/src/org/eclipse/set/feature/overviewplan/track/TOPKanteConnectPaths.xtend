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
import org.eclipse.set.toolboxmodel.Geodaten.TOP_Knoten
import static extension org.eclipse.set.ppmodel.extensions.TopKanteExtensions.*
import static extension org.eclipse.set.ppmodel.extensions.utils.ListExtensions.*

/**
 * Contains all connect path of a TOP_Kanten
 * 
 * @author Truong
 */
class TOPKanteConnectPaths {
	public TOPKanteMetaData md
	List<ConnectPath> connectPaths = newArrayList

	new(TOPKanteMetaData md) {
		this.md = md
		connectPaths.add(new ConnectPath(md, md.topNodeA))
		connectPaths.add(new ConnectPath(md, md.topNodeB))
	}

	def ConnectPath getConnectPathsAtNode(TOP_Knoten node) {
		return connectPaths.findFirst[it.node === node]
	}

	def void setupPaths(TOP_Knoten node) {
		val path = newLinkedList(md)
		md.setupPaths(node, node.connectPathsAtNode, path)
	}

	private def void setupPaths(TOPKanteMetaData metadata, TOP_Knoten node,
		ConnectPath connectPath, List<TOPKanteMetaData> path) {
		var intersectEdge = metadata.getIntersectEdgeAt(node)
		val pathAtNode = metadata.TOPKanteConnectPaths.
			getConnectPathsAtNode(node)
		val alreadyFoundPaths = pathAtNode.getPaths(path)
		if (!alreadyFoundPaths.empty) {
			alreadyFoundPaths.forEach[path.addAlreadyFoundPath(it, connectPath)]
			// Check if already found path of both next edge
			val nextConnectEdges = alreadyFoundPaths.filter[size > 1].map [
				get(1)
			].toSet

			if (nextConnectEdges.size === intersectEdge.size &&
				nextConnectEdges.containsAll(intersectEdge)) {
				return
			}
			if (!nextConnectEdges.empty) {
				intersectEdge = intersectEdge.filter [
					!nextConnectEdges.contains(it)
				].toList
			}
		}

		intersectEdge.forEach [
			val nextNode = getNextTopNode(node)
			val intersect = it.getIntersectEdgeAt(nextNode)
			if (intersect.empty || path.contains(it)) {
				addPath(connectPath, path, it)
				return
			}

			val clone = path.cloneLinkedList
			clone.add(it)
			setupPaths(nextNode, connectPath, clone)
		]
	}

	private def void addAlreadyFoundPath(List<TOPKanteMetaData> currentPath,
		List<TOPKanteMetaData> foundPath, ConnectPath connectPath) {
		val clone = currentPath.cloneLinkedList
		val subList = foundPath.subList(1, foundPath.size)
		val duplicate = subList.findFirst[clone.contains(it)]
		if (duplicate !== null) {
			clone.addAll(subList.subList(0, subList.indexOf(duplicate)))
		} else {
			clone.addAll(subList)
		}

		if (connectPath.isPathComplete(clone)) {
			connectPath.addPath(clone, null)

			return
		}

		// Make this found path to complete
		val connectNode = clone.last.topEdge.connectionTo(
			clone.get(clone.size - 2).topEdge)
		val nextNode = clone.last.getNextTopNode(connectNode)
		clone.last.setupPaths(nextNode, connectPath, clone)
	}

	private def void addPath(ConnectPath connectPath,
		List<TOPKanteMetaData> path, TOPKanteMetaData next) {
		val clone = path.cloneLinkedList
		if (next !== null && !path.subList(1, path.size).contains(next)) {
			clone.add(next)
		}

		connectPath.addPath(clone)
		for (var i = 1; i < clone.size - 1; i++) {
			clone.get(i).updatePath(clone.subList(i, clone.size), next)
		}
	}

	private def void updatePath(TOPKanteMetaData current,
		List<TOPKanteMetaData> path, TOPKanteMetaData next) {

		val clone = path.cloneLinkedList
		if (next !== null && !path.subList(1, path.size).contains(next)) {
			clone.add(next)
		}
		val connectNode = current.topEdge.connectionTo(clone.get(1).topEdge)
		val mdConnectPath = current.TOPKanteConnectPaths
		mdConnectPath.getConnectPathsAtNode(connectNode).addPath(clone)
	}

	/**
	 * Get all cycle path of TOP_Kante
	 */
	def List<List<TOPKanteMetaData>> getCyclePath() {
		val connectPathsA = getConnectPathsAtNode(md.topNodeA).paths.filter [
			isCyclePath
		].toList
		val connectPathsB = getConnectPathsAtNode(md.topNodeB).paths.filter [
			isCyclePath
		].toList
		val filterSamePath = connectPathsB.filter [
			val sameSizePath = connectPathsA.filter[t|t.size === it.size]
			return sameSizePath.empty || !sameSizePath.exists [ t |
				it.forall[i|i.equals(t.get(it.size - 1 - it.indexOf(i)))]
			]
		]
		connectPathsA.addAll(filterSamePath)
		return connectPathsA
	}

	/**
	 * A cycle path is a path start at TOP_Knoten A and end at TOP_Knoten B of a TOP_Kante
	 */
	private def boolean isCyclePath(List<TOPKanteMetaData> path) {
		val first = path.get(0).topEdge
		val next = path.get(1).topEdge
		val last = path.last.topEdge
		val previousLast = path.get(path.size - 2).topEdge
		return path.last === path.get(0) && first.connectionTo(next) !==
			last.connectionTo(previousLast)
	}
}
