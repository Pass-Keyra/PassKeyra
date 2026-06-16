"""
Script pour créer une icône avec fond rond blanc et clé bleue dedans
"""

from PIL import Image, ImageDraw, ImageFilter
import os
import sys
import numpy as np

def create_round_white_icon(input_path, output_path, size=1024):
    """
    Extrait la clé bleue et la place dans un fond rond blanc
    
    Args:
        input_path: Chemin de l'image source
        output_path: Chemin de l'image optimisée
        size: Taille cible (par défaut 1024x1024)
    """
    try:
        # Ouvrir l'image
        img = Image.open(input_path)
        print(f"Image originale: {img.size[0]}x{img.size[1]}")
        
        # Convertir en RGBA
        if img.mode != 'RGBA':
            img = img.convert('RGBA')
        
        # Convertir en array numpy
        img_array = np.array(img)
        gray = np.array(img.convert('L'))
        
        # Trouver la zone de la clé bleue (tout ce qui n'est pas blanc)
        # On cherche les pixels non-blancs (le logo bleu)
        white_threshold = 240
        
        # Trouver les limites du contenu (la clé bleue)
        non_white_pixels = np.where(gray < white_threshold)
        
        if len(non_white_pixels[0]) == 0:
            print("⚠ Aucun contenu non-blanc trouvé. Utilisation de l'image complète.")
            crop_left, crop_top = 0, 0
            crop_right, crop_bottom = img.size[0], img.size[1]
        else:
            crop_top = np.min(non_white_pixels[0])
            crop_bottom = np.max(non_white_pixels[0])
            crop_left = np.min(non_white_pixels[1])
            crop_right = np.max(non_white_pixels[1])
        
        # Ajouter une marge plus importante pour éviter les coupures
        margin_percent = 0.05  # 5% de marge pour éviter les coupures
        margin_x = int((crop_right - crop_left) * margin_percent)
        margin_y = int((crop_bottom - crop_top) * margin_percent)
        margin = max(margin_x, margin_y, 20)  # Au minimum 20 pixels
        
        crop_left = max(0, crop_left - margin)
        crop_top = max(0, crop_top - margin)
        crop_right = min(img.size[0], crop_right + margin)
        crop_bottom = min(img.size[1], crop_bottom + margin)
        
        # Extraire la clé bleue
        key_img = img.crop((crop_left, crop_top, crop_right, crop_bottom))
        print(f"Clé extraite: {(crop_right - crop_left)}x{(crop_bottom - crop_top)} pixels")
        
        # Convertir en RGBA si nécessaire
        if key_img.mode != 'RGBA':
            key_img = key_img.convert('RGBA')
        
        # Créer une nouvelle image carrée 1024x1024 avec fond blanc
        final_img = Image.new('RGB', (size, size), (255, 255, 255))
        
        # Calculer la taille pour la clé - LARGER EN LARGEUR, RÉDUIRE EN HAUTEUR
        circle_diameter = int(size * 0.9)  # 90% pour avoir une marge du cercle
        
        # Forcer des dimensions : très large en largeur, réduite en hauteur
        # Largeur maximale = 99% du diamètre pour bien allonger de droite à gauche
        max_width = int(circle_diameter * 0.99)
        # Hauteur limitée = 80% du diamètre pour réduire de haut en bas
        max_height = int(circle_diameter * 0.80)
        
        key_aspect = key_img.width / key_img.height
        
        # Essayer d'obtenir la largeur max, puis ajuster la hauteur
        key_new_width = max_width
        calculated_height_from_width = int(key_new_width / key_aspect)
        
        # Si la hauteur calculée dépasse la limite, on réduit la hauteur et on garde la largeur max
        # Cela va légèrement "écraser" la clé mais la rendra plus large
        if calculated_height_from_width > max_height:
            key_new_height = max_height
            # La largeur reste à max_width (on ne la réduit pas)
        else:
            key_new_height = calculated_height_from_width
        
        # Redimensionner avec un algorithme haute qualité
        key_resized = key_img.resize((key_new_width, key_new_height), Image.Resampling.LANCZOS)
        
        # Améliorer la netteté après redimensionnement
        # Appliquer un léger filtre de netteté pour améliorer la qualité
        key_resized = key_resized.filter(ImageFilter.SHARPEN)
        
        # Calculer la position pour centrer la clé
        x_offset = (size - key_new_width) // 2
        y_offset = (size - key_new_height) // 2
        
        # Créer un masque pour la clé (transparence)
        key_mask = key_resized.split()[3] if key_resized.mode == 'RGBA' else None
        
        # Créer une image temporaire RGBA pour gérer la transparence
        temp_img = Image.new('RGBA', (size, size), (255, 255, 255, 255))
        temp_img.paste(key_resized, (x_offset, y_offset), key_mask)
        
        # Dessiner un cercle blanc par-dessus
        # En fait, on va créer un masque circulaire et l'appliquer
        mask = Image.new('L', (size, size), 0)
        draw = ImageDraw.Draw(mask)
        
        # Dessiner un cercle blanc (rayon = 90% de la taille)
        circle_radius = size // 2 * 0.9
        center = size // 2
        draw.ellipse(
            [center - circle_radius, center - circle_radius, 
             center + circle_radius, center + circle_radius],
            fill=255
        )
        
        # Appliquer le masque circulaire
        final_img_rgba = Image.new('RGBA', (size, size), (255, 255, 255, 255))
        final_img_rgba.paste(temp_img, (0, 0))
        
        # Créer un masque pour le cercle (transparence à l'extérieur)
        circle_mask = Image.new('L', (size, size), 0)
        draw_circle = ImageDraw.Draw(circle_mask)
        draw_circle.ellipse(
            [center - circle_radius, center - circle_radius, 
             center + circle_radius, center + circle_radius],
            fill=255
        )
        
        # Appliquer le masque circulaire (transparence en dehors du cercle)
        final_img_rgba.putalpha(circle_mask)
        
        # Convertir en RGB avec fond blanc pour Android (pas de transparence)
        final_rgb = Image.new('RGB', (size, size), (255, 255, 255))
        final_rgb.paste(final_img_rgba, mask=final_img_rgba.split()[3])
        
        # Sauvegarder
        final_rgb.save(output_path, 'PNG', optimize=True, quality=100)
        
        # Afficher les informations
        file_size = os.path.getsize(output_path) / 1024  # Taille en KB
        print(f"✓ Icône créée: {output_path}")
        print(f"  Dimensions: {size}x{size} pixels")
        print(f"  Fond: Rond blanc")
        print(f"  Taille fichier: {file_size:.2f} KB")
        
        return True
        
    except Exception as e:
        print(f"✗ Erreur lors de la création: {str(e)}")
        import traceback
        traceback.print_exc()
        return False


if __name__ == "__main__":
    # Chemins des fichiers
    input_file = r"C:\Projet_PassKeyra\PassKeyra_Mobile\passkeyra\assets\icons\Screenshot_20251030-184112~2.png"
    output_file = r"C:\Projet_PassKeyra\PassKeyra_Mobile\passkeyra\assets\icons\Screenshot_20251030-184112~2.png"
    
    # Vérifier que le fichier existe
    if not os.path.exists(input_file):
        print(f"✗ Fichier introuvable: {input_file}")
        sys.exit(1)
    
    # Créer une copie de sauvegarde
    backup_file = input_file.replace('.png', '_backup3.png')
    try:
        import shutil
        shutil.copy2(input_file, backup_file)
        print(f"✓ Copie de sauvegarde créée: {backup_file}")
    except:
        pass
    
    # Créer l'icône avec fond rond blanc
    success = create_round_white_icon(input_file, output_file, size=1024)
    
    if success:
        print("\n✓ Icône créée avec succès !")
        print("  Fond rond blanc avec clé bleue centrée.")
        print("  Régénérez les icônes avec:")
        print("  flutter pub run flutter_launcher_icons:main")
    else:
        print("\n✗ Échec de la création")
        sys.exit(1)

