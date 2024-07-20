//
//  sporttrackerTests.swift
//  sporttrackerTests
//
//  Created by Pyry Lahtinen on 20.7.2024.
//

import Testing

struct FormattersTests {

    @Test func testDistanceFormatting() {
        #expect(Formatters.distance(9.9173) == "0.00")
        #expect(Formatters.distance(10.0) == "0.01")
        #expect(Formatters.distance(12.459123) == "0.01")

        #expect(Formatters.distance(99.8172) == "0.09")
        #expect(Formatters.distance(100.0) == "0.10")
        #expect(Formatters.distance(192.3488) == "0.19")

        #expect(Formatters.distance(999.91782) == "0.99")
        #expect(Formatters.distance(1000.0) == "1.00")
        #expect(Formatters.distance(1038.7191) == "1.03")

        #expect(Formatters.distance(10518.5092) == "10.51")
        #expect(Formatters.distance(109376.1921) == "109.37")
        #expect(Formatters.distance(-12.1109) == "")
    }

}
