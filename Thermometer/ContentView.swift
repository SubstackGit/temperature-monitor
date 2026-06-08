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
    
    let categories: [PresetCategory] = [
        PresetCategory(title: "Common", presets: [
            ("🏠", "Room", 20.0),
            ("☕", "Coffee", 60.0),
            ("🔥", "Hot", 70.0)
        ]),
        PresetCategory(title: "Weather", presets: [
            ("❄️", "Cold", 10.0),
            ("☀️", "Warm", 30.0),
            ("🌊", "Water", 40.0)
        ]),
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
        HStack(spacing: 20) {
            // LEFT COLUMN: First 2 categories
            VStack(alignment: .leading, spacing: 12) {
                Text("Temperature")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.secondary)
                
                ForEach(categories[0...1], id: \.title) { category in
                    PresetGrid(category: category, action: { moveSlider(to: $0) })
                }
            }
            
            // CENTER: Thermometer
            VStack(spacing: 8) {
                Text("Monitor")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                
                ThermometerCanvas(fillPct: fillPct, minTemp: minTemp, maxTemp: maxTemp)
                    .frame(height: 430)
                
                Slider(value: $sliderValue, in: minTemp...maxTemp, step: 0.5)
                    .tint(.red)
                
                Text("\(String(format: "%.1f", currentCelsius))°C / \(String(format: "%.1f", currentFahrenheit))°F")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.vertical, 10)
            
            // RIGHT COLUMN: Last 3 categories
            VStack(alignment: .leading, spacing: 12) {
                ForEach(categories[2...4], id: \.title) { category in
                    PresetGrid(category: category, action: { moveSlider(to: $0) })
                }
            }
        }
        .padding(20)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(16)
        .frame(width: 550, height: 650) // WIDER window for side columns
    }
    
    func moveSlider(to value: Double) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            sliderValue = value
        }
    }
}

// MARK: - Preset Grid Component (Compact horizontal row per category)
struct PresetGrid: View {
    let category: ContentView.PresetCategory
    let action: (Double) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(category.title)
                .font(.caption2)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 8) {
                ForEach(category.presets, id: \.temp) { preset in
                    Button(action: { action(preset.temp) }) {
                        VStack(spacing: 2) {
                            Text(preset.icon).font(.system(size: 16))
                            Text(String(format: "%.0f°", preset.temp)).font(.system(size: 9, weight: .medium))
                        }
                        .frame(width: 50, height: 45)
                        .background(Color.gray.opacity(0.15))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// MARK: - Thermometer Canvas Component
struct ThermometerCanvas: View {
    let fillPct: CGFloat
    let minTemp: Double
    let maxTemp: Double
    
    var body: some View {
        Canvas { context, size in
            let tubeWidth: CGFloat = 24
            let tubeHeight: CGFloat = size.height - 60
            let tubeTop: CGFloat = 10
            let tubeBottom = tubeTop + tubeHeight
            let centerX = size.width / 2
            let bulbRadius: CGFloat = 22
            let bulbCenterY = tubeBottom + bulbRadius + 5
            
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
            
            // Ticks & Labels
            for intC in Int(minTemp)...Int(maxTemp) {
                let celsius = Double(intC)
                let pct = (celsius - minTemp) / (maxTemp - minTemp)
                let tickY = tubeBottom - CGFloat(pct * Double(tubeHeight))
                
                let isMajor = intC % 5 == 0
                let tickLength: CGFloat = isMajor ? 12 : 7
                let tickWidth: CGFloat = isMajor ? 1.5 : 1.0
                
                // Left Tick (Fahrenheit)
                var pathLeft = Path()
                pathLeft.move(to: CGPoint(x: centerX - tubeWidth/2, y: tickY))
                pathLeft.addLine(to: CGPoint(x: centerX - tubeWidth/2 - tickLength, y: tickY))
                context.stroke(pathLeft, with: .color(.gray.opacity(isMajor ? 1 : 0.6)), lineWidth: tickWidth)
                
                // Right Tick (Celsius)
                var pathRight = Path()
                pathRight.move(to: CGPoint(x: centerX + tubeWidth/2, y: tickY))
                pathRight.addLine(to: CGPoint(x: centerX + tubeWidth/2 + tickLength, y: tickY))
                context.stroke(pathRight, with: .color(.gray.opacity(isMajor ? 1 : 0.6)), lineWidth: tickWidth)
                
                if isMajor {
                    let fahr = (celsius * 9/5) + 32
                    
                    let fLabel = "\(Int(fahr))°F"
                    context.draw(Text(fLabel).font(.system(size: 9)).foregroundColor(.blue), at: CGPoint(x: centerX - tubeWidth/2 - tickLength - 4, y: tickY), anchor: .trailing)
                    
                    let cLabel = "\(intC)°C"
                    context.draw(Text(cLabel).font(.system(size: 9)).foregroundColor(.red), at: CGPoint(x: centerX + tubeWidth/2 + tickLength + 4, y: tickY), anchor: .leading)
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
