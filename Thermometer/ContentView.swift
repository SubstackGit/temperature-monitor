import SwiftUI

struct ContentView: View {
    @State private var sliderValue: Double = 40.0
    
    let minTemp = 10.0
    let maxTemp = 70.0
    
    var currentCelsius: Double { sliderValue }
    var currentFahrenheit: Double { (sliderValue * 9/5) + 32 }
    
    var fillPct: CGFloat {
        max(0, min(1, CGFloat((sliderValue - minTemp) / (maxTemp - minTemp))))
    }
    
    // PRESET CATEGORIES
    struct PresetCategory {
        let title: String
        let presets: [(icon: String, label: String, temp: Double)]
    }
    
    let leftCategories: [PresetCategory] = [
        PresetCategory(title: "Common", presets: [
            ("🏠", "Room", 20.0),
            ("☕", "Coffee", 60.0),
            ("🔥", "Hot", 70.0)
        ]),
        PresetCategory(title: "Weather", presets: [
            ("❄️", "Cold", 10.0),
            ("☀️", "Warm", 30.0),
            ("🌊", "Water", 40.0)
        ])
    ]
    
    let rightCategories: [PresetCategory] = [
        PresetCategory(title: "Health", presets: [
            ("🧊", "Cool Bath", 25.0),
            ("🤒", "Body Temp", 37.0),
            ("🔥", "Fever", 40.0)
        ]),
        PresetCategory(title: "Cooking", presets: [
            ("🧈", "Butter", 20.0),
            ("🍳", "Eggs", 45.0),
            ("🥐", "Oven", 70.0)
        ]),
        PresetCategory(title: "Aquarium", presets: [
            ("🐟", "Cold Water", 15.0),
            ("🐠", "Tropical", 25.0),
            ("⚠️", "Too Warm", 35.0)
        ])
    ]
    
    var body: some View {
        HStack(spacing: 12) {
            // LEFT COLUMN
            VStack(alignment: .leading, spacing: 4) {
                Text("Temperature")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer().frame(height: 6)
                
                // SLIDER: Moved UP (Higher than icons now)
                // Aligns roughly with ~40-45°C visually
                VStack(spacing: 4) {
                    Slider(value: $sliderValue, in: minTemp...maxTemp, step: 0.5)
                        .tint(.red)
                        .frame(width: 100) // Widened
                    
                    Text("\(String(format: "%.0f", currentCelsius))°C")
                        .font(.caption2)
                        .foregroundColor(.red)
                    
                    Text("\(String(format: "%.0f", currentFahrenheit))°F")
                        .font(.caption2)
                        .foregroundColor(.blue)
                }
                
                Spacer().frame(height: 18) // Gap between slider and icons (pushes icons down)
                
                // LEFT PRESETS: Common & Weather (Pushed Down)
                ForEach(leftCategories, id: \.title) { category in
                    CompactPresetGrid(category: category, action: { moveSlider(to: $0) })
                    if category.title != "Weather" { Spacer().frame(height: 4) }
                }
                
                Spacer() // Fill remaining space at bottom
            }
            
            // CENTER: Thermometer
            ThermometerCanvas(fillPct: fillPct, minTemp: minTemp, maxTemp: maxTemp)
                .frame(width: 100, height: 360)
            
            // RIGHT COLUMN
            VStack(alignment: .leading, spacing: 4) {
                Spacer().frame(height: 18) // Match left side gap
                
                // RIGHT PRESETS: Health, Cooking, Aquarium (Pushed Down to match Left)
                ForEach(rightCategories, id: \.title) { category in
                    CompactPresetGrid(category: category, action: { moveSlider(to: $0) })
                    if category.title != "Aquarium" { Spacer().frame(height: 4) }
                }
                
                Spacer() // Fill remaining space
            }
        }
        .padding(12)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .frame(width: 380, height: 430)
    }
    
    func moveSlider(to value: Double) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            sliderValue = value
        }
    }
}

// MARK: - Compact Preset Grid
struct CompactPresetGrid: View {
    let category: ContentView.PresetCategory
    let action: (Double) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(category.title)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(.secondary)
            
