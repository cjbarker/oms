import Foundation
import SwiftData

enum EquipmentType: String, Codable, CaseIterable, Identifiable, Hashable {
    case pullUpBar
    case dipBar
    case bench
    case dumbbells
    case barbell
    case kettlebell
    case resistanceBand
    case exerciseBike
    case rower
    case cable
    case squatRack
    case yogaMat
    case medicineBall
    case foamRoller
    case boxStep
    case trxStraps
    case treadmill
    case jumpRope

    var id: String { rawValue }

    var label: String {
        switch self {
        case .pullUpBar:      return "Pull-up bar"
        case .dipBar:         return "Dip bar / station"
        case .bench:          return "Bench"
        case .dumbbells:      return "Dumbbells"
        case .barbell:        return "Barbell"
        case .kettlebell:     return "Kettlebell"
        case .resistanceBand: return "Resistance bands"
        case .exerciseBike:   return "Exercise bike"
        case .rower:          return "Rower"
        case .cable:          return "Cable machine"
        case .squatRack:      return "Squat rack"
        case .yogaMat:        return "Yoga mat"
        case .medicineBall:   return "Medicine ball"
        case .foamRoller:     return "Foam roller"
        case .boxStep:        return "Box / step"
        case .trxStraps:      return "TRX / suspension straps"
        case .treadmill:      return "Treadmill"
        case .jumpRope:       return "Jump rope"
        }
    }

    var symbol: String {
        switch self {
        case .pullUpBar, .dipBar: return "figure.strengthtraining.traditional"
        case .dumbbells, .kettlebell: return "dumbbell.fill"
        case .barbell, .squatRack: return "figure.strengthtraining.functional"
        case .bench: return "bed.double.fill"
        case .resistanceBand, .trxStraps: return "arrow.left.and.right"
        case .exerciseBike: return "figure.outdoor.cycle"
        case .rower: return "figure.rower"
        case .treadmill: return "figure.run"
        case .cable: return "cable.connector"
        case .yogaMat, .foamRoller: return "rectangle"
        case .medicineBall: return "circle.fill"
        case .boxStep: return "square.stack.3d.up.fill"
        case .jumpRope: return "figure.jumprope"
        }
    }
}

@Model
final class Equipment {
    var typeRaw: String
    var note: String?
    var addedAt: Date

    init(type: EquipmentType, note: String? = nil) {
        self.typeRaw = type.rawValue
        self.note = note
        self.addedAt = Date()
    }

    var type: EquipmentType { EquipmentType(rawValue: typeRaw) ?? .yogaMat }
}

@Model
final class EquipmentProfile {
    @Attribute(.unique) var name: String
    var equipmentRaw: [String]
    var isActive: Bool
    var createdAt: Date

    init(name: String, equipment: [EquipmentType] = [], isActive: Bool = false) {
        self.name = name
        self.equipmentRaw = equipment.map(\.rawValue)
        self.isActive = isActive
        self.createdAt = Date()
    }

    var equipment: [EquipmentType] {
        get { equipmentRaw.compactMap(EquipmentType.init(rawValue:)) }
        set { equipmentRaw = newValue.map(\.rawValue) }
    }
}
