/**
 * Copyright (c) 2023 DB Netz AG and others.
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v2.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v20.html
 */

package org.eclipse.set.feature.overviewplan.service;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.LinkedList;
import java.util.List;
import java.util.Set;

/**
 * @author truong
 *
 */
public class TestAlgo {
	static List<TestTrack> tracks = new ArrayList<>();

	/**
	 * @param args
	 */
	public static void main(final String[] args) {
		final TestTrack A = new TestTrack("A");
		final TestTrack B = new TestTrack("B");
		final TestTrack C = new TestTrack("C");
		final TestTrack D = new TestTrack("D");
		final TestTrack E = new TestTrack("E");
		final TestTrack F = new TestTrack("F");

		final TestTrack G = new TestTrack("G");
		final TestTrack H = new TestTrack("H");
		final TestTrack I = new TestTrack("I");
		final TestTrack J = new TestTrack("J");
		final TestTrack K = new TestTrack("K");
		final TestTrack L = new TestTrack("L");
		final TestTrack M = new TestTrack("M");
		final TestTrack N = new TestTrack("N");
		final TestTrack O = new TestTrack("O");
		final TestTrack P = new TestTrack("P");
		final TestTrack Q = new TestTrack("Q");
		final TestTrack R = new TestTrack("R");
		final TestTrack S = new TestTrack("S");
		final TestTrack T = new TestTrack("T");
		final TestTrack U = new TestTrack("U");
		tracks.addAll(List.of(A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q,
				R, S, T, U));
		A.leftTrack.add(B);

		B.rightTrack.add(A);
		B.leftTrack.add(C);

		C.leftTrack.addAll(List.of(D, R));
		C.rightTrack.addAll(List.of(B, F, Q));

		D.leftTrack.add(E);
		D.rightTrack.add(C);

		E.rightTrack.addAll(List.of(D, R));
		E.leftTrack.add(S);

		F.rightTrack.add(G);
		F.leftTrack.add(C);

		G.leftTrack.addAll(List.of(F, Q));
		G.rightTrack.addAll(List.of(H, I, K, U));

		H.leftTrack.addAll(List.of(G, J, I));
		H.rightTrack.add(K);

		I.leftTrack.add(G);
		I.rightTrack.addAll(List.of(O, P, H));

		J.rightTrack.addAll(List.of(K, H));

		K.leftTrack.addAll(List.of(G, O, P, J, H, L, M));
		K.rightTrack.add(N);

		L.rightTrack.addAll(List.of(K, M));

		M.leftTrack.add(L);
		M.rightTrack.add(K);

		N.leftTrack.add(K);

		O.leftTrack.add(I);
		O.rightTrack.add(K);

		P.leftTrack.add(I);
		P.rightTrack.add(K);

		Q.leftTrack.add(C);
		Q.rightTrack.add(G);

		R.leftTrack.add(E);
		R.rightTrack.add(C);

		S.leftTrack.add(T);
		S.rightTrack.add(E);

		T.rightTrack.add(S);

		U.leftTrack.add(G);
		final List<TestTrack> path = new LinkedList<>();
		path.add(K);
		defineTracklvl(K, true, path);
		defineTracklvl(K, false, path);

	}

	private static Set<List<TestTrack>> alreadyCheck = new HashSet<>();

	private static void defineTracklvl(final TestTrack source,
			final boolean isLeft, final List<TestTrack> path) {
		final List<TestTrack> leftTracks = isLeft ? source.leftTrack
				: source.rightTrack;
		leftTracks.forEach(track -> {
			if (path.contains(track)) {
				return;
			}
			if (isLeft && source.lvl + 1 > track.lvl) {
				track.lvl = source.lvl + 1;
			} else if (!isLeft && source.lvl - 1 < track.lvl) {
				track.lvl = source.lvl - 1;
			}
			final List<TestTrack> clone = new LinkedList<>();
			clone.addAll(path);
			clone.add(track);
			defineTracklvl(track, isLeft, clone);
			defineTracklvl(track, !isLeft, clone);
		});
	}

	public static class TestTrack {
		public List<TestTrack> leftTrack = new ArrayList<>();
		public List<TestTrack> rightTrack = new ArrayList<>();
		public int lvl;
		public boolean fixedLvl = false;
		public String name;

		public TestTrack(final String name) {
			this.name = name;
			lvl = 0;
		}
	}

}
