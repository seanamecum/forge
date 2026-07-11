import Foundation

/// The curated science behind Forge's recommendations. Every entry is a real,
/// stable reference — position stands and landmark studies, not blog posts.
/// The live coach may cite ONLY from this list (never invented citations);
/// the app surfaces it as "grounded in sport science" for transparency.
struct EvidenceItem: Identifiable, Equatable {
    var id: String { topic }
    let topic: String
    let claim: String
    let source: String
}

enum EvidenceBase {

    static let items: [EvidenceItem] = [
        EvidenceItem(
            topic: "Protein for muscle gain",
            claim: "0.7–1.0 g per lb of bodyweight daily (1.6–2.2 g/kg) supports muscle growth; distribution across meals matters.",
            source: "ISSN Position Stand: Protein & Exercise — Jäger et al., JISSN 2017"),
        EvidenceItem(
            topic: "Creatine",
            claim: "3–5 g/day of creatine monohydrate is the most effective and well-studied ergogenic supplement for strength and power.",
            source: "ISSN Position Stand: Creatine — Kreider et al., JISSN 2017"),
        EvidenceItem(
            topic: "Sleep & performance",
            claim: "Extending sleep improves sprint times, accuracy, and reaction time in athletes.",
            source: "Mah et al., SLEEP 2011 (Stanford sleep-extension study)"),
        EvidenceItem(
            topic: "Training load & injury",
            claim: "Rapid spikes in acute:chronic workload are associated with elevated injury risk; progress load gradually.",
            source: "Gabbett, British Journal of Sports Medicine 2016"),
        EvidenceItem(
            topic: "Tendinopathy rehab",
            claim: "Heavy-slow-resistance loading produces outcomes comparable to eccentric protocols for patellar tendinopathy, with better compliance.",
            source: "Kongsgaard et al., Scand J Med Sci Sports 2009; Beyer et al., AJSM 2015"),
        EvidenceItem(
            topic: "HRV-guided training",
            claim: "Adjusting training by daily HRV produces equal or better fitness gains than fixed programming.",
            source: "Kiviniemi et al., Eur J Appl Physiol 2007"),
        EvidenceItem(
            topic: "Caffeine timing",
            claim: "Caffeine taken even six hours before bed measurably disrupts sleep.",
            source: "Drake et al., Journal of Clinical Sleep Medicine 2013"),
        EvidenceItem(
            topic: "Return-to-sport criteria",
            claim: "Meeting objective return-to-sport criteria before returning substantially reduces reinjury risk.",
            source: "Grindem et al., British Journal of Sports Medicine 2016"),
    ]

    /// Compact block for the live coach's system prompt.
    static var promptBlock: String {
        items.map { "- \($0.topic): \($0.claim) [\($0.source)]" }.joined(separator: "\n")
    }
}
