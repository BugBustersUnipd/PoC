#!/usr/bin/env python3
"""
Script per generare immagini e PDF di test per l'OCR
Genera immagini PNG/JPEG e PDF che simulano documenti (cedolini, fatture, ecc.)
"""

from PIL import Image, ImageDraw, ImageFont, ImageFilter
from reportlab.lib.pagesizes import A4
from reportlab.lib.units import mm
from reportlab.pdfgen import canvas
from reportlab.lib import colors
import os
from datetime import datetime

# Crea le cartelle per i file di test
TEST_IMAGES_DIR = "immagini-test"
TEST_PDFS_DIR = "immagini-test"  # Stessa cartella per semplicità
os.makedirs(TEST_IMAGES_DIR, exist_ok=True)

def create_cedolino_image(filename):
    """Crea un'immagine che simula un cedolino"""
    # Crea un'immagine bianca A4-like (2480x3508 pixel a 300 DPI, ma più piccola per test)
    width, height = 1200, 1600
    img = Image.new('RGB', (width, height), color='white')
    draw = ImageDraw.Draw(img)
    
    # Prova a usare un font, altrimenti usa il default
    try:
        # Su Windows, prova con i font di sistema
        font_large = ImageFont.truetype("arial.ttf", 32)
        font_medium = ImageFont.truetype("arial.ttf", 24)
        font_small = ImageFont.truetype("arial.ttf", 18)
    except:
        # Font di default se non trova Arial
        font_large = ImageFont.load_default()
        font_medium = ImageFont.load_default()
        font_small = ImageFont.load_default()
    
    y = 50
    
    # Intestazione
    draw.text((width//2 - 150, y), "CEDOLINO STIPENDIO", fill='black', font=font_large)
    y += 60
    
    # Dati dipendente
    draw.text((50, y), "DIPENDENTE: Mario Rossi", fill='black', font=font_medium)
    y += 40
    draw.text((50, y), "CODICE FISCALE: RSSMRA80A01H501X", fill='black', font=font_medium)
    y += 40
    
    # Data competenza
    draw.text((50, y), f"DATA COMPETENZA: 31/12/2024", fill='black', font=font_medium)
    y += 60
    
    # Dettagli stipendio
    draw.text((50, y), "DETTAGLIO STIPENDIO", fill='black', font=font_medium)
    y += 40
    draw.text((100, y), "Stipendio base: € 2.500,00", fill='black', font=font_small)
    y += 30
    draw.text((100, y), "Trattenute: € 500,00", fill='black', font=font_small)
    y += 30
    draw.text((100, y), "NETTO: € 2.000,00", fill='black', font=font_medium)
    
    img.save(os.path.join(TEST_IMAGES_DIR, filename))
    print(f"[OK] Creato: {filename}")

def create_fattura_image(filename):
    """Crea un'immagine che simula una fattura"""
    width, height = 1200, 1600
    img = Image.new('RGB', (width, height), color='white')
    draw = ImageDraw.Draw(img)
    
    try:
        font_large = ImageFont.truetype("arial.ttf", 32)
        font_medium = ImageFont.truetype("arial.ttf", 24)
        font_small = ImageFont.truetype("arial.ttf", 18)
    except:
        font_large = ImageFont.load_default()
        font_medium = ImageFont.load_default()
        font_small = ImageFont.load_default()
    
    y = 50
    
    # Intestazione
    draw.text((width//2 - 100, y), "FATTURA", fill='black', font=font_large)
    y += 60
    
    # Numero fattura e data
    draw.text((50, y), "Fattura N. 001/2024", fill='black', font=font_medium)
    y += 40
    draw.text((50, y), "Data emissione: 15/01/2024", fill='black', font=font_medium)
    y += 60
    
    # Cliente
    draw.text((50, y), "Cliente:", fill='black', font=font_medium)
    y += 40
    draw.text((100, y), "Azienda S.r.l.", fill='black', font=font_small)
    y += 30
    draw.text((100, y), "CODICE FISCALE: AZISRL80A01H501Y", fill='black', font=font_small)
    y += 60
    
    # Dettagli
    draw.text((50, y), "Descrizione: Servizi di consulenza", fill='black', font=font_small)
    y += 40
    draw.text((50, y), "Importo: € 1.000,00 + IVA", fill='black', font=font_medium)
    
    img.save(os.path.join(TEST_IMAGES_DIR, filename))
    print(f"[OK] Creato: {filename}")

def create_cud_image(filename):
    """Crea un'immagine che simula un CUD"""
    width, height = 1200, 1600
    img = Image.new('RGB', (width, height), color='white')
    draw = ImageDraw.Draw(img)
    
    try:
        font_large = ImageFont.truetype("arial.ttf", 32)
        font_medium = ImageFont.truetype("arial.ttf", 24)
        font_small = ImageFont.truetype("arial.ttf", 18)
    except:
        font_large = ImageFont.load_default()
        font_medium = ImageFont.load_default()
        font_small = ImageFont.load_default()
    
    y = 50
    
    # Intestazione
    draw.text((width//2 - 100, y), "CERTIFICAZIONE UNICA", fill='black', font=font_large)
    y += 60
    
    # Anno
    draw.text((50, y), "ANNO 2024", fill='black', font=font_medium)
    y += 60
    
    # Dati dipendente
    draw.text((50, y), "DIPENDENTE: Luigi Bianchi", fill='black', font=font_medium)
    y += 40
    draw.text((50, y), "CODICE FISCALE: BNCLGU75B15H501Z", fill='black', font=font_medium)
    y += 60
    
    # Redditi
    draw.text((50, y), "Reddito complessivo: € 30.000,00", fill='black', font=font_small)
    y += 30
    draw.text((50, y), "Imposte: € 7.500,00", fill='black', font=font_small)
    
    img.save(os.path.join(TEST_IMAGES_DIR, filename))
    print(f"[OK] Creato: {filename}")

def create_ricevuta_image(filename):
    """Crea un'immagine che simula una ricevuta"""
    width, height = 800, 1200
    img = Image.new('RGB', (width, height), color='white')
    draw = ImageDraw.Draw(img)
    
    try:
        font_medium = ImageFont.truetype("arial.ttf", 24)
        font_small = ImageFont.truetype("arial.ttf", 18)
    except:
        font_medium = ImageFont.load_default()
        font_small = ImageFont.load_default()
    
    y = 50
    
    # Intestazione
    draw.text((width//2 - 80, y), "RICEVUTA", fill='black', font=font_medium)
    y += 60
    
    # Data
    draw.text((50, y), "Data: 20/12/2024", fill='black', font=font_small)
    y += 40
    
    # Importo
    draw.text((50, y), "Importo ricevuto: € 500,00", fill='black', font=font_medium)
    y += 60
    
    # Descrizione
    draw.text((50, y), "Per: Pagamento servizi", fill='black', font=font_small)
    
    img.save(os.path.join(TEST_IMAGES_DIR, filename))
    print(f"[OK] Creato: {filename}")

# ==================== FUNZIONI PER DOCUMENTI CON STRUTTURE DIVERSE ====================

def create_cedolino_con_matricola_image(filename):
    """Crea un cedolino con MATRICOLA e CF (struttura diversa: info in alto)"""
    width, height = 1200, 1600
    img = Image.new('RGB', (width, height), color='white')
    draw = ImageDraw.Draw(img)
    
    try:
        font_large = ImageFont.truetype("arial.ttf", 28)
        font_medium = ImageFont.truetype("arial.ttf", 20)
        font_small = ImageFont.truetype("arial.ttf", 16)
    except:
        font_large = ImageFont.load_default()
        font_medium = ImageFont.load_default()
        font_small = ImageFont.load_default()
    
    y = 30
    
    # Intestazione azienda in alto
    draw.text((50, y), "AZIENDA SRL - Ufficio Paghe", fill='black', font=font_medium)
    y += 40
    
    # TITOLO CENTRATO
    draw.text((width//2 - 120, y), "CEDOLINO STIPENDIO", fill='black', font=font_large)
    y += 50
    
    # SEZIONE DATI IN ALTO (layout diverso)
    draw.text((50, y), "MATRICOLA: 12345", fill='black', font=font_medium)
    y += 35
    draw.text((50, y), "DIPENDENTE: Paolo Bianchi", fill='black', font=font_medium)
    y += 35
    draw.text((50, y), "CODICE FISCALE: BNCPLA70B15H501K", fill='black', font=font_medium)
    y += 35
    draw.text((50, y), "DATA COMPETENZA: 30/11/2024", fill='black', font=font_medium)
    y += 60
    
    # Dettagli stipendio in basso
    draw.text((50, y), "DETTAGLIO STIPENDIO", fill='black', font=font_medium)
    y += 40
    draw.text((100, y), "Stipendio base: € 3.200,00", fill='black', font=font_small)
    y += 30
    draw.text((100, y), "Trattenute: € 650,00", fill='black', font=font_small)
    y += 30
    draw.text((100, y), "NETTO: € 2.550,00", fill='black', font=font_medium)
    
    img.save(os.path.join(TEST_IMAGES_DIR, filename))
    print(f"[OK] Creato: {filename}")

def create_fattura_solo_nome_image(filename):
    """Crea una fattura con SOLO NOME (senza CF) - layout orizzontale"""
    width, height = 1600, 1200  # Orizzontale
    img = Image.new('RGB', (width, height), color='white')
    draw = ImageDraw.Draw(img)
    
    try:
        font_large = ImageFont.truetype("arial.ttf", 28)
        font_medium = ImageFont.truetype("arial.ttf", 20)
        font_small = ImageFont.truetype("arial.ttf", 16)
    except:
        font_large = ImageFont.load_default()
        font_medium = ImageFont.load_default()
        font_small = ImageFont.load_default()
    
    # Layout a due colonne
    x_left = 50
    x_right = width // 2 + 50
    y = 50
    
    # Colonna sinistra - Mittente
    draw.text((x_left, y), "FATTURA N. 042/2024", fill='black', font=font_large)
    y += 50
    draw.text((x_left, y), "Data: 10/12/2024", fill='black', font=font_medium)
    y += 60
    
    # Colonna destra - Cliente (SOLO NOME, NO CF)
    draw.text((x_right, y), "Cliente:", fill='black', font=font_medium)
    y += 35
    draw.text((x_right, y), "Giuseppe Neri", fill='black', font=font_medium)
    y += 35
    draw.text((x_right, y), "Via Roma 123, Milano", fill='black', font=font_small)
    y += 60
    
    # Dettagli in basso
    draw.text((x_left, y), "Descrizione: Servizi informatici", fill='black', font=font_small)
    y += 40
    draw.text((x_left, y), "Importo: € 2.500,00 + IVA", fill='black', font=font_medium)
    
    img.save(os.path.join(TEST_IMAGES_DIR, filename))
    print(f"[OK] Creato: {filename}")

def create_documento_piu_nomi_image(filename):
    """Crea un documento con PIU' NOMI (destinatario, mittente, dipendente)"""
    width, height = 1200, 1800
    img = Image.new('RGB', (width, height), color='white')
    draw = ImageDraw.Draw(img)
    
    try:
        font_large = ImageFont.truetype("arial.ttf", 24)
        font_medium = ImageFont.truetype("arial.ttf", 18)
        font_small = ImageFont.truetype("arial.ttf", 14)
    except:
        font_large = ImageFont.load_default()
        font_medium = ImageFont.load_default()
        font_small = ImageFont.load_default()
    
    y = 40
    
    # Intestazione
    draw.text((width//2 - 100, y), "DOCUMENTO TRASFERIMENTO", fill='black', font=font_large)
    y += 60
    
    # MITTENTE (in alto)
    draw.text((50, y), "MITTENTE:", fill='black', font=font_medium)
    y += 30
    draw.text((100, y), "Azienda Alpha S.p.A.", fill='black', font=font_small)
    y += 25
    draw.text((100, y), "CF: ALPHAZ80A01H501A", fill='black', font=font_small)
    y += 50
    
    # DESTINATARIO (al centro)
    draw.text((50, y), "DESTINATARIO:", fill='black', font=font_medium)
    y += 30
    draw.text((100, y), "Azienda Beta S.r.l.", fill='black', font=font_small)
    y += 25
    draw.text((100, y), "CF: BETAZZ80A01H501B", fill='black', font=font_small)
    y += 50
    
    # DIPENDENTE TRASFERITO (in basso)
    draw.text((50, y), "DIPENDENTE TRASFERITO:", fill='black', font=font_medium)
    y += 30
    draw.text((100, y), "Marco Gialli", fill='black', font=font_small)
    y += 25
    draw.text((100, y), "CF: GLLMRC85D20H501C", fill='black', font=font_small)
    y += 50
    
    # Data competenza
    draw.text((50, y), "DATA COMPETENZA: 15/12/2024", fill='black', font=font_medium)
    
    img.save(os.path.join(TEST_IMAGES_DIR, filename))
    print(f"[OK] Creato: {filename}")

def create_cedolino_info_sotto_image(filename):
    """Crea un cedolino con INFO IN BASSO (layout invertito)"""
    width, height = 1200, 1600
    img = Image.new('RGB', (width, height), color='white')
    draw = ImageDraw.Draw(img)
    
    try:
        font_large = ImageFont.truetype("arial.ttf", 30)
        font_medium = ImageFont.truetype("arial.ttf", 22)
        font_small = ImageFont.truetype("arial.ttf", 18)
    except:
        font_large = ImageFont.load_default()
        font_medium = ImageFont.load_default()
        font_small = ImageFont.load_default()
    
    y = 50
    
    # TITOLO IN ALTO
    draw.text((width//2 - 130, y), "BUSTA PAGA", fill='black', font=font_large)
    y += 80
    
    # DETTAGLI STIPENDIO IN ALTO (invece che in basso)
    draw.text((50, y), "Periodo: Novembre 2024", fill='black', font=font_medium)
    y += 50
    draw.text((50, y), "Stipendio lordo: € 3.500,00", fill='black', font=font_small)
    y += 35
    draw.text((50, y), "Trattenute: € 700,00", fill='black', font=font_small)
    y += 35
    draw.text((50, y), "NETTO: € 2.800,00", fill='black', font=font_medium)
    y += 100
    
    # DATI DIPENDENTE IN BASSO (layout invertito)
    draw.text((50, height - 200), "DIPENDENTE: Francesca Neri", fill='black', font=font_medium)
    draw.text((50, height - 160), "CODICE FISCALE: NRIFRC90E25H501D", fill='black', font=font_medium)
    draw.text((50, height - 120), "DATA COMPETENZA: 30/11/2024", fill='black', font=font_medium)
    
    img.save(os.path.join(TEST_IMAGES_DIR, filename))
    print(f"[OK] Creato: {filename}")

def create_fattura_tabella_image(filename):
    """Crea una fattura con layout a TABELLA (struttura complessa)"""
    width, height = 1400, 1600
    img = Image.new('RGB', (width, height), color='white')
    draw = ImageDraw.Draw(img)
    
    try:
        font_large = ImageFont.truetype("arial.ttf", 26)
        font_medium = ImageFont.truetype("arial.ttf", 18)
        font_small = ImageFont.truetype("arial.ttf", 14)
    except:
        font_large = ImageFont.load_default()
        font_medium = ImageFont.load_default()
        font_small = ImageFont.load_default()
    
    y = 40
    
    # Intestazione
    draw.text((width//2 - 80, y), "FATTURA", fill='black', font=font_large)
    y += 50
    draw.text((50, y), "N. 156/2024 - Data: 20/12/2024", fill='black', font=font_medium)
    y += 80
    
    # Layout a tabella con righe
    x_col1 = 50
    x_col2 = 400
    
    # Riga 1: Cliente
    draw.text((x_col1, y), "Cliente:", fill='black', font=font_medium)
    draw.text((x_col2, y), "TecnoService S.r.l.", fill='black', font=font_small)
    y += 40
    draw.text((x_col2, y), "CF: TCSRVC85A01H501E", fill='black', font=font_small)
    y += 60
    
    # Riga 2: Descrizione
    draw.text((x_col1, y), "Descrizione:", fill='black', font=font_medium)
    draw.text((x_col2, y), "Consulenza tecnica", fill='black', font=font_small)
    y += 60
    
    # Riga 3: Importo
    draw.text((x_col1, y), "Importo:", fill='black', font=font_medium)
    draw.text((x_col2, y), "€ 1.800,00 + IVA", fill='black', font=font_medium)
    
    img.save(os.path.join(TEST_IMAGES_DIR, filename))
    print(f"[OK] Creato: {filename}")

def create_cud_solo_nome_image(filename):
    """Crea un CUD con SOLO NOME (senza CF)"""
    width, height = 1200, 1600
    img = Image.new('RGB', (width, height), color='white')
    draw = ImageDraw.Draw(img)
    
    try:
        font_large = ImageFont.truetype("arial.ttf", 28)
        font_medium = ImageFont.truetype("arial.ttf", 20)
        font_small = ImageFont.truetype("arial.ttf", 16)
    except:
        font_large = ImageFont.load_default()
        font_medium = ImageFont.load_default()
        font_small = ImageFont.load_default()
    
    y = 50
    
    # Intestazione
    draw.text((width//2 - 120, y), "CERTIFICAZIONE UNICA", fill='black', font=font_large)
    y += 60
    
    # Anno
    draw.text((50, y), "ANNO 2024", fill='black', font=font_medium)
    y += 60
    
    # SOLO NOME (senza CF)
    draw.text((50, y), "DIPENDENTE: Luca Rossi", fill='black', font=font_medium)
    y += 50
    
    # Redditi
    draw.text((50, y), "Reddito complessivo: € 28.000,00", fill='black', font=font_small)
    y += 30
    draw.text((50, y), "Imposte: € 6.500,00", fill='black', font=font_small)
    
    img.save(os.path.join(TEST_IMAGES_DIR, filename))
    print(f"[OK] Creato: {filename}")

# ==================== FUNZIONI PER IMMAGINI SFOCATE ====================

def create_blurred_version(original_filename, blurred_filename, blur_radius=2):
    """
    Crea una versione sfocata di un'immagine esistente
    blur_radius: intensità della sfocatura (1-5, dove 2 è leggera, 5 è molto sfocata)
    """
    original_path = os.path.join(TEST_IMAGES_DIR, original_filename)
    
    # Verifica che l'immagine originale esista
    if not os.path.exists(original_path):
        print(f"[SKIP] Immagine originale non trovata: {original_filename}")
        return
    
    # Carica l'immagine
    img = Image.open(original_path)
    
    # Applica sfocatura gaussiana
    blurred_img = img.filter(ImageFilter.GaussianBlur(radius=blur_radius))
    
    # Salva la versione sfocata
    blurred_path = os.path.join(TEST_IMAGES_DIR, blurred_filename)
    blurred_img.save(blurred_path)
    print(f"[OK] Creato (sfocato): {blurred_filename}")

def create_all_blurred_images():
    """Crea versioni sfocate di tutte le immagini di test"""
    print("\n[BLUR] Generazione immagini sfocate...")
    
    # Versioni leggermente sfocate (blur_radius=1.5) - ancora leggibili
    create_blurred_version("cedolino-test.png", "cedolino-test-sfocato-leggero.png", blur_radius=1.5)
    create_blurred_version("fattura-test.png", "fattura-test-sfocato-leggero.png", blur_radius=1.5)
    create_blurred_version("cud-test.png", "cud-test-sfocato-leggero.png", blur_radius=1.5)
    
    # Versioni moderatamente sfocate (blur_radius=2.5) - più difficile da leggere
    create_blurred_version("cedolino-test.png", "cedolino-test-sfocato-moderato.png", blur_radius=2.5)
    create_blurred_version("fattura-test.png", "fattura-test-sfocato-moderato.png", blur_radius=2.5)
    
    # Versione molto sfocata (blur_radius=3.5) - test estremo
    create_blurred_version("cedolino-test.png", "cedolino-test-sfocato-forte.png", blur_radius=3.5)

# ==================== FUNZIONI PER PDF ====================

def create_cedolino_pdf(filename):
    """Crea un PDF che simula un cedolino"""
    c = canvas.Canvas(os.path.join(TEST_PDFS_DIR, filename), pagesize=A4)
    width, height = A4
    
    # Intestazione
    c.setFont("Helvetica-Bold", 24)
    c.drawString(50, height - 50, "CEDOLINO STIPENDIO")
    
    y = height - 100
    
    # Dati dipendente
    c.setFont("Helvetica", 14)
    c.drawString(50, y, "DIPENDENTE: Mario Rossi")
    y -= 30
    c.drawString(50, y, "CODICE FISCALE: RSSMRA80A01H501X")
    y -= 30
    
    # Data competenza
    c.drawString(50, y, "DATA COMPETENZA: 31/12/2024")
    y -= 50
    
    # Dettagli stipendio
    c.setFont("Helvetica-Bold", 14)
    c.drawString(50, y, "DETTAGLIO STIPENDIO")
    y -= 30
    
    c.setFont("Helvetica", 12)
    c.drawString(100, y, "Stipendio base: € 2.500,00")
    y -= 25
    c.drawString(100, y, "Trattenute: € 500,00")
    y -= 25
    c.setFont("Helvetica-Bold", 14)
    c.drawString(100, y, "NETTO: € 2.000,00")
    
    c.save()
    print(f"[OK] Creato: {filename}")

def create_fattura_pdf(filename):
    """Crea un PDF che simula una fattura"""
    c = canvas.Canvas(os.path.join(TEST_PDFS_DIR, filename), pagesize=A4)
    width, height = A4
    
    # Intestazione
    c.setFont("Helvetica-Bold", 24)
    c.drawString(50, height - 50, "FATTURA")
    
    y = height - 100
    
    # Numero fattura e data
    c.setFont("Helvetica", 14)
    c.drawString(50, y, "Fattura N. 001/2024")
    y -= 30
    c.drawString(50, y, "Data emissione: 15/01/2024")
    y -= 50
    
    # Cliente
    c.setFont("Helvetica-Bold", 14)
    c.drawString(50, y, "Cliente:")
    y -= 30
    c.setFont("Helvetica", 12)
    c.drawString(100, y, "Azienda S.r.l.")
    y -= 25
    c.drawString(100, y, "CODICE FISCALE: AZISRL80A01H501Y")
    y -= 50
    
    # Dettagli
    c.drawString(50, y, "Descrizione: Servizi di consulenza")
    y -= 30
    c.setFont("Helvetica-Bold", 14)
    c.drawString(50, y, "Importo: € 1.000,00 + IVA")
    
    c.save()
    print(f"[OK] Creato: {filename}")

def create_cud_pdf(filename):
    """Crea un PDF che simula un CUD"""
    c = canvas.Canvas(os.path.join(TEST_PDFS_DIR, filename), pagesize=A4)
    width, height = A4
    
    # Intestazione
    c.setFont("Helvetica-Bold", 24)
    c.drawString(50, height - 50, "CERTIFICAZIONE UNICA")
    
    y = height - 100
    
    # Anno
    c.setFont("Helvetica-Bold", 16)
    c.drawString(50, y, "ANNO 2024")
    y -= 50
    
    # Dati dipendente
    c.setFont("Helvetica", 14)
    c.drawString(50, y, "DIPENDENTE: Luigi Bianchi")
    y -= 30
    c.drawString(50, y, "CODICE FISCALE: BNCLGU75B15H501Z")
    y -= 50
    
    # Redditi
    c.drawString(50, y, "Reddito complessivo: € 30.000,00")
    y -= 25
    c.drawString(50, y, "Imposte: € 7.500,00")
    
    c.save()
    print(f"[OK] Creato: {filename}")

def create_ricevuta_pdf(filename):
    """Crea un PDF che simula una ricevuta"""
    c = canvas.Canvas(os.path.join(TEST_PDFS_DIR, filename), pagesize=A4)
    width, height = A4
    
    # Intestazione
    c.setFont("Helvetica-Bold", 20)
    c.drawString(50, height - 50, "RICEVUTA")
    
    y = height - 100
    
    # Data
    c.setFont("Helvetica", 12)
    c.drawString(50, y, "Data: 20/12/2024")
    y -= 40
    
    # Importo
    c.setFont("Helvetica-Bold", 14)
    c.drawString(50, y, "Importo ricevuto: € 500,00")
    y -= 50
    
    # Descrizione
    c.setFont("Helvetica", 12)
    c.drawString(50, y, "Per: Pagamento servizi")
    
    c.save()
    print(f"[OK] Creato: {filename}")

def create_busta_paga_pdf(filename):
    """Crea un PDF che simula una busta paga più dettagliata"""
    c = canvas.Canvas(os.path.join(TEST_PDFS_DIR, filename), pagesize=A4)
    width, height = A4
    
    # Intestazione
    c.setFont("Helvetica-Bold", 20)
    c.drawString(50, height - 50, "BUSTA PAGA")
    
    y = height - 100
    
    # Periodo
    c.setFont("Helvetica", 12)
    c.drawString(50, y, "Periodo: Dicembre 2024")
    y -= 40
    
    # Dati dipendente
    c.setFont("Helvetica-Bold", 14)
    c.drawString(50, y, "DIPENDENTE: Anna Verdi")
    y -= 25
    c.setFont("Helvetica", 12)
    c.drawString(50, y, "CODICE FISCALE: VRDNNA85C45H501W")
    y -= 40
    
    # Data competenza
    c.drawString(50, y, "DATA COMPETENZA: 31/12/2024")
    y -= 50
    
    # Dettagli
    c.setFont("Helvetica-Bold", 12)
    c.drawString(50, y, "COMPETENZE")
    y -= 25
    c.setFont("Helvetica", 11)
    c.drawString(100, y, "Stipendio base: € 2.800,00")
    y -= 20
    c.drawString(100, y, "Premio produzione: € 200,00")
    y -= 20
    c.drawString(100, y, "TOTALE COMPETENZE: € 3.000,00")
    y -= 40
    
    c.setFont("Helvetica-Bold", 12)
    c.drawString(50, y, "TRATTENUTE")
    y -= 25
    c.setFont("Helvetica", 11)
    c.drawString(100, y, "IRPEF: € 600,00")
    y -= 20
    c.drawString(100, y, "INPS: € 300,00")
    y -= 20
    c.drawString(100, y, "TOTALE TRATTENUTE: € 900,00")
    y -= 40
    
    c.setFont("Helvetica-Bold", 14)
    c.drawString(50, y, "NETTO DA PAGARE: € 2.100,00")
    
    c.save()
    print(f"[OK] Creato: {filename}")

# ==================== PDF CON STRUTTURE DIVERSE ====================

def create_cedolino_con_matricola_pdf(filename):
    """PDF cedolino con matricola e CF"""
    c = canvas.Canvas(os.path.join(TEST_PDFS_DIR, filename), pagesize=A4)
    width, height = A4
    
    c.setFont("Helvetica", 12)
    c.drawString(50, height - 30, "AZIENDA SRL - Ufficio Paghe")
    
    c.setFont("Helvetica-Bold", 22)
    c.drawString(50, height - 70, "CEDOLINO STIPENDIO")
    
    y = height - 120
    c.setFont("Helvetica", 13)
    c.drawString(50, y, "MATRICOLA: 12345")
    y -= 30
    c.drawString(50, y, "DIPENDENTE: Paolo Bianchi")
    y -= 30
    c.drawString(50, y, "CODICE FISCALE: BNCPLA70B15H501K")
    y -= 30
    c.drawString(50, y, "DATA COMPETENZA: 30/11/2024")
    y -= 50
    c.setFont("Helvetica-Bold", 13)
    c.drawString(50, y, "DETTAGLIO STIPENDIO")
    y -= 30
    c.setFont("Helvetica", 11)
    c.drawString(100, y, "Stipendio base: € 3.200,00")
    y -= 25
    c.drawString(100, y, "Trattenute: € 650,00")
    y -= 25
    c.setFont("Helvetica-Bold", 13)
    c.drawString(100, y, "NETTO: € 2.550,00")
    
    c.save()
    print(f"[OK] Creato: {filename}")

def create_fattura_solo_nome_pdf(filename):
    """PDF fattura con solo nome (senza CF)"""
    c = canvas.Canvas(os.path.join(TEST_PDFS_DIR, filename), pagesize=A4)
    width, height = A4
    
    c.setFont("Helvetica-Bold", 22)
    c.drawString(50, height - 50, "FATTURA N. 042/2024")
    
    y = height - 90
    c.setFont("Helvetica", 13)
    c.drawString(50, y, "Data: 10/12/2024")
    y -= 60
    
    c.setFont("Helvetica-Bold", 13)
    c.drawString(50, y, "Cliente:")
    y -= 30
    c.setFont("Helvetica", 12)
    c.drawString(100, y, "Giuseppe Neri")
    y -= 25
    c.drawString(100, y, "Via Roma 123, Milano")
    y -= 50
    
    c.drawString(50, y, "Descrizione: Servizi informatici")
    y -= 40
    c.setFont("Helvetica-Bold", 13)
    c.drawString(50, y, "Importo: € 2.500,00 + IVA")
    
    c.save()
    print(f"[OK] Creato: {filename}")

def create_documento_piu_nomi_pdf(filename):
    """PDF con più nomi (destinatario, mittente, dipendente)"""
    c = canvas.Canvas(os.path.join(TEST_PDFS_DIR, filename), pagesize=A4)
    width, height = A4
    
    c.setFont("Helvetica-Bold", 20)
    c.drawString(50, height - 50, "DOCUMENTO TRASFERIMENTO")
    
    y = height - 100
    c.setFont("Helvetica-Bold", 13)
    c.drawString(50, y, "MITTENTE:")
    y -= 30
    c.setFont("Helvetica", 11)
    c.drawString(100, y, "Azienda Alpha S.p.A.")
    y -= 25
    c.drawString(100, y, "CF: ALPHAZ80A01H501A")
    y -= 50
    
    c.setFont("Helvetica-Bold", 13)
    c.drawString(50, y, "DESTINATARIO:")
    y -= 30
    c.setFont("Helvetica", 11)
    c.drawString(100, y, "Azienda Beta S.r.l.")
    y -= 25
    c.drawString(100, y, "CF: BETAZZ80A01H501B")
    y -= 50
    
    c.setFont("Helvetica-Bold", 13)
    c.drawString(50, y, "DIPENDENTE TRASFERITO:")
    y -= 30
    c.setFont("Helvetica", 11)
    c.drawString(100, y, "Marco Gialli")
    y -= 25
    c.drawString(100, y, "CF: GLLMRC85D20H501C")
    y -= 50
    
    c.setFont("Helvetica", 13)
    c.drawString(50, y, "DATA COMPETENZA: 15/12/2024")
    
    c.save()
    print(f"[OK] Creato: {filename}")

def create_cedolino_info_sotto_pdf(filename):
    """PDF cedolino con info in basso (layout invertito)"""
    c = canvas.Canvas(os.path.join(TEST_PDFS_DIR, filename), pagesize=A4)
    width, height = A4
    
    c.setFont("Helvetica-Bold", 26)
    c.drawString(50, height - 50, "BUSTA PAGA")
    
    y = height - 100
    c.setFont("Helvetica", 13)
    c.drawString(50, y, "Periodo: Novembre 2024")
    y -= 50
    c.drawString(50, y, "Stipendio lordo: € 3.500,00")
    y -= 35
    c.drawString(50, y, "Trattenute: € 700,00")
    y -= 35
    c.setFont("Helvetica-Bold", 13)
    c.drawString(50, y, "NETTO: € 2.800,00")
    
    # Info in basso
    y = 200
    c.setFont("Helvetica", 13)
    c.drawString(50, y, "DIPENDENTE: Francesca Neri")
    y -= 30
    c.drawString(50, y, "CODICE FISCALE: NRIFRC90E25H501D")
    y -= 30
    c.drawString(50, y, "DATA COMPETENZA: 30/11/2024")
    
    c.save()
    print(f"[OK] Creato: {filename}")

def create_cud_solo_nome_pdf(filename):
    """PDF CUD con solo nome (senza CF)"""
    c = canvas.Canvas(os.path.join(TEST_PDFS_DIR, filename), pagesize=A4)
    width, height = A4
    
    c.setFont("Helvetica-Bold", 24)
    c.drawString(50, height - 50, "CERTIFICAZIONE UNICA")
    
    y = height - 100
    c.setFont("Helvetica-Bold", 16)
    c.drawString(50, y, "ANNO 2024")
    y -= 50
    
    c.setFont("Helvetica", 14)
    c.drawString(50, y, "DIPENDENTE: Luca Rossi")
    y -= 50
    
    c.setFont("Helvetica", 12)
    c.drawString(50, y, "Reddito complessivo: € 28.000,00")
    y -= 25
    c.drawString(50, y, "Imposte: € 6.500,00")
    
    c.save()
    print(f"[OK] Creato: {filename}")

if __name__ == "__main__":
    print("Generazione immagini e PDF di test per OCR...")
    print("=" * 50)
    
    print("\n[1/4] Generazione immagini base...")
    # Genera vari tipi di documenti come immagini
    create_cedolino_image("cedolino-test.png")
    create_cedolino_image("cedolino-test.jpg")
    create_fattura_image("fattura-test.png")
    create_cud_image("cud-test.png")
    create_ricevuta_image("ricevuta-test.png")
    
    print("\n[2/4] Generazione immagini con strutture diverse...")
    # Genera immagini con layout e campi diversi
    create_cedolino_con_matricola_image("cedolino-matricola-test.png")
    create_fattura_solo_nome_image("fattura-solo-nome-test.png")
    create_documento_piu_nomi_image("documento-piu-nomi-test.png")
    create_cedolino_info_sotto_image("cedolino-info-sotto-test.png")
    create_fattura_tabella_image("fattura-tabella-test.png")
    create_cud_solo_nome_image("cud-solo-nome-test.png")
    
    print("\n[3/4] Generazione PDF...")
    # Genera vari tipi di documenti come PDF
    create_cedolino_pdf("cedolino-test.pdf")
    create_fattura_pdf("fattura-test.pdf")
    create_cud_pdf("cud-test.pdf")
    create_ricevuta_pdf("ricevuta-test.pdf")
    create_busta_paga_pdf("busta-paga-test.pdf")
    
    print("\n[4/4] Generazione PDF con strutture diverse...")
    # Genera PDF con layout diversi
    create_cedolino_con_matricola_pdf("cedolino-matricola-test.pdf")
    create_fattura_solo_nome_pdf("fattura-solo-nome-test.pdf")
    create_documento_piu_nomi_pdf("documento-piu-nomi-test.pdf")
    create_cedolino_info_sotto_pdf("cedolino-info-sotto-test.pdf")
    create_cud_solo_nome_pdf("cud-solo-nome-test.pdf")
    
    print("\n[EXTRA] Generazione immagini sfocate...")
    # Genera versioni sfocate per testare la robustezza dell'OCR
    create_all_blurred_images()
    
    print("=" * 50)
    print(f"\n[OK] File generati nella cartella: {TEST_IMAGES_DIR}/")
    print("\nPuoi usare questi file per testare l'OCR su:")
    print("  http://localhost:3000/documentTester.html")
    print("\nFormati supportati: PNG, JPEG, WebP, PDF")

