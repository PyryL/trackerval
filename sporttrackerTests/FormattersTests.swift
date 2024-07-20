//
//  FormattersTests.swift
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
        #expect(Formatters.distance(.nan) == "")
    }

    @Test func testDurationFormatting() {
        #expect(Formatters.duration(0.0) == "00.0")
        #expect(Formatters.duration(0.5) == "00.5")
        #expect(Formatters.duration(0.5010) == "00.6")
        #expect(Formatters.duration(0.5989) == "00.6")

        #expect(Formatters.duration(10.7192) == "10.8")
        #expect(Formatters.duration(58.1021) == "58.2")

        #expect(Formatters.duration(59.81) == "59.9")
        #expect(Formatters.duration(59.90) == "59.9")
        #expect(Formatters.duration(59.9001) == "1:00.0")
        #expect(Formatters.duration(60.0) == "1:00.0")
        #expect(Formatters.duration(60.0001) == "1:00.1")
        #expect(Formatters.duration(61.50238) == "1:01.6")

        #expect(Formatters.duration(74.9018) == "1:15.0")
        #expect(Formatters.duration(120.0711) == "2:00.1")
        #expect(Formatters.duration(682.3082) == "11:22.4")

        #expect(Formatters.duration(3599.9001) == "1:00:00.0")
        #expect(Formatters.duration(3600.0) == "1:00:00.0")
        #expect(Formatters.duration(3600.81023) == "1:00:00.9")
        #expect(Formatters.duration(3602.1291) == "1:00:02.2")
        #expect(Formatters.duration(3647.5985) == "1:00:47.6")
        #expect(Formatters.duration(3687.2984) == "1:01:27.3")

        #expect(Formatters.duration(9556.8429) == "2:39:16.9")
        #expect(Formatters.duration(52968.001812) == "14:42:48.1")
        #expect(Formatters.duration(-1.3101) == "")
        #expect(Formatters.duration(.nan) == "")
    }

    @Test func testSpeedFormatting() {
        #expect(Formatters.speed(0.0) == "0:00")
        #expect(Formatters.speed(0.0001) == "0:01")
        #expect(Formatters.speed(8.3918) == "0:09")
        #expect(Formatters.speed(12.4912) == "0:13")

        #expect(Formatters.speed(59.0184) == "1:00")
        #expect(Formatters.speed(60.0) == "1:00")
        #expect(Formatters.speed(74.1937) == "1:15")

        #expect(Formatters.speed(138.9739) == "2:19")
        #expect(Formatters.speed(352.40189) == "5:53")
        #expect(Formatters.speed(606.9192) == "10:07")
        #expect(Formatters.speed(737.391) == "12:18")

        #expect(Formatters.speed(-382.17819) == "")
        #expect(Formatters.speed(.nan) == "")
    }

    @Test func testHeartRateFormatting() {
        #expect(Formatters.heartRate(0.0) == "0")
        #expect(Formatters.heartRate(94.0) == "94")
        #expect(Formatters.heartRate(125.4) == "125")
        #expect(Formatters.heartRate(125.6) == "126")
        #expect(Formatters.heartRate(216.1948) == "216")

        #expect(Formatters.heartRate(-145) == "")
        #expect(Formatters.heartRate(.nan) == "")
    }

}
