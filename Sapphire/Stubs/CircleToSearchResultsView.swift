//
//  CircleToSearchResultsView.swift
//  Sapphire
//
//  Created by Shariq Charolia on 2026-08-30

#if !SAPPHIRE_FULL_BUILD
import SwiftUI

struct CircleToSearchResultsView: View {
    @Binding var navigationStack: [NotchWidgetMode]

    init(navigationStack: Binding<[NotchWidgetMode]>) {
        _navigationStack = navigationStack
    }

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "magnifyingglass.circle.fill").font(.system(size: 22))
            Text("循环搜索在此版本中不可用").font(.caption)
        }
        .frame(width: 320)
    }
}
#endif