# FreeJerem

FreeJerem est une petite application macOS native qui vit uniquement dans la barre des menus. Elle propose deux automatisations indépendantes :

- déplacer légèrement la souris à intervalle régulier ;
- ouvrir un vrai fichier `.txt`, y ajouter des lettres aléatoires et le sauvegarder en continu.

L’écriture se fait dans une fenêtre dédiée de FreeJerem afin de ne jamais envoyer de frappes dans une autre application par erreur.

## Rythme humain sur une journée

FreeJerem ne tape plus en continu. Le profil par défaut représente une journée de huit heures :

- objectif quotidien aléatoire entre 3 500 et 8 000 caractères ;
- pseudo-mots écrits par rafales de 15 à 65 caractères ;
- pauses aléatoires de 45 secondes à 3 minutes ;
- environ 7 % de pauses longues entre 5 et 15 minutes ;
- compteur conservé pour la journée, même après un arrêt ou un redémarrage ;
- arrêt automatique lorsque le plafond quotidien ou les huit heures sont atteints.

Les mouvements de souris utilisent aussi un intervalle aléatoire autour du réglage choisi. Leur compteur quotidien est calculé sur une journée de huit heures. Les compteurs sont visibles directement dans le menu.

## Raccourcis globaux

| Action | Raccourci |
| --- | --- |
| Activer/arrêter la souris | `⌥⌘M` |
| Activer/arrêter l’écriture | `⌥⌘T` |
| Activer/arrêter le mode mélange clavier + souris | `⌥⌘A` |
| Tout arrêter | `⌥⌘S` |

Le mode mélange active les deux automatismes ensemble. Si un seul est déjà actif, il démarre simplement le second afin de rejoindre le mode combiné.

## Construire et lancer

```zsh
chmod +x scripts/build-app.sh
./scripts/build-app.sh
open dist/FreeJerem.app
```

Le bundle final est créé dans `dist/FreeJerem.app`. Il est signé localement de manière ad hoc et peut être déplacé dans `/Applications`.

## Réglages

Depuis l’icône FreeJerem dans la barre des menus, ouvrez **Réglages…** pour changer :

- l’intervalle moyen et la distance des mouvements de souris ;
- le rythme de base de l’écriture dans les rafales ;
- le fichier texte utilisé.

Par défaut, le fichier est `~/Documents/FreeJerem/freejerem.txt`.

## Développement

```zsh
swift run FreeJeremCoreChecks
swift build
```

Le cœur testable se trouve dans `Sources/FreeJeremCore`. L’application, les automatisations, les raccourcis et les fenêtres sont séparés dans `Sources/FreeJeremApp`.
