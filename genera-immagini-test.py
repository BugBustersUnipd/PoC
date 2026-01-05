#!/usr/bin/env python3
"""
Script avanzato per generare immagini e PDF di test per l'OCR
Genera documenti realistici simili a cedolini, fatture, CUD, ecc.
Con supporto per PDF nativi e PDF scansionati
"""

from PIL import Image, ImageDraw, ImageFont, ImageFilter, ImageEnhance
from reportlab.lib.pagesizes import A4
from reportlab.pdfgen import canvas
from reportlab.lib import colors
import os
import random
import numpy as np
from datetime import datetime
from faker import Faker  # Per dati realistici

# Installa faker se non presente: pip install faker
try:
    fake = Faker('it_IT')  # Dati italiani
except:
    # Fallback se faker non è disponibile
    class SimpleFaker:
        def name(self):
            return f"Nome Cognome {random.randint(1, 100)}"
        def ssn(self):
            return f"ABCDEF{random.randint(10, 99)}A{random.randint(10, 99)}Z{random.randint(100, 999)}X"
        def company(self):
            return f"Azienda {random.randint(1, 100)} S.p.A."
        def street_address(self):
            return f"Via Roma {random.randint(1, 200)}"
        def city(self):
            return random.choice(["Milano", "Roma", "Torino", "Napoli", "Firenze"])
        def postcode(self):
            return f"{random.randint(10000, 99999)}"
        def vat_id(self):
            return f"{random.randint(10000000000, 99999999999)}"
        def bban(self):
            return f"{random.randint(1000000000, 9999999999)}"
    
    fake = SimpleFaker()

# Crea le cartelle per i file di test
TEST_IMAGES_DIR = "documenti-test-ocr"
TEST_PDFS_DIR = "documenti-test-ocr"
os.makedirs(TEST_IMAGES_DIR, exist_ok=True)

# ==================== FUNZIONI PER EFFETTI REALISTICI ====================

def add_noise(img, intensity=0.01):
    """Aggiunge rumore all'immagine per simulare una scansione reale"""
    if img.mode != 'RGB':
        img = img.convert('RGB')
    
    arr = np.array(img).astype(np.float32)
    noise = np.random.randn(*arr.shape) * intensity * 255
    arr = arr + noise
    arr = np.clip(arr, 0, 255).astype(np.uint8)
    
    return Image.fromarray(arr)

def add_scan_lines(img, num_lines=3):
    """Aggiunge linee di scansione imperfetta"""
    draw = ImageDraw.Draw(img, 'RGBA')
    width, height = img.size
    
    for _ in range(num_lines):
        y = random.randint(50, height - 50)
        thickness = random.randint(1, 3)
        length = random.randint(100, width - 100)
        x_start = random.randint(50, width - length - 50)
        
        # Linea semi-trasparente
        for i in range(thickness):
            draw.line([(x_start, y+i), (x_start+length, y+i)], 
                     fill=(200, 200, 200, 30), width=1)
    
    return img

def add_fold_marks(img):
    """Aggiunge segni di piegatura"""
    draw = ImageDraw.Draw(img, 'RGBA')
    width, height = img.size
    
    # Segni angolari
    corner_size = 15
    draw.rectangle([(5, 5), (5+corner_size, 5+2)], fill=(100, 100, 100, 100))
    draw.rectangle([(5, 5), (5+2, 5+corner_size)], fill=(100, 100, 100, 100))
    
    draw.rectangle([(width-20, 5), (width-5, 5+2)], fill=(100, 100, 100, 100))
    draw.rectangle([(width-2, 5), (width-2, 5+corner_size)], fill=(100, 100, 100, 100))
    
    return img

def create_realistic_effects(img):
    """Applica tutti gli effetti realistici all'immagine"""
    # Aggiungi effetti di scansione
    img = add_scan_lines(img, num_lines=random.randint(1, 4))
    img = add_fold_marks(img)
    
    # Aggiungi leggera sfocatura per realismo
    img = img.filter(ImageFilter.GaussianBlur(radius=0.3))
    
    # Aggiungi rumore
    img = add_noise(img, intensity=0.005)
    
    # Regola contrasto e luminosità
    enhancer = ImageEnhance.Contrast(img)
    img = enhancer.enhance(1.1)
    
    return img

# ==================== FUNZIONI PER IMMAGINI (SENZA SOVRAPPOSIZIONI) ====================

