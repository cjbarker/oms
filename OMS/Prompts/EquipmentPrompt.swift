import Foundation

struct DetectedEquipmentResponse: Codable {
    var detected: [String]            // raw EquipmentType rawValues
    var notes: String?
}

enum EquipmentPrompt {
    static let system = """
    You identify gym / home-workout equipment visible in a single photo.
    Respond ONLY with JSON of the form:
    {"detected": ["dumbbells", "bench"], "notes": "optional one-sentence observation"}

    Allowed values for "detected" (use these exact strings, nothing else):
    pullUpBar, dipBar, bench, dumbbells, barbell, kettlebell, resistanceBand,
    exerciseBike, rower, cable, squatRack, yogaMat, medicineBall, foamRoller,
    boxStep, trxStraps, treadmill, jumpRope

    Include every allowed item you can clearly see. Skip ambiguous items.
    Wrap the JSON in ```json fences. No prose outside the fences.
    """

    static let userInstruction = "Identify every piece of exercise equipment visible in this photo."
}
