import SwiftUI
import CoreLocation
import WidgetKit

struct LockScreenEntry: TimelineEntry {
    let date: Date
}

struct SimpleLockScreenProvider: TimelineProvider {
    func placeholder(in context: Context) -> LockScreenEntry {
        return LockScreenEntry(date: Date())
    }
    
    func getSnapshot(in context: Context, completion: @escaping (LockScreenEntry) -> Void) {
        let entry = LockScreenEntry(date: Date())
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<LockScreenEntry>) -> Void) {
        let entry = LockScreenEntry(date: Date())
        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
    }
}

@available(iOSApplicationExtension 16.0, *)
struct LocationSwitcherWidgetOn: Widget {
    let kind: String = "LocationSwitcherOn"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SimpleLockScreenProvider()) { entry in
            LocationSwitcherWidgetOnView(entry: entry)
        }
        .configurationDisplayName(NSLocalizedString("TurnOnLocationServices", comment: ""))
        .description("CFBundleDisplayName")
        .supportedFamilies([.accessoryCircular])
    }
}

@available(iOSApplicationExtension 16.0, *)
struct LocationSwitcherWidgetOff: Widget {
    let kind: String = "LocationSwitcherOff"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SimpleLockScreenProvider()) { entry in
            LocationSwitcherWidgetOffView(entry: entry)
        }
        .configurationDisplayName(NSLocalizedString("TurnOffLocationServices", comment: ""))
        .description("CFBundleDisplayName")
        .supportedFamilies([.accessoryCircular])
    }
}

struct LocationSwitcherWidgetOnView: View {
    var entry: LockScreenEntry
    
    var body: some View {
        ZStack {
            Image(systemName: "location.fill")
                .resizable()
                .scaledToFit()
                .padding(15)
                .accessibilityLabel(Text("TurnOnLocationServices")) // 无障碍化VoiceOver读取的描述
        }
        .applyLockScreenBackground() // 背景
    }
}

struct LocationSwitcherWidgetOffView: View {
    var entry: LockScreenEntry
    
    var body: some View {
        ZStack {
            Image(systemName: "location.slash.fill")
                .resizable()
                .scaledToFit()
                .padding(15)
                .accessibilityLabel(Text("TurnOffLocationServices")) // 无障碍化VoiceOver读取的描述
        }
        .applyLockScreenBackground() // 背景
    }
}

extension View {
    @ViewBuilder
    func applyLockScreenBackground() -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
            self.containerBackground(Color.blue, for: .widget)
        } else { // iOS 16 fallback
            self.background(Color.clear)
        }
    }
}