def create_realistic_cedolino_image(filename, output_format="png"):
    """Crea un cedolino realistico come immagine senza sovrapposizioni"""
    width, height = 1800, 2400  # Dimensioni aumentate per evitare sovrapposizioni
    img = Image.new('RGB', (width, height), color=(248, 248, 248))
    draw = ImageDraw.Draw(img)
    
    try:
        # Prova diversi font
        font_bold = ImageFont.truetype("arialbd.ttf", 28)
        font_normal = ImageFont.truetype("arial.ttf", 22)
        font_small = ImageFont.truetype("arial.ttf", 18)
        font_tiny = ImageFont.truetype("arial.ttf", 14)
    except:
        # Font di default con dimensioni adeguate
        font_bold = ImageFont.load_default()
        font_normal = ImageFont.load_default()
        font_small = ImageFont.load_default()
        font_tiny = ImageFont.load_default()
    
    # Variabile per la posizione verticale
    y = 50
    
    # Intestazione
    draw.rectangle([(0, y-30), (width, y+90)], fill=(0, 51, 102))
    draw.text((width//2 - 250, y), "ZETA SERVICE S.R.L.", fill='white', font=font_bold)
    draw.text((width//2 - 200, y+50), "SISTEMA PAGHE E RETRIBUZIONI", fill=(200, 200, 255), font=font_small)
    
    y += 140  # Spazio dopo intestazione
    
    # Titolo
    draw.text((width//2 - 150, y), "CEDOLINO PAGA", fill=(0, 51, 102), font=font_bold)
    y += 70
    
    # Dati azienda - prima riga
    draw.text((100, y), "CODICE AZIENDA: 999999", fill='black', font=font_small)
    draw.text((width//2 + 100, y), "RAGIONE SOCIALE: Zeta Service S.r.l.", fill='black', font=font_small)
    y += 40
    
    # Dati azienda - seconda riga
    draw.text((100, y), "INDIRIZZO: Viale Ortles, 12", fill='black', font=font_small)
    draw.text((width//2 + 100, y), "20100 MILANO (MI)", fill='black', font=font_small)
    y += 40
    
    # Dati azienda - terza riga
    draw.text((100, y), "CODICE FISCALE: 12345678901", fill='black', font=font_small)
    draw.text((width//2 + 100, y), "PARTITA IVA: 01234567890", fill='black', font=font_small)
    y += 70
    
    # Rettangolo dati dipendente
    rect_y_start = y
    draw.rectangle([(80, y), (width-80, y+200)], outline=(0, 51, 102), width=2)
    
    # Colonna sinistra - dati dipendente
    draw.text((100, y+30), "CODICE DIPENDENTE:", fill='black', font=font_small)
    draw.text((300, y+30), "001234", fill='black', font=font_bold)
    
    draw.text((100, y+70), "NOME E COGNOME:", fill='black', font=font_small)
    nome = fake.name().upper()
    draw.text((300, y+70), nome, fill='black', font=font_normal)
    
    draw.text((100, y+110), "CODICE FISCALE:", fill='black', font=font_small)
    cf = fake.ssn().upper()
    draw.text((300, y+110), cf, fill='black', font=font_normal)
    
    draw.text((100, y+150), "MATRICOLA:", fill='black', font=font_small)
    draw.text((300, y+150), "123456", fill='black', font=font_normal)
    
    # Colonna destra - dati contrattuali
    draw.text((width//2 + 100, y+30), "DATA ASSUNZIONE:", fill='black', font=font_small)
    draw.text((width//2 + 300, y+30), "15/01/2020", fill='black', font=font_normal)
    
    draw.text((width//2 + 100, y+70), "DATA CESSATIONE:", fill='black', font=font_small)
    draw.text((width//2 + 300, y+70), "-", fill='black', font=font_normal)
    
    draw.text((width//2 + 100, y+110), "QUALIFICA:", fill='black', font=font_small)
    draw.text((width//2 + 300, y+110), "IMPIEGATO", fill='black', font=font_normal)
    
    draw.text((width//2 + 100, y+150), "LIVELLO:", fill='black', font=font_small)
    draw.text((width//2 + 300, y+150), "2°", fill='black', font=font_normal)
    
    y += 220  # Spazio dopo rettangolo
    
    # Periodo di paga
    draw.text((100, y), f"PERIODO DI PAGA: MAGGIO 2024", fill=(0, 51, 102), font=font_bold)
    y += 50
    
    # Sezione competenze e trattenute
    section_width = (width - 200) // 2
    section_height = 350
    
    # Competenze - sinistra
    draw.rectangle([(80, y), (80 + section_width, y + section_height)], outline=(150, 150, 150), width=1)
    draw.text((100, y+20), "COMPETENZE", fill=(0, 51, 102), font=font_normal)
    
    competenze = [
        ("Stipendio base", "1.800,00"),
        ("Indennità di contingenza", "150,00"),
        ("Superminimo", "200,00"),
        ("Premio produzione", "300,00"),
        ("Straordinari", "150,00"),
        ("Trasferta", "75,00"),
        ("Indennità di malattia", "0,00"),
        ("Ferie godute", "0,00")
    ]
    
    for i, (desc, importo) in enumerate(competenze):
        yy = y + 60 + i * 35  # Spazio aumentato tra righe
        if yy < y + section_height - 30:  # Evita sovrapposizione con bordo
            draw.text((100, yy), desc, fill='black', font=font_small)
            draw.text((80 + section_width - 150, yy), f"€ {importo}", fill='black', font=font_small)
            if i < len(competenze) - 1:  # Linea separatrice tranne ultima riga
                draw.line([(80, yy+25), (80 + section_width, yy+25)], fill=(220, 220, 220), width=1)
    
    # Trattenute - destra
    draw.rectangle([(100 + section_width, y), (100 + section_width + section_width, y + section_height)], 
                  outline=(150, 150, 150), width=1)
    draw.text((120 + section_width, y+20), "TRATTENUTE", fill=(0, 51, 102), font=font_normal)
    
    trattenute = [
        ("IRPEF", "425,00"),
        ("INPS (9,19%)", "218,00"),
        ("Addizionale regionale", "45,00"),
        ("TFR", "75,00"),
        ("Assicurazione", "30,00"),
        ("Anticipi", "0,00"),
        ("Rateizzazione", "0,00"),
        ("Esoneri", "0,00")
    ]
    
    for i, (desc, importo) in enumerate(trattenute):
        yy = y + 60 + i * 35
        if yy < y + section_height - 30:
            draw.text((120 + section_width, yy), desc, fill='black', font=font_small)
            draw.text((100 + section_width * 2 - 150, yy), f"€ {importo}", fill='black', font=font_small)
            if i < len(trattenute) - 1:
                draw.line([(100 + section_width, yy+25), (100 + section_width * 2, yy+25)], 
                         fill=(220, 220, 220), width=1)
    
    y += section_height + 40
    
    # Rettangolo totali
    draw.rectangle([(80, y), (width-80, y+120)], outline=(0, 51, 102), width=2, fill=(240, 240, 255))
    
    draw.text((100, y+25), "TOTALE COMPETENZE:", fill='black', font=font_normal)
    draw.text((350, y+25), "€ 2.675,00", fill='black', font=font_normal)
    
    draw.text((100, y+65), "TOTALE TRATTENUTE:", fill='black', font=font_normal)
    draw.text((350, y+65), "€ 793,00", fill='black', font=font_normal)
    
    draw.text((width//2 + 100, y+25), "NETTO DA PAGARE:", fill=(0, 51, 102), font=font_bold)
    draw.text((width//2 + 350, y+25), "€ 1.882,00", fill=(0, 51, 102), font=font_bold)
    
    draw.text((width//2 + 100, y+65), "GIORNI LAVORATI:", fill='black', font=font_normal)
    draw.text((width//2 + 350, y+65), "22", fill='black', font=font_normal)
    
    y += 140
    
    # Note
    draw.text((100, y), "Il presente cedolino è stato emesso in conformità alle disposizioni di legge vigenti.", 
              fill=(100, 100, 100), font=font_tiny)
    y += 30
    
    draw.text((100, y), "Data di emissione: 05/06/2024", fill='black', font=font_small)
    draw.text((width - 300, y), "Il responsabile del personale", fill='black', font=font_small)
    
    y += 40
    draw.line([(width - 300, y), (width - 100, y)], fill='black', width=1)
    
    # Applica effetti realistici (opzionale)
    if "scansione" in filename or "sfocato" in filename:
        img = create_realistic_effects(img)
    
    # Salva
    filepath = os.path.join(TEST_IMAGES_DIR, filename)
    if output_format.lower() == "jpg" or filename.lower().endswith('.jpg'):
        img.save(filepath, "JPEG", quality=90)
    else:
        img.save(filepath)
    
    print(f"[OK] Immagine creata: {filename}")
    return img

# ==================== FUNZIONI PER PDF NATIVI ====================

def create_realistic_cedolino_pdf(filename):
    """Crea un PDF nativo realistico di un cedolino"""
    filepath = os.path.join(TEST_PDFS_DIR, filename)
    c = canvas.Canvas(filepath, pagesize=A4)
    width, height = A4
    
    # Margini
    margin_left = 50
    margin_top = height - 50
    
    # Intestazione
    c.setFillColor(colors.HexColor("#003366"))
    c.rect(0, height-100, width, 100, fill=1, stroke=0)
    
    c.setFillColor(colors.white)
    c.setFont("Helvetica-Bold", 20)
    c.drawString(margin_left, margin_top - 30, "ZETA SERVICE S.R.L.")
    c.setFont("Helvetica", 10)
    c.drawString(margin_left, margin_top - 55, "SISTEMA PAGHE E RETRIBUZIONI")
    
    c.setFillColor(colors.black)
    y = margin_top - 100
    
    # Titolo
    c.setFont("Helvetica-Bold", 18)
    c.setFillColor(colors.HexColor("#003366"))
    c.drawString(margin_left, y, "CEDOLINO PAGA")
    y -= 40
    
    # Dati azienda
    c.setFont("Helvetica", 9)
    c.setFillColor(colors.black)
    c.drawString(margin_left, y, "CODICE AZIENDA: 999999")
    c.drawString(width/2, y, "RAGIONE SOCIALE: Zeta Service S.r.l.")
    y -= 20
    
    c.drawString(margin_left, y, "INDIRIZZO: Viale Ortles, 12")
    c.drawString(width/2, y, "20100 MILANO (MI)")
    y -= 20
    
    c.drawString(margin_left, y, "CODICE FISCALE: 12345678901")
    c.drawString(width/2, y, "PARTITA IVA: 01234567890")
    y -= 40
    
    # Dati dipendente - rettangolo
    c.setStrokeColor(colors.HexColor("#003366"))
    c.setLineWidth(1.5)
    c.rect(margin_left - 10, y - 180, width - 80, 180)
    
    # Colonna sinistra
    c.setFont("Helvetica", 9)
    y_dipendente = y - 30
    c.drawString(margin_left, y_dipendente, "CODICE DIPENDENTE:")
    c.setFont("Helvetica-Bold", 9)
    c.drawString(margin_left + 150, y_dipendente, "001234")
    
    c.setFont("Helvetica", 9)
    c.drawString(margin_left, y_dipendente - 30, "NOME E COGNOME:")
    c.drawString(margin_left + 150, y_dipendente - 30, fake.name().upper())
    
    c.drawString(margin_left, y_dipendente - 60, "CODICE FISCALE:")
    c.drawString(margin_left + 150, y_dipendente - 60, fake.ssn().upper())
    
    c.drawString(margin_left, y_dipendente - 90, "MATRICOLA:")
    c.drawString(margin_left + 150, y_dipendente - 90, "123456")
    
    # Colonna destra
    c.drawString(width/2 + 50, y_dipendente, "DATA ASSUNZIONE:")
    c.drawString(width/2 + 200, y_dipendente, "15/01/2020")
    
    c.drawString(width/2 + 50, y_dipendente - 30, "DATA CESSATIONE:")
    c.drawString(width/2 + 200, y_dipendente - 30, "-")
    
    c.drawString(width/2 + 50, y_dipendente - 60, "QUALIFICA:")
    c.drawString(width/2 + 200, y_dipendente - 60, "IMPIEGATO")
    
    c.drawString(width/2 + 50, y_dipendente - 90, "LIVELLO:")
    c.drawString(width/2 + 200, y_dipendente - 90, "2°")
    
    y = y_dipendente - 120
    
    # Periodo
    c.setFont("Helvetica-Bold", 11)
    c.setFillColor(colors.HexColor("#003366"))
    c.drawString(margin_left, y, "PERIODO DI PAGA: MAGGIO 2024")
    y -= 40
    
    # Tabella competenze (sinistra)
    table_width = (width - 120) / 2
    table_height = 280
    
    c.setStrokeColor(colors.gray)
    c.setLineWidth(1)
    c.rect(margin_left - 10, y - table_height, table_width, table_height)
    
    c.setFont("Helvetica-Bold", 10)
    c.setFillColor(colors.HexColor("#003366"))
    c.drawString(margin_left, y - 20, "COMPETENZE")
    
    competenze = [
        ("Stipendio base", "1.800,00"),
        ("Indennità di contingenza", "150,00"),
        ("Superminimo", "200,00"),
        ("Premio produzione", "300,00"),
        ("Straordinari", "150,00"),
        ("Trasferta", "75,00")
    ]
    
    for i, (desc, importo) in enumerate(competenze):
        yy = y - 50 - i * 35
        c.setFont("Helvetica", 8)
        c.setFillColor(colors.black)
        c.drawString(margin_left, yy, desc)
        c.drawString(margin_left + table_width - 80, yy, f"€ {importo}")
        if i < len(competenze) - 1:
            c.setStrokeColor(colors.lightgrey)
            c.line(margin_left - 10, yy - 10, margin_left + table_width - 10, yy - 10)
    
    # Tabella trattenute (destra)
    c.setStrokeColor(colors.gray)
    c.rect(margin_left + table_width + 20, y - table_height, table_width, table_height)
    
    c.setFont("Helvetica-Bold", 10)
    c.setFillColor(colors.HexColor("#003366"))
    c.drawString(margin_left + table_width + 30, y - 20, "TRATTENUTE")
    
    trattenute = [
        ("IRPEF", "425,00"),
        ("INPS (9,19%)", "218,00"),
        ("Addizionale regionale", "45,00"),
        ("TFR", "75,00"),
        ("Assicurazione", "30,00"),
        ("Anticipi", "-")
    ]
    
    for i, (desc, importo) in enumerate(trattenute):
        yy = y - 50 - i * 35
        c.setFont("Helvetica", 8)
        c.setFillColor(colors.black)
        c.drawString(margin_left + table_width + 30, yy, desc)
        c.drawString(margin_left + table_width * 2 + 10, yy, f"€ {importo}")
        if i < len(trattenute) - 1:
            c.setStrokeColor(colors.lightgrey)
            c.line(margin_left + table_width + 20, yy - 10, margin_left + table_width * 2 + 20, yy - 10)
    
    y = y - table_height - 40
    
    # Totali
    c.setStrokeColor(colors.HexColor("#003366"))
    c.setLineWidth(1.5)
    c.setFillColor(colors.HexColor("#F0F0FF"))
    c.rect(margin_left - 10, y - 100, width - 80, 100, fill=1, stroke=1)
    
    c.setFont("Helvetica", 9)
    c.setFillColor(colors.black)
    c.drawString(margin_left, y - 30, "TOTALE COMPETENZE:")
    c.drawString(margin_left + 200, y - 30, "€ 2.675,00")
    
    c.drawString(margin_left, y - 60, "TOTALE TRATTENUTE:")
    c.drawString(margin_left + 200, y - 60, "€ 793,00")
    
    c.setFont("Helvetica-Bold", 11)
    c.setFillColor(colors.HexColor("#003366"))
    c.drawString(width/2 + 50, y - 30, "NETTO DA PAGARE:")
    c.drawString(width/2 + 250, y - 30, "€ 1.882,00")
    
    c.setFont("Helvetica", 9)
    c.setFillColor(colors.black)
    c.drawString(width/2 + 50, y - 60, "GIORNI LAVORATI:")
    c.drawString(width/2 + 250, y - 60, "22")
    
    y -= 120
    
    # Note
    c.setFont("Helvetica", 7)
    c.setFillColor(colors.gray)
    c.drawString(margin_left, y, "Il presente cedolino è stato emesso in conformità alle disposizioni di legge vigenti.")
    
    c.setFont("Helvetica", 9)
    c.setFillColor(colors.black)
    c.drawString(margin_left, y - 30, "Data di emissione: 05/06/2024")
    c.drawString(width - 250, y - 30, "Il responsabile del personale")
    
    # Firma simulata
    c.setLineWidth(1)
    c.setStrokeColor(colors.black)
    c.line(width - 250, y - 45, width - 100, y - 45)
    
    c.save()
    print(f"[OK] PDF nativo creato: {filename}")

# ==================== FUNZIONI PER ALTRI DOCUMENTI ====================

def create_fattura_image(filename, output_format="png"):
    """Crea un'immagine di fattura senza sovrapposizioni"""
    width, height = 1800, 2200
    img = Image.new('RGB', (width, height), color=(255, 255, 255))
    draw = ImageDraw.Draw(img)
    
    try:
        font_bold = ImageFont.truetype("arialbd.ttf", 26)
        font_normal = ImageFont.truetype("arial.ttf", 20)
        font_small = ImageFont.truetype("arial.ttf", 16)
        font_tiny = ImageFont.truetype("arial.ttf", 12)
    except:
        font_bold = ImageFont.load_default()
        font_normal = ImageFont.load_default()
        font_small = ImageFont.load_default()
        font_tiny = ImageFont.load_default()
    
    y = 50
    
    # Intestazione
    draw.rectangle([(0, y-30), (width, y+70)], fill=(220, 20, 60))
    draw.text((width//2 - 180, y), "TECNOSOLUTIONS S.P.A.", fill='white', font=font_bold)
    draw.text((width//2 - 150, y+50), "SOLUZIONI INFORMATICHE INTEGRATE", fill=(255, 200, 200), font=font_small)
    
    y += 140
    
    # Numero fattura
    draw.text((100, y), f"FATTURA N. {random.randint(100, 999)}/2024", fill='black', font=font_bold)
    draw.text((width - 300, y), f"DATA: {datetime.now().strftime('%d/%m/%Y')}", fill='black', font=font_normal)
    y += 70
    
    # Dati fornitore e cliente in colonne separate
    col_width = (width - 300) // 2
    
    # Fornitore
    draw.rectangle([(80, y), (80 + col_width, y + 200)], outline=(150, 150, 150), width=1)
    draw.text((100, y+20), "FORNITORE:", fill=(220, 20, 60), font=font_small)
    draw.text((100, y+60), "TecnoSolutions S.p.A.", fill='black', font=font_small)
    draw.text((100, y+90), "Via delle Tecnologie, 45", fill='black', font=font_tiny)
    draw.text((100, y+120), "00100 ROMA (RM)", fill='black', font=font_tiny)
    draw.text((100, y+150), "P.IVA: 01234567890", fill='black', font=font_tiny)
    
    # Cliente
    draw.rectangle([(220 + col_width, y), (220 + col_width + col_width, y + 200)], 
                  outline=(150, 150, 150), width=1)
    draw.text((240 + col_width, y+20), "CLIENTE:", fill=(220, 20, 60), font=font_small)
    
    nome_cliente = fake.company().upper()
    draw.text((240 + col_width, y+60), nome_cliente, fill='black', font=font_small)
    draw.text((240 + col_width, y+90), fake.street_address().upper(), fill='black', font=font_tiny)
    draw.text((240 + col_width, y+120), fake.postcode() + " " + fake.city().upper(), fill='black', font=font_tiny)
    draw.text((240 + col_width, y+150), f"P.IVA: {fake.vat_id()}", fill='black', font=font_tiny)
    
    y += 230
    
    # Tabella articoli - intestazione
    draw.rectangle([(80, y), (width-80, y+50)], fill=(240, 240, 240))
    draw.text((100, y+15), "DESCRIZIONE", fill='black', font=font_small)
    draw.text((width//3, y+15), "QUANTITÀ", fill='black', font=font_small)
    draw.text((width//2, y+15), "PREZZO UNITARIO", fill='black', font=font_small)
    draw.text((width*2//3, y+15), "IMPORTO", fill='black', font=font_small)
    
    y += 60
    
    # Articoli
    articoli = [
        ("Consulenza sviluppo software", 10, 120.00),
        ("Manutenzione server", 5, 85.50),
        ("Licenze software antivirus", 25, 45.00),
        ("Formazione personale", 8, 150.00),
        ("Assistenza tecnica remota", 15, 75.00)
    ]
    
    for i, (desc, qta, prezzo) in enumerate(articoli):
        if i % 2 == 0:
            draw.rectangle([(80, y), (width-80, y+50)], fill=(250, 250, 250))
        
        draw.text((100, y+15), desc, fill='black', font=font_tiny)
        draw.text((width//3, y+15), str(qta), fill='black', font=font_tiny)
        draw.text((width//2, y+15), f"€ {prezzo:,.2f}".replace(',', 'X').replace('.', ',').replace('X', '.'), 
                  fill='black', font=font_tiny)
        
        importo = qta * prezzo
        draw.text((width*2//3, y+15), f"€ {importo:,.2f}".replace(',', 'X').replace('.', ',').replace('X', '.'), 
                  fill='black', font=font_tiny)
        
        draw.line([(80, y+50), (width-80, y+50)], fill=(200, 200, 200), width=1)
        y += 50
    
    y += 30
    
    # Totali
    subtotale = sum(qta * prezzo for _, qta, prezzo in articoli)
    iva = subtotale * 0.22
    totale = subtotale + iva
    
    draw.text((width - 400, y), "Imponibile:", fill='black', font=font_small)
    draw.text((width - 200, y), f"€ {subtotale:,.2f}".replace(',', 'X').replace('.', ',').replace('X', '.'), 
              fill='black', font=font_small)
    y += 40
    
    draw.text((width - 400, y), "IVA 22%:", fill='black', font=font_small)
    draw.text((width - 200, y), f"€ {iva:,.2f}".replace(',', 'X').replace('.', ',').replace('X', '.'), 
              fill='black', font=font_small)
    y += 50
    
    # Rettangolo totale
    draw.rectangle([(width - 450, y), (width-80, y+60)], fill=(240, 240, 240), outline=(220, 20, 60), width=2)
    draw.text((width - 430, y+15), "TOTALE FATTURA:", fill=(220, 20, 60), font=font_normal)
    draw.text((width - 200, y+15), f"€ {totale:,.2f}".replace(',', 'X').replace('.', ',').replace('X', '.'), 
              fill=(220, 20, 60), font=font_normal)
    
    y += 100
    
    # Modalità di pagamento
    draw.text((100, y), "MODALITÀ DI PAGAMENTO: Bonifico bancario entro 30 giorni", fill='black', font=font_small)
    draw.text((100, y+30), f"IBAN: IT60X05428{fake.bban()}", fill='black', font=font_tiny)
    draw.text((100, y+60), f"Banca: {fake.company()} - {fake.city()}", fill='black', font=font_tiny)
    
    # Salva
    filepath = os.path.join(TEST_IMAGES_DIR, filename)
    if output_format.lower() == "jpg" or filename.lower().endswith('.jpg'):
        img.save(filepath, "JPEG", quality=90)
    else:
        img.save(filepath)
    
    print(f"[OK] Fattura creata: {filename}")
    return img

def create_fattura_pdf(filename):
    """Crea un PDF nativo di una fattura"""
    filepath = os.path.join(TEST_PDFS_DIR, filename)
    c = canvas.Canvas(filepath, pagesize=A4)
    width, height = A4
    
    # Margini
    margin_left = 50
    margin_top = height - 50
    
    # Intestazione rossa
    c.setFillColor(colors.HexColor("#DC143C"))
    c.rect(0, height-80, width, 80, fill=1, stroke=0)
    
    c.setFillColor(colors.white)
    c.setFont("Helvetica-Bold", 18)
    c.drawString(margin_left, margin_top - 30, "TECNOSOLUTIONS S.P.A.")
    c.setFont("Helvetica", 9)
    c.drawString(margin_left, margin_top - 55, "SOLUZIONI INFORMATICHE INTEGRATE")
    
    c.setFillColor(colors.black)
    y = margin_top - 100
    
    # Numero fattura
    fattura_num = random.randint(100, 999)
    c.setFont("Helvetica-Bold", 14)
    c.drawString(margin_left, y, f"FATTURA N. {fattura_num}/2024")
    c.setFont("Helvetica", 9)
    c.drawString(width-200, y, f"DATA: {datetime.now().strftime('%d/%m/%Y')}")
    y -= 40
    
    # Dati fornitore e cliente
    col_width = (width - 140) / 2
    
    # Fornitore
    c.setStrokeColor(colors.gray)
    c.setLineWidth(1)
    c.rect(margin_left - 10, y - 180, col_width, 180)
    
    c.setFont("Helvetica-Bold", 9)
    c.setFillColor(colors.HexColor("#DC143C"))
    c.drawString(margin_left, y - 20, "FORNITORE:")
    
    c.setFont("Helvetica", 8)
    c.setFillColor(colors.black)
    c.drawString(margin_left, y - 50, "TecnoSolutions S.p.A.")
    c.drawString(margin_left, y - 70, "Via delle Tecnologie, 45")
    c.drawString(margin_left, y - 90, "00100 ROMA (RM)")
    c.drawString(margin_left, y - 110, "P.IVA: 01234567890")
    c.drawString(margin_left, y - 130, "C.F.: TCNSPA80A01H501Z")
    
    # Cliente
    c.rect(margin_left + col_width + 20, y - 180, col_width, 180)
    
    c.setFont("Helvetica-Bold", 9)
    c.setFillColor(colors.HexColor("#DC143C"))
    c.drawString(margin_left + col_width + 30, y - 20, "CLIENTE:")
    
    nome_cliente = fake.company().upper()
    c.setFont("Helvetica", 8)
    c.setFillColor(colors.black)
    c.drawString(margin_left + col_width + 30, y - 50, nome_cliente)
    c.drawString(margin_left + col_width + 30, y - 70, fake.street_address().upper())
    c.drawString(margin_left + col_width + 30, y - 90, fake.postcode() + " " + fake.city().upper())
    c.drawString(margin_left + col_width + 30, y - 110, f"P.IVA: {fake.vat_id()}")
    c.drawString(margin_left + col_width + 30, y - 130, f"C.F.: {fake.ssn().upper()}")
    
    y -= 200
    
    # Tabella articoli - intestazione
    c.setFillColor(colors.HexColor("#F0F0F0"))
    c.rect(margin_left - 10, y - 40, width - 80, 40, fill=1, stroke=0)
    
    c.setFillColor(colors.black)
    c.setFont("Helvetica-Bold", 9)
    c.drawString(margin_left, y - 25, "DESCRIZIONE")
    c.drawString(width/3, y - 25, "QUANTITÀ")
    c.drawString(width/2, y - 25, "PREZZO UNITARIO")
    c.drawString(width*2/3, y - 25, "IMPORTO")
    
    y -= 40
    
    # Articoli
    articoli = [
        ("Consulenza sviluppo software", 10, 120.00),
        ("Manutenzione server", 5, 85.50),
        ("Licenze software antivirus", 25, 45.00),
        ("Formazione personale", 8, 150.00),
        ("Assistenza tecnica remota", 15, 75.00)
    ]
    
    for i, (desc, qta, prezzo) in enumerate(articoli):
        if i % 2 == 0:
            c.setFillColor(colors.HexColor("#FAFAFA"))
            c.rect(margin_left - 10, y - 40, width - 80, 40, fill=1, stroke=0)
        
        c.setFillColor(colors.black)
        c.setFont("Helvetica", 7)
        c.drawString(margin_left, y - 25, desc)
        c.drawString(width/3, y - 25, str(qta))
        c.drawString(width/2, y - 25, f"€ {prezzo:,.2f}".replace(',', 'X').replace('.', ',').replace('X', '.'))
        
        importo = qta * prezzo
        c.drawString(width*2/3, y - 25, f"€ {importo:,.2f}".replace(',', 'X').replace('.', ',').replace('X', '.'))
        
        c.setStrokeColor(colors.lightgrey)
        c.line(margin_left - 10, y - 40, width - 70, y - 40)
        y -= 40
    
    y -= 20
    
    # Totali
    subtotale = sum(qta * prezzo for _, qta, prezzo in articoli)
    iva = subtotale * 0.22
    totale = subtotale + iva
    
    c.setFont("Helvetica", 9)
    c.setFillColor(colors.black)
    c.drawString(width - 300, y, "Imponibile:")
    c.drawString(width - 150, y, f"€ {subtotale:,.2f}".replace(',', 'X').replace('.', ',').replace('X', '.'))
    y -= 30
    
    c.drawString(width - 300, y, "IVA 22%:")
    c.drawString(width - 150, y, f"€ {iva:,.2f}".replace(',', 'X').replace('.', ',').replace('X', '.'))
    y -= 40
    
    # Rettangolo totale
    c.setStrokeColor(colors.HexColor("#DC143C"))
    c.setLineWidth(1.5)
    c.setFillColor(colors.HexColor("#F0F0F0"))
    c.rect(width - 350, y - 50, 300, 50, fill=1, stroke=1)
    
    c.setFont("Helvetica-Bold", 11)
    c.setFillColor(colors.HexColor("#DC143C"))
    c.drawString(width - 330, y - 20, "TOTALE FATTURA:")
    c.drawString(width - 150, y - 20, f"€ {totale:,.2f}".replace(',', 'X').replace('.', ',').replace('X', '.'))
    
    y -= 80
    
    # Modalità di pagamento
    c.setFont("Helvetica", 9)
    c.setFillColor(colors.black)
    c.drawString(margin_left, y, "MODALITÀ DI PAGAMENTO: Bonifico bancario entro 30 giorni")
    c.setFont("Helvetica", 8)
    c.drawString(margin_left, y - 25, f"IBAN: IT60X05428{fake.bban()}")
    c.drawString(margin_left, y - 50, f"Banca: {fake.company()} - {fake.city()}")
    
    c.save()
    print(f"[OK] PDF fattura creato: {filename}")

# ==================== FUNZIONI PER VARIANTI ====================

def create_document_variants(base_name, create_image_func, create_pdf_func):
    """Crea varianti dello stesso documento"""
    print(f"\n[VARIANTI] Creazione varianti per {base_name}")
    
    # Immagine ad alta qualità
    create_image_func(f"{base_name}-alta-qualita.png", output_format="png")
    
    # Immagine in JPEG
    create_image_func(f"{base_name}-media-qualita.jpg", output_format="jpg")
    
    # Immagine sfocata
    img_path = os.path.join(TEST_IMAGES_DIR, f"{base_name}-alta-qualita.png")
    if os.path.exists(img_path):
        img = Image.open(img_path)
        blurred = img.filter(ImageFilter.GaussianBlur(radius=1.5))
        blurred.save(os.path.join(TEST_IMAGES_DIR, f"{base_name}-sfocato.png"))
        print(f"[OK] Variante sfocata: {base_name}-sfocato.png")
        
        # Versione con rumore
        noisy = add_noise(img, intensity=0.015)
        enhancer = ImageEnhance.Brightness(noisy)
        noisy = enhancer.enhance(0.9)
        noisy.save(os.path.join(TEST_IMAGES_DIR, f"{base_name}-rumoroso.png"))
        print(f"[OK] Variante rumorosa: {base_name}-rumoroso.png")
    
    # PDF nativo
    create_pdf_func(f"{base_name}-nativo.pdf")
    
    print(f"[OK] Varianti completate per {base_name}")

# ==================== FUNZIONE PRINCIPALE ====================

def generate_all_documents():
    """Genera tutti i documenti di test"""
    print("=" * 70)
    print("GENERAZIONE DOCUMENTI PER TEST OCR - VERSIONE CORRETTA")
    print("=" * 70)
    
    print("\n[1/3] Generazione cedolini...")
    create_document_variants(
        "cedolino-paga",
        create_realistic_cedolino_image,
        create_realistic_cedolino_pdf
    )
    
    print("\n[2/3] Generazione fatture...")
    create_document_variants(
        "fattura-commerciale",
        create_fattura_image,
        create_fattura_pdf
    )
    
    print("\n[3/3] Generazione documenti extra...")
    
    # Crea un cedolino extra
    create_realistic_cedolino_image("cedolino-extra-01.png")
    create_realistic_cedolino_pdf("cedolino-extra-01.pdf")
    
    # Crea una fattura extra
    create_fattura_image("fattura-extra-01.png")
    create_fattura_pdf("fattura-extra-01.pdf")
    
    # Crea un documento semplice per test di base
    create_simple_document_image()
    create_simple_document_pdf()
    
    print("\n" + "=" * 70)
    print(f"DOCUMENTI GENERATI IN: {TEST_IMAGES_DIR}/")
    
    # Conta i file generati
    count_images = len([f for f in os.listdir(TEST_IMAGES_DIR) 
                       if f.endswith(('.png', '.jpg', '.jpeg'))])
    count_pdfs = len([f for f in os.listdir(TEST_PDFS_DIR) 
                     if f.endswith('.pdf')])
    
    print(f"\nSTATISTICHE:")
    print(f"  • Immagini totali: {count_images}")
    print(f"  • PDF totali: {count_pdfs}")
    print(f"  • File totali: {count_images + count_pdfs}")
    
    print("\nTIPI DI FILE CREATI:")
    print("  ✓ Immagini PNG (alta qualità)")
    print("  ✓ Immagini JPG (media qualità)")
    print("  ✓ Immagini sfocate (test robustezza)")
    print("  ✓ Immagini rumorose (simulazione scansioni)")
    print("  ✓ PDF nativi (testo selezionabile)")
    
    print("\nTIPI DI DOCUMENTO:")
    print("  ✓ Cedolini paga con layout pulito")
    print("  ✓ Fatture commerciali con IVA")
    print("  ✓ Documenti extra per test vari")

def create_simple_document_image():
    """Crea un documento semplice per test di base"""
    width, height = 1200, 1600
    img = Image.new('RGB', (width, height), color=(255, 255, 255))
    draw = ImageDraw.Draw(img)
    
    try:
        font_bold = ImageFont.truetype("arial.ttf", 28)
        font_normal = ImageFont.truetype("arial.ttf", 22)
        font_small = ImageFont.truetype("arial.ttf", 18)
    except:
        font_bold = ImageFont.load_default()
        font_normal = ImageFont.load_default()
        font_small = ImageFont.load_default()
    
    y = 100
    
    # Titolo
    draw.text((width//2 - 150, y), "DOCUMENTO DI TEST", fill='black', font=font_bold)
    y += 80
    
    # Sezione 1
    draw.text((100, y), "Sezione 1: Dati principali", fill=(0, 0, 150), font=font_normal)
    y += 50
    
    draw.text((150, y), "Nome: Mario Rossi", fill='black', font=font_small)
    y += 40
    draw.text((150, y), "Codice Fiscale: RSSMRA80A01H501X", fill='black', font=font_small)
    y += 40
    draw.text((150, y), "Data di nascita: 01/01/1980", fill='black', font=font_small)
    y += 60
    
    # Sezione 2
    draw.text((100, y), "Sezione 2: Dettagli", fill=(0, 0, 150), font=font_normal)
    y += 50
    
    draw.text((150, y), "Importo totale: € 1.250,00", fill='black', font=font_small)
    y += 40
    draw.text((150, y), "IVA 22%: € 275,00", fill='black', font=font_small)
    y += 40
    draw.text((150, y), "Netto a pagare: € 1.525,00", fill='black', font=font_small)
    y += 60
    
    # Data
    draw.text((100, y), f"Data emissione: {datetime.now().strftime('%d/%m/%Y')}", fill='black', font=font_small)
    
    img.save(os.path.join(TEST_IMAGES_DIR, "documento-semplice.png"))
    print("[OK] Documento semplice creato: documento-semplice.png")

def create_simple_document_pdf():
    """Crea un PDF semplice per test di base"""
    filepath = os.path.join(TEST_PDFS_DIR, "documento-semplice.pdf")
    c = canvas.Canvas(filepath, pagesize=A4)
    width, height = A4
    
    # Margini
    margin_left = 50
    y = height - 50
    
    # Titolo
    c.setFont("Helvetica-Bold", 20)
    c.drawString(margin_left, y, "DOCUMENTO DI TEST")
    y -= 60
    
    # Sezione 1
    c.setFont("Helvetica-Bold", 14)
    c.setFillColor(colors.blue)
    c.drawString(margin_left, y, "Sezione 1: Dati principali")
    y -= 30
    
    c.setFont("Helvetica", 12)
    c.setFillColor(colors.black)
    c.drawString(margin_left + 20, y, "Nome: Mario Rossi")
    y -= 25
    c.drawString(margin_left + 20, y, "Codice Fiscale: RSSMRA80A01H501X")
    y -= 25
    c.drawString(margin_left + 20, y, "Data di nascita: 01/01/1980")
    y -= 40
    
    # Sezione 2
    c.setFont("Helvetica-Bold", 14)
    c.setFillColor(colors.blue)
    c.drawString(margin_left, y, "Sezione 2: Dettagli")
    y -= 30
    
    c.setFont("Helvetica", 12)
    c.setFillColor(colors.black)
    c.drawString(margin_left + 20, y, "Importo totale: € 1.250,00")
    y -= 25
    c.drawString(margin_left + 20, y, "IVA 22%: € 275,00")
    y -= 25
    c.drawString(margin_left + 20, y, "Netto a pagare: € 1.525,00")
    y -= 40
    
    # Data
    c.drawString(margin_left, y, f"Data emissione: {datetime.now().strftime('%d/%m/%Y')}")
    
    c.save()
    print("[OK] PDF semplice creato: documento-semplice.pdf")

# ==================== MAIN ====================

if __name__ == "__main__":
    # Informazioni sulle dipendenze
    print("REQUISITI:")
    print("  • Pillow: pip install pillow")
    print("  • ReportLab: pip install reportlab")
    print("  • NumPy: pip install numpy")
    print("  • Faker: pip install faker (opzionale)")
    print()
    
    # Genera tutti i documenti
    generate_all_documents()
    
    print("\n" + "=" * 70)
    print("UTILIZZO:")
    print("  1. I file sono stati generati nella cartella: documenti-test-ocr/")
    print("  2. Usa questi file per testare il tuo sistema OCR")
    print("\nSUGGERIMENTI:")
    print("  • Inizia con 'documento-semplice.pdf' per test di base")
    print("  • Prova le varianti sfocate per testare la robustezza")
    print("  • I PDF nativi contengono testo selezionabile")
    print("  • Le immagini simulano documenti scansionati")
    print("=" * 70)