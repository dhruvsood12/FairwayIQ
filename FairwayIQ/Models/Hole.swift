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
    var handicapIndex: Int?
    var yardage: Int?
    var course: Course?

    init(number: Int, par: Int, handicapIndex: Int? = nil, yardage: Int? = nil) {
        self.number = number
        self.par = par
        self.handicapIndex = handicapIndex
        self.yardage = yardage
    }
}
