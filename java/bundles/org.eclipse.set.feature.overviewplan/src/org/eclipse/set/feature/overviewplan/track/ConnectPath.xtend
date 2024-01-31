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

/**
 * Contains all path of a TOP_Kanten, which start at a TOP_Knoten
 */
class ConnectPath {
	public TOPKanteMetaData md
	public TOP_Knoten node
	List<List<TOPKanteMetaData>> paths = newArrayList

	new(TOPKanteMetaData md, TOP_Knoten node) {
		this.md = md;
		this.node = node
	}

	def List<List<TOPKanteMetaData>> getPaths() {
		return paths
	}

	def List<List<TOPKanteMetaData>> getPaths(List<TOPKanteMetaData> path) {
		return paths.filter [ p |
			path.last === p.get(0) && !path.exists [
				p.subList(1, p.size).contains(it)
			]
		].toList
	}

	def void addPath(List<TOPKanteMetaData> path) {
		if (path.get(0) !== md || path.alreadyExist) {
			return
		}

		val notCompletePaths = paths.filter [
			!isPathComplete && it.size < path.size
		].findFirst [ current |
			current.forall [
				it === path.get(current.indexOf(it))
			]
		]

		if (notCompletePaths !== null) {
			notCompletePaths.updatePath(path)
			return
		}

		paths.add(path)
	}

	private def boolean isAlreadyExist(List<TOPKanteMetaData> path) {
		return paths.filter[size === path.size].exists [
			it.forall [ ele |
				ele === path.get(it.indexOf(ele))
			]
		]
	}

	/**
	 * A path is complete, when given no more next TOP_Kante or
	 * the path is already contains the next connect TOP_Kanten
	 */
	def boolean isPathComplete(List<TOPKanteMetaData> path) {
		val connectNode = path.last.topEdge.connectionTo(
			path.get(path.size - 2).topEdge)
		val intersect = path.last.getIntersectEdgeAt(
			path.last.getNextTopNode(connectNode))
		return path.last === md || intersect.empty ||
			path.containsAll(intersect)
	}

	private def void updatePath(List<TOPKanteMetaData> notCompletePath,
		List<TOPKanteMetaData> path) {
		val newElements = path.subList(notCompletePath.size, path.size)
		val duplicate = newElements.findFirst[notCompletePath.contains(it)]
		if (duplicate === null || duplicate === md) {
			notCompletePath.addAll(
				path.subList(notCompletePath.size, path.size))
		} else {
			notCompletePath.addAll(
				newElements.subList(0, newElements.indexOf(duplicate)))
		}
	}

}
