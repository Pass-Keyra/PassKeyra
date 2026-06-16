"""
Script pour optimiser une image en icône d'application Android
Formats: 1024x1024 pixels, carré, optimisé
"""

from PIL import Image
import os
import sys

def optimize_icon(input_path, output_path, size=1024):
    """
    Optimise une image pour en faire une icône d'application
    
    Args:
        input_path: Chemin de l'image source
        output_path: Chemin de l'image optimisée
        size: Taille cible (par défaut 1024x1024)
    """
    try:
        # Ouvrir l'image
        img = Image.open(input_path)
        print(f"Image originale: {img.size[0]}x{img.size[1]}")
        
        # Convertir en RGBA si nécessaire (pour supporter la transparence)
        if img.mode != 'RGBA':
            img = img.convert('RGBA')
        
        # Calculer les dimensions pour garder le ratio et créer un carré
        width, height = img.size
        
        # Si l'image est déjà carrée
        if width == height:
            # Redimensionner à la taille cible
            img_resized = img.resize((size, size), Image.Resampling.LANCZOS)
        else:
            # Trouver la dimension la plus grande pour créer un carré
            max_dim = max(width, height)
            
            # Créer une nouvelle image carrée avec fond transparent
            square_img = Image.new('RGBA', (max_dim, max_dim), (0, 0, 0, 0))
            
            # Calculer la position pour centrer l'image originale
            x_offset = (max_dim - width) // 2
            y_offset = (max_dim - height) // 2
            
            # Coller l'image originale au centre
            square_img.paste(img, (x_offset, y_offset), img if img.mode == 'RGBA' else None)
            
            # Redimensionner à la taille cible
            img_resized = square_img.resize((size, size), Image.Resampling.LANCZOS)
        
        # Optimiser l'image (réduire la taille du fichier)
        img_resized = img_resized.convert('RGB')
        
        # Sauvegarder avec une qualité optimale
        img_resized.save(output_path, 'PNG', optimize=True, quality=95)
        
        # Afficher les informations
        file_size = os.path.getsize(output_path) / 1024  # Taille en KB
        print(f"✓ Image optimisée créée: {output_path}")
        print(f"  Dimensions: {size}x{size} pixels")
        print(f"  Taille fichier: {file_size:.2f} KB")
        
        return True
        
    except Exception as e:
        print(f"✗ Erreur lors de l'optimisation: {str(e)}")
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
    backup_file = input_file.replace('.png', '_backup.png')
    try:
        import shutil
        shutil.copy2(input_file, backup_file)
        print(f"✓ Copie de sauvegarde créée: {backup_file}")
    except:
        pass
    
    # Optimiser l'image
    success = optimize_icon(input_file, output_file, size=1024)
    
    if success:
        print("\n✓ Optimisation terminée avec succès !")
        print("  Vous pouvez maintenant régénérer les icônes avec:")
        print("  flutter pub run flutter_launcher_icons:main")
    else:
        print("\n✗ Échec de l'optimisation")
        sys.exit(1)