            HStack(spacing: 4) {
                ForEach(category.presets, id: \.temp) { preset in
                    Button(action: { action(preset.temp) }) {
                        Text(preset.icon)
                            .font(.system(size: 14))
                            .frame(width: 28, height: 28)
                            .background(Color.gray.opacity(0.15))
                            .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// MARK: - Thermometer Canvas Component (Safe Bulb)
struct ThermometerCanvas: View {
    let fillPct: CGFloat
    let minTemp: Double
    let maxTemp: Double
    
    var body: some View {
        Canvas { context, size in
            let tubeWidth: CGFloat = 16
            let tubeHeight: CGFloat = size.height - 45
            let tubeTop: CGFloat = 10
            let tubeBottom = tubeTop + tubeHeight
            let centerX = size.width / 2
            
            // Bulb: Radius 10, fully visible
            let bulbRadius: CGFloat = 10
            let bulbCenterY = tubeBottom + bulbRadius + 1
            
            // Bulb
            let bulbRect = CGRect(x: centerX - bulbRadius, y: bulbCenterY - bulbRadius, width: bulbRadius * 2, height: bulbRadius * 2)
            context.fill(Path(ellipseIn: bulbRect), with: .color(.red))
            context.stroke(Path(ellipseIn: bulbRect), with: .color(.gray.opacity(0.5)), lineWidth: 1)
            
            // Tube
            let tubeRect = CGRect(x: centerX - tubeWidth / 2, y: tubeTop, width: tubeWidth, height: tubeHeight)
            context.fill(Path(roundedRect: tubeRect, cornerRadius: 6), with: .color(.white))
            context.stroke(Path(roundedRect: tubeRect, cornerRadius: 6), with: .color(.gray.opacity(0.5)), lineWidth: 1)
            
            // Mercury
            let mercuryHeight = tubeHeight * fillPct
            if mercuryHeight > 2 {
                let mercuryRect = CGRect(x: centerX - tubeWidth / 2 + 2, y: tubeBottom - mercuryHeight, width: tubeWidth - 4, height: mercuryHeight)
                context.fill(Path(roundedRect: mercuryRect, cornerRadius: 4), with: .linearGradient(Gradient(colors: [.orange, .red]), startPoint: CGPoint(x: centerX, y: tubeBottom - mercuryHeight), endPoint: CGPoint(x: centerX, y: tubeBottom)))
            }
            
            // Ticks & Labels (Every 5 degrees)
            let step = 5
            for intC in stride(from: Int(minTemp), through: Int(maxTemp), by: step) {
                let celsius = Double(intC)
                let pct = (celsius - minTemp) / (maxTemp - minTemp)
                let tickY = tubeBottom - CGFloat(pct * Double(tubeHeight))
                
                let tickLength: CGFloat = 10
                let tickWidth: CGFloat = 1.5
                
                // Left Tick (Fahrenheit)
                var pathLeft = Path()
                pathLeft.move(to: CGPoint(x: centerX - tubeWidth/2, y: tickY))
                pathLeft.addLine(to: CGPoint(x: centerX - tubeWidth/2 - tickLength, y: tickY))
                context.stroke(pathLeft, with: .color(.gray), lineWidth: tickWidth)
                
                // Right Tick (Celsius)
                var pathRight = Path()
                pathRight.move(to: CGPoint(x: centerX + tubeWidth/2, y: tickY))
                pathRight.addLine(to: CGPoint(x: centerX + tubeWidth/2 + tickLength, y: tickY))
                context.stroke(pathRight, with: .color(.gray), lineWidth: tickWidth)
                
                // Labels
                let fahr = (celsius * 9/5) + 32
                
                let fLabel = "\(Int(fahr))°"
                context.draw(Text(fLabel).font(.system(size: 7)).foregroundColor(.blue), at: CGPoint(x: centerX - tubeWidth/2 - tickLength - 2, y: tickY), anchor: .trailing)
                
                let cLabel = "\(intC)°"
                context.draw(Text(cLabel).font(.system(size: 7)).foregroundColor(.red), at: CGPoint(x: centerX + tubeWidth/2 + tickLength + 2, y: tickY), anchor: .leading)
            }
        }
    }
}

#Preview {
    ContentView()
}
