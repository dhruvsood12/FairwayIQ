//
//  Hole.swift
//  FairwayIQ
//

import Foundation
import SwiftData

@Model
final class Hole {
    var number: Int
    var par: Int
    var handicapIndex: Int
    var course: Course?

    init(number: Int, par: Int, handicapIndex: Int = 0) {
        self.number = number
        self.par = par
        self.handicapIndex = handicapIndex
    }
}
