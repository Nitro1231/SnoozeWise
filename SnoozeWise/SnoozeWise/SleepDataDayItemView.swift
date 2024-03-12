//
//  SleepDataDayItemView.swift
//  SnoozeWise
//
//  Created by Jun Park on 2/23/24.
//

import SwiftUI
import Charts

struct SleepDataDayItemView: View {
    @EnvironmentObject var health: Health
    @Binding var data: SleepDataDay
    @State private var isPresentingChartView = false

    var body: some View {
        Button(action: {
            self.isPresentingChartView = true
        }) {
            VStack {
                HStack {
                    Text(data.endDate.formatDate(format: "MMM d, yyyy"))
                        .font(.system(size: 20))
                        .bold()
                        .padding()
                    Spacer()
                    VStack (alignment: .trailing) {
                        Text("Time Asleep")
                            .font(.subheadline)
                            .bold()
                        Text(data.formattedTotalSleepDuration)
                            .font(.system(size: 20))
                    }
                    .padding()
                    
                }
                .foregroundColor(.primary)
                Chart {
                    ForEach(data.intervals.sorted(by: { $0.stage < $1.stage }), id: \.id) { interval in
                        RuleMark(
                            xStart: .value("Start Time", interval.startDate),
                            xEnd: .value("End Time", interval.endDate),
                            y: .value("Stage", 0)
                        )
                        .foregroundStyle(health.getColorForStage(interval.stage))
                        .lineStyle(StrokeStyle(lineWidth: 5))
                    }
                }
                .chartXAxis(.hidden)
                .chartYAxis(.hidden)
                .chartLegend(.hidden)
                .cornerRadius(15)
                .frame(height: 5)
                .background(Color(UIColor.systemBackground))
                .padding([.horizontal, .bottom])
            }
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(15)
        }
        .sheet(isPresented: $isPresentingChartView) {
            NavigationStack {
                SleepDataDayChartView(data: data)
                    .environmentObject(health)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") {
                                isPresentingChartView = false
                            }
                        }
                    }
            }
        }
    }
}
