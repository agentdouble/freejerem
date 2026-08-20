import CoreGraphics
import FreeJeremCore

func check(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else {
        fatalError("Échec : \(message)")
    }
}

let bounds = CGRect(x: 0, y: 0, width: 100, height: 80)
let target = MouseTargetCalculator.target(
    from: CGPoint(x: 98, y: 2),
    deltaX: 10,
    deltaY: -10,
    visibleBounds: bounds
)

check(target == CGPoint(x: 100, y: 0), "le déplacement doit rester dans l’écran")
check(RandomTextGenerator.alphabet.count == 26, "l’alphabet doit contenir 26 lettres")
check(RandomTextGenerator.character(at: 0) == "a", "la première lettre doit être a")
check(RandomTextGenerator.character(at: 25) == "z", "la dernière lettre doit être z")
check(RandomTextGenerator.character(at: 26) == "a", "l’index doit reboucler")

let profile = DailyActivityProfile.computerWorkday
check(profile.workdayDuration == 28_800, "la journée doit durer huit heures")
for _ in 0..<100 {
    check(profile.characterBudget.contains(profile.randomCharacterBudget()), "le plafond texte doit rester dans sa plage")
    check(profile.burstLength.contains(profile.randomBurstLength()), "la rafale doit rester dans sa plage")
    let mouseInterval = profile.randomMouseInterval(around: 20)
    check((8...48).contains(mouseInterval), "l’intervalle souris doit être borné")
}

var textGenerator = RandomTextGenerator()
for _ in 0..<100 {
    let burst = textGenerator.nextBurst(maxCharacters: 50)
    check(!burst.isEmpty, "une rafale ne doit pas être vide")
    check(burst.count <= 50, "une rafale doit respecter sa taille maximale")
}

print("OK — contrôles du cœur FreeJerem réussis")
