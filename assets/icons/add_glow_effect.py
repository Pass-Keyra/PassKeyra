"""
Script pour ajouter un effet de reflet/glow bleu autour du logo PassKeyra
"""
from PIL import Image, ImageDraw, ImageFilter
import os

def add_blue_glow(input_path, output_path, glow_color=(25, 140, 240), glow_intensity=0.4):
    """
    Ajoute un effet de reflet bleu autour de l'icône

    Args:
        input_path: Chemin de l'image source
        output_path: Chemin de l'image de sortie
        glow_color: Couleur du glow en RGB (par défaut: #198CF0)
        glow_intensity: Intensité du glow (0.0 à 1.0)
    """
    # Ouvrir l'image source
    img = Image.open(input_path).convert('RGBA')
    width, height = img.size

    # Créer une nouvelle image plus grande pour accueillir le glow
    glow_padding = int(min(width, height) * 0.15)  # 15% de padding pour le glow
    new_size = (width + glow_padding * 2, height + glow_padding * 2)

    # Créer l'image finale
    result = Image.new('RGBA', new_size, (255, 255, 255, 0))

    # Créer le glow (gradient radial)
    glow_layer = Image.new('RGBA', new_size, (255, 255, 255, 0))
    draw = ImageDraw.Draw(glow_layer)

    center_x = new_size[0] // 2
    center_y = new_size[1] // 2
    max_radius = int(min(width, height) // 2 * 0.85)  # 85% du rayon original pour éviter la coupure

    # Dessiner plusieurs cercles avec opacité décroissante pour créer le gradient
    num_circles = 50
    for i in range(num_circles, 0, -1):
        radius = int((i / num_circles) * max_radius)
        # Opacité décroissante du centre vers l'extérieur
        opacity = int((i / num_circles) ** 2 * 255 * glow_intensity)
        color = glow_color + (opacity,)

        bbox = [
            center_x - radius,
            center_y - radius,
            center_x + radius,
            center_y + radius
        ]
        draw.ellipse(bbox, fill=color)

    # Appliquer un flou gaussien pour adoucir le glow
    glow_layer = glow_layer.filter(ImageFilter.GaussianBlur(radius=20))

    # Composer les couches
    result = Image.alpha_composite(result, glow_layer)

    # Ajouter l'image originale au centre
    result.paste(img, (glow_padding, glow_padding), img)

    # Sauvegarder (SANS redimensionner pour conserver le padding complet)
    result.save(output_path, 'PNG')
    print(f"[OK] Image avec glow creee: {output_path}")
    print(f"  Taille originale: {width}x{height}")
    print(f"  Taille avec glow: {new_size[0]}x{new_size[1]} (padding: {glow_padding}px)")
    print(f"  Couleur: RGB{glow_color}")
    print(f"  Intensite: {glow_intensity}")


if __name__ == '__main__':
    script_dir = os.path.dirname(os.path.abspath(__file__))

    # Créer les versions avec glow
    files_to_process = [
        ('PassKeyra_centered.png', 'PassKeyra_centered_glow.png', 0.3),
        ('PassKeyra_adaptive.png', 'PassKeyra_adaptive_glow.png', 0.3),
    ]

    print("Ajout de l'effet de reflet bleu...")
    print("=" * 50)

    for input_file, output_file, intensity in files_to_process:
        input_path = os.path.join(script_dir, input_file)
        output_path = os.path.join(script_dir, output_file)

        if os.path.exists(input_path):
            add_blue_glow(
                input_path,
                output_path,
                glow_color=(25, 140, 240),  # #198CF0
                glow_intensity=intensity
            )
        else:
            print(f"[WARN] Fichier non trouve: {input_file}")

    print("=" * 50)
    print("\nPour utiliser ces nouvelles icônes:")
    print("1. Vérifiez les fichiers *_glow.png générés")
    print("2. Si l'effet vous convient, remplacez les fichiers originaux:")
    print("   - PassKeyra_centered.png")
    print("   - PassKeyra_adaptive.png")
    print("3. Regénérez les icônes avec: flutter pub run flutter_launcher_icons")
    print("4. Reconstruisez l'APK")
